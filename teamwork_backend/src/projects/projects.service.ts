import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Project } from './schemas/project.schema';
import { ProjectMember } from './schemas/project-member.schema';
import { User } from '../auth/schemas/user.schema';
import { Task } from '../tasks/schemas/task.schema';
import { Notification } from '../notifications/schemas/notification.schema';
import { CreateProjectDto, UpdateProjectDto } from './dto/create-project.dto';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';
import { AppGateway } from '../gateway/app.gateway';
import { ProjectAccessService } from '../common/project-access/project-access.service';

@Injectable()
export class ProjectsService {
  constructor(
    @InjectModel(Project.name)
    private projectModel: Model<Project>,
    @InjectModel(ProjectMember.name)
    private projectMemberModel: Model<ProjectMember>,
    @InjectModel(User.name)
    private userModel: Model<User>,
    @InjectModel(Task.name)
    private taskModel: Model<Task>,
    @InjectModel(Notification.name)
    private notificationModel: Model<Notification>,
    private readonly gateway: AppGateway,
    private readonly access: ProjectAccessService,
    private readonly configService: ConfigService,
  ) {}

  private get mailTransporter() {
    return nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: this.configService.get<string>('EMAIL_USER'),
        pass: this.configService.get<string>('EMAIL_PASS'),
      },
    });
  }

  private async _sendEmail(to: string, subject: string, html: string) {
    return this.mailTransporter.sendMail({
      from: '"WorkFlow App" <no-reply@workflow.com>',
      to,
      subject,
      html,
    }).catch((err) => console.log('Lỗi gửi email:', err));
  }

  async createProject(dto: CreateProjectDto, ownerId: string) {
    const project = await this.projectModel.create({
      name:        dto.name,
      description: dto.description ?? '',
      ownerId:     new Types.ObjectId(ownerId),
    });

    await this.projectMemberModel.create({
      projectId: project._id,
      userId:    ownerId,
      role:      'Admin',
    });

    // Real-time: notify the creator's user room so their project list refreshes.
    this.gateway.emitToUser(ownerId, 'project_list_changed', {
      projectId: project._id.toString(),
      name:      project.name,
    });

    return {
      id:          project._id,
      name:        project.name,
      description: project.description,
      role:        'Admin',
      message:     'Tạo dự án thành công',
    };
  }

  async getMyProjects(userId: string) {
    const memberships = await this.projectMemberModel
      .find({ userId })
      .populate('projectId', 'name description ownerId');

    const results = [];
    for (const m of memberships) {
      if (!m.projectId) continue;
      const project = m.projectId as any;

      const total = await this.taskModel.countDocuments({
        projectId: project._id,
      });
      const done = await this.taskModel.countDocuments({
        projectId: project._id, status: 'done',
      });
      // Dự án chưa có task nào → tiến độ LUÔN là 0%, không bịa số liệu
      const percent = total === 0 ? 0 : Math.round((done / total) * 100);

      results.push({
        id:          project._id,
        name:        project.name,
        description: project.description ?? '',
        role:        m.role,
        taskTotal:   total,
        taskDone:    done,
        progress:    percent,
      });
    }
    return results;
  }

  // ── Sửa tên/mô tả — dùng _assertIsAdmin (owner luôn được phép) ──
  async updateProject(
    projectId: string,
    dto: UpdateProjectDto,
    currentUserId: string,
  ) {
    await this.access.assertHasRole(projectId, currentUserId, ['Admin']);

    const set: Partial<UpdateProjectDto> = {};
    if (dto.name        !== undefined) set.name        = dto.name;
    if (dto.description !== undefined) set.description = dto.description;

    const updated = await this.projectModel.findByIdAndUpdate(
      projectId, { $set: set }, { new: true },
    );
    if (!updated) throw new NotFoundException('Không tìm thấy dự án');

    // Real-time: push the updated project to everyone in the room.
    this.gateway.emitToProject(projectId, 'project_updated', {
      id:          updated._id.toString(),
      name:        updated.name,
      description: updated.description,
    });

    return {
      id:          updated._id,
      name:        updated.name,
      description: updated.description,
      message:     'Cập nhật dự án thành công',
    };
  }

  // ── Xóa dự án — dùng _assertIsAdmin (owner luôn được phép) ──
  async deleteProject(projectId: string, currentUserId: string) {
    await this.access.assertHasRole(projectId, currentUserId, ['Admin']);

    // Capture member ids BEFORE deleting so we can notify their user rooms
    // (the project room itself is gone after deletion).
    const members = await this.projectMemberModel.find({ projectId });
    const memberUserIds = members.map((m) => m.userId.toString());

    await this.projectModel.findByIdAndDelete(projectId);
    await this.projectMemberModel.deleteMany({ projectId });
    await this.taskModel.deleteMany({ projectId });

    // Real-time: tell everyone (including the owner) the project is gone.
    this.gateway.emitToProject(projectId, 'project_deleted', {
      projectId,
    });
    for (const uid of memberUserIds) {
      this.gateway.emitToUser(uid, 'project_list_changed', { projectId });
    }

    return { message: 'Đã xóa dự án' };
  }

  async getProjectMembers(projectId: string, currentUserId?: string) {
    // Member list is project-scoped: only project members can read it.
    if (currentUserId !== undefined) {
      await this.access.assertIsMember(projectId, currentUserId);
    }
    const members = await this.projectMemberModel
      .find({ projectId })
      .populate('userId', 'email fullName phone avatarUrl');

    return members.map((m) => {
      const user = m.userId as any;
      return {
        id:        user._id,
        name:      user.fullName || user.email.split('@')[0],
        email:     user.email,
        phone:     user.phone     ?? '',
        avatarUrl: user.avatarUrl ?? '',
        role:      m.role,
        isOnline:  false,
      };
    });
  }

  // ── Role hiệu lực của 1 user trong project (owner = Admin) ──
  getMemberRole(projectId: string, userId: string): Promise<string | null> {
    return this.access.getEffectiveRole(projectId, userId);
  }

  async getMyRole(projectId: string, userId: string) {
    const role = await this.access.getEffectiveRole(projectId, userId);
    if (!role) throw new ForbiddenException('Bạn không phải thành viên của dự án này');
    return { role };
  }

  // ── Thêm thành viên — GIỜ TẠO THÔNG BÁO + ĐẨY REAL-TIME ──
  async addMemberByEmail(projectId: string, email: string, currentUserId?: string) {
    // Chỉ Admin/Manager của dự án mới được mời thêm thành viên.
    const requesterRole = currentUserId
      ? await this.getMemberRole(projectId, currentUserId)
      : 'Admin';
    if (requesterRole !== 'Admin' && requesterRole !== 'Manager') {
      throw new ForbiddenException('Bạn không có quyền mời thành viên');
    }
    const user = await this.userModel.findOne({ email });
    if (!user) {
      throw new NotFoundException(
        'Không tìm thấy tài khoản với email này trong hệ thống',
      );
    }

    const existing = await this.projectMemberModel.findOne({
      projectId, userId: user._id,
    });
    if (existing) {
      throw new BadRequestException('Thành viên này đã có trong dự án');
    }

    await this.projectMemberModel.create({
      projectId, userId: user._id, role: 'Member',
    });

    // Lấy tên dự án để đưa vào nội dung thông báo
    const project = await this.projectModel.findById(projectId);
    const projectName = project?.name ?? 'dự án';

    // Tạo thông báo lưu DB
    const notif = await this.notificationModel.create({
      userId:  user._id,
      type:    'member_added',
      title:   'Bạn được thêm vào một dự án mới',
      body:    `Bạn đã được thêm vào dự án "${projectName}"`,
      refId:   new Types.ObjectId(projectId),
      refType: 'project',
      isRead:  false,
    });

    await this._sendEmail(
      user.email,
      'Bạn được thêm vào một dự án mới',
      `<b>Xin chào ${user.fullName ?? user.email}</b><br/>Bạn đã được thêm vào dự án <b>${projectName}</b>.<br/>Hãy đăng nhập để xem chi tiết.`,
    );

    // Đẩy real-time đến đúng user (nếu đang online)
    this.gateway.emitToUser(user._id.toString(), 'notification', {
      id:    notif._id,
      type:  notif.type,
      title: notif.title,
      body:  notif.body,
      refId: projectId,
      refType: 'project',
    });
    this.gateway.emitToUser(user._id.toString(), 'you_were_added_to_project', {
      type: 'member_added',
      title: 'Bạn được thêm vào một dự án mới',
      body: `Bạn đã được thêm vào dự án "${projectName}"`,
      projectId,
      projectName,
    });
    // Real-time: update the member list + project list of everyone involved.
    this.gateway.emitToProject(projectId, 'member_added', {
      projectId,
      userId:    user._id.toString(),
      email:     user.email,
      fullName:  user.fullName,
      role:      'Member',
    });
    this.gateway.emitToUser(user._id.toString(), 'project_list_changed', {
      projectId,
    });

    return { message: 'Thêm thành viên thành công' };
  }

  async removeMember(
    projectId: string,
    targetUserId: string,
    currentUserId: string,
  ) {
    // Owner counts as implicit Admin even without a ProjectMember doc,
    // mirroring _assertIsAdmin (ownerId is the source of truth).
    const project = await this.projectModel.findById(projectId);
    if (!project) throw new NotFoundException('Không tìm thấy dự án');
    const isOwner = project.ownerId.toString() === currentUserId;

    const requesterMember = await this.projectMemberModel.findOne({
      projectId, userId: currentUserId,
    });
    const requesterRole =
      requesterMember?.role ?? (isOwner ? 'Admin' : null);
    const target = await this.projectMemberModel.findOne({
      projectId, userId: targetUserId,
    });
    if (!requesterRole || !target) {
      throw new NotFoundException('Không tìm thấy thành viên');
    }
    const requester = { role: requesterRole };
    if (requester.role === 'Manager') {
      if (target.role === 'Admin' || target.role === 'Manager') {
        throw new ForbiddenException(
          'Quản lý không được xóa Quản trị hoặc Quản lý khác',
        );
      }
    } else if (requester.role !== 'Admin') {
      throw new ForbiddenException('Bạn không có quyền thực hiện hành động này');
    }
    await this.projectMemberModel.deleteOne({
      projectId, userId: targetUserId,
    });

    // Real-time: update the room + tell the removed user (while they're
    // still connected) so their project list refreshes.
    this.gateway.emitToProject(projectId, 'member_removed', {
      projectId,
      userId: targetUserId,
    });
    this.gateway.emitToUser(targetUserId, 'project_list_changed', {
      projectId,
    });

    return { message: 'Đã xóa thành viên khỏi dự án' };
  }

  async updateMemberRole(
    projectId: string,
    targetUserId: string,
    newRole: string,
    currentUserId: string,
  ) {
    const validRoles = ['Admin', 'Manager', 'Member'];
    if (!validRoles.includes(newRole)) {
      throw new BadRequestException('Vai trò không hợp lệ');
    }
    // Owner counts as implicit Admin (see removeMember) — one RBAC rule
    // for every member-management operation.
    const project = await this.projectModel.findById(projectId);
    if (!project) throw new NotFoundException('Không tìm thấy dự án');
    const isOwner = project.ownerId.toString() === currentUserId;

    const requesterMember = await this.projectMemberModel.findOne({
      projectId, userId: currentUserId,
    });
    const requesterRole =
      requesterMember?.role ?? (isOwner ? 'Admin' : null);
    if (requesterRole !== 'Admin') {
      throw new ForbiddenException('Chỉ Quản trị mới được đổi vai trò');
    }
    const target = await this.projectMemberModel.findOne({
      projectId, userId: targetUserId,
    });
    if (!target) {
      throw new NotFoundException('Không tìm thấy thành viên');
    }
    target.role = newRole;
    await target.save();

    // Real-time: role change is visible to the whole room instantly.
    this.gateway.emitToProject(projectId, 'member_role_changed', {
      projectId,
      userId: targetUserId,
      role:   newRole,
    });
    this.gateway.emitToUser(targetUserId, 'project_list_changed', {
      projectId,
    });

    return { message: `Đã đổi vai trò thành ${newRole}`, role: newRole };
  }
}