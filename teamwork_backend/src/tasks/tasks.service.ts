import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Task } from './schemas/task.schema';
import { TaskComment } from './schemas/task-comment.schema';
import { Notification } from '../notifications/schemas/notification.schema';
import { Project } from '../projects/schemas/project.schema';
import { ProjectMember } from '../projects/schemas/project-member.schema';
import { CreateTaskDto, UpdateTaskDto, MoveTaskDto } from './dto/task.dto';
import { CreateCommentDto } from './dto/create-comment.dto';
import { GetTasksQueryDto } from './dto/get-tasks-query.dto';
import { placeInColumn } from './task-order.util';
import { isOverdue, overdueCutoff } from './task-overdue.util';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';
import { User } from '../auth/schemas/user.schema';
import { AppGateway } from '../gateway/app.gateway';
import { ProjectAccessService } from '../common/project-access/project-access.service';

@Injectable()
export class TasksService {
  private readonly logger = new Logger(TasksService.name);

  constructor(
    @InjectModel(Task.name)
    private taskModel: Model<Task>,
    @InjectModel(TaskComment.name)
    private taskCommentModel: Model<TaskComment>,
    @InjectModel(Notification.name)
    private notificationModel: Model<Notification>,
    @InjectModel(Project.name)
    private projectModel: Model<Project>,
    @InjectModel(ProjectMember.name)
    private projectMemberModel: Model<ProjectMember>,
    @InjectModel(User.name)
    private userModel: Model<User>,
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
    }).catch((err) => this.logger.warn('Lỗi gửi email', err));
  }

  private _objectIdOrFail(value: string, field: string): Types.ObjectId {
    if (!Types.ObjectId.isValid(value)) {
      throw new BadRequestException(`${field} không hợp lệ`);
    }
    return new Types.ObjectId(value);
  }

  // Mô hình mở (giống Trello): mọi member đều sửa được nội dung task (xem updateTask).
  // Riêng XÓA thì chỉ Quản trị viên hoặc chính người tạo task mới được phép.
  private async _assertCanDeleteTask(task: Task, currentUserId: string) {
    const role = await this.access.getEffectiveRole(task.projectId.toString(), currentUserId);
    const isCreator = task.createdBy.toString() === currentUserId;
    if (!isCreator && role !== 'Admin') {
      throw new ForbiddenException(
        'Chỉ Quản trị viên hoặc người tạo công việc này mới được xóa',
      );
    }
  }

  private async _assertAssigneeInProject(
    projectId: string,
    assigneeId: string,
  ) {
    const project = await this.projectModel.findById(projectId);
    if (!project) throw new NotFoundException('Không tìm thấy dự án');

    const isOwner = project.ownerId.toString() === assigneeId;
    const member = await this.projectMemberModel.findOne({
      projectId,
      userId: assigneeId,
    });
    if (!isOwner && !member) {
      throw new BadRequestException('Người được giao không thuộc dự án này');
    }
  }

  async getProjectTasks(
    projectId: string,
    currentUserId?: string,
    filters: GetTasksQueryDto = {},
  ) {
    if (currentUserId !== undefined) {
      await this.access.assertIsMember(projectId, currentUserId);
    }
    const now = new Date();
    const query: Record<string, any> = { projectId };
    if (filters.assigneeId) query.assigneeId = filters.assigneeId;
    if (filters.priority) query.priority = filters.priority;

    const dueRange: Record<string, Date> = {};
    if (filters.dueAfter) dueRange.$gte = new Date(filters.dueAfter);
    const lte = filters.dueBefore ? new Date(filters.dueBefore) : undefined;
    if (lte) dueRange.$lte = lte;
    if (Object.keys(dueRange).length > 0) query.dueDate = dueRange;
    if (filters.overdue) {
      // Task có giờ quá hạn đúng giờ hạn; task chỉ có ngày quá hạn sau khi cả ngày trôi qua.
      query.status = { $ne: 'done' };
      query.$or = [
        { dueHasTime: true, dueDate: { $lte: now } },
        { dueHasTime: { $ne: true }, dueDate: { $lte: overdueCutoff(now) } },
      ];
    }

    const tasks = (
      await this.taskModel
        .find(query)
        .populate('assigneeId', 'fullName email avatarUrl')
        .populate('createdBy', 'fullName')
        .sort({ order: 1, createdAt: 1 })
    ).map((t) => ({ ...t.toObject(), isOverdue: isOverdue(t.status, t.dueDate, now, t.dueHasTime) }));

    return {
      todo:  tasks.filter((t) => t.status === 'todo'),
      doing: tasks.filter((t) => t.status === 'doing'),
      done:  tasks.filter((t) => t.status === 'done'),
    };
  }

  async getProjectProgress(projectId: string, currentUserId?: string) {
    if (currentUserId !== undefined) {
      await this.access.assertIsMember(projectId, currentUserId);
    }
    const total = await this.taskModel.countDocuments({ projectId });
    const done  = await this.taskModel.countDocuments({
      projectId, status: 'done',
    });

    return {
      total,
      done,
      percent: total === 0 ? 0 : Math.round((done / total) * 100),
    };
  }

  async createTask(dto: CreateTaskDto, createdBy: string) {
    const title = (dto.title ?? '').trim();
    if (!title) throw new BadRequestException('Tiêu đề công việc không được để trống');

    const projectId = this._objectIdOrFail(dto.projectId, 'projectId');
    const creatorId = this._objectIdOrFail(createdBy, 'createdBy');
    const assigneeId = dto.assigneeId
      ? this._objectIdOrFail(dto.assigneeId, 'assigneeId')
      : null;

    await this.access.assertIsMember(projectId.toString(), createdBy);
    if (assigneeId) {
      await this._assertAssigneeInProject(
        projectId.toString(),
        assigneeId.toString(),
      );
    }

    let dueDate: Date | undefined;
    if (dto.dueDate) {
      const parsed = new Date(dto.dueDate);
      if (Number.isNaN(parsed.getTime())) {
        throw new BadRequestException('dueDate không hợp lệ');
      }
      dueDate = parsed;
    }

    const count = await this.taskModel.countDocuments({
      projectId, status: 'todo',
    });

    const task = await this.taskModel.create({
      title,
      description: dto.description ?? '',
      projectId,
      assigneeId,
      createdBy: creatorId,
      dueDate,
      dueHasTime:  dueDate ? dto.dueHasTime === true : false,
      priority:    dto.priority ?? 'medium',
      status:      'todo',
      order:       count,
    });

    if (dto.assigneeId) {
      await this._notifyAssigned(
        task._id.toString(),
        dto.assigneeId,
        dto.title,
        dto.projectId,
      );
    }

    this.gateway.emitToProject(dto.projectId, 'task_created', {
      taskId:    task._id.toString(),
      title:     task.title,
      status:    task.status,
      task:      task.toObject ? task.toObject() : task,
      projectId: dto.projectId,
    });

    return task;
  }

  async updateTask(
    taskId: string,
    dto: UpdateTaskDto,
    currentUserId: string,
  ) {
    const parsedTaskId = this._objectIdOrFail(taskId, 'taskId');
    const task = await this.taskModel.findById(parsedTaskId);
    if (!task) throw new NotFoundException('Không tìm thấy task');

    // Mô hình mở: mọi member của dự án đều được sửa task (không chỉ creator/assignee).
    await this.access.assertIsMember(task.projectId.toString(), currentUserId);

    const oldAssigneeId = task.assigneeId?.toString();

    if (dto.title !== undefined) {
      const title = dto.title.trim();
      if (!title) throw new BadRequestException('Tiêu đề công việc không được để trống');
      task.title = title;
    }
    if (dto.description !== undefined) task.description = dto.description;
    if (dto.status !== undefined && dto.status !== task.status) {
      // Đổi cột qua update: xếp xuống cuối cột mới (kéo thả dùng moveTask).
      task.order = await this.taskModel.countDocuments({
        projectId: task.projectId, status: dto.status,
      });
      task.status = dto.status;
    }
    if (dto.priority !== undefined) task.priority = dto.priority;
    if (dto.assigneeId !== undefined) {
      task.assigneeId = dto.assigneeId
        ? this._objectIdOrFail(dto.assigneeId, 'assigneeId')
        : null;
      if (task.assigneeId) {
        await this._assertAssigneeInProject(
          task.projectId.toString(),
          task.assigneeId.toString(),
        );
      }
    }
    if (dto.dueDate !== undefined) {
      if (!dto.dueDate) {
        task.dueDate = undefined;
        task.dueHasTime = false;
      } else {
        const parsed = new Date(dto.dueDate);
        if (Number.isNaN(parsed.getTime())) {
          throw new BadRequestException('dueDate không hợp lệ');
        }
        task.dueDate = parsed;
        task.dueHasTime = dto.dueHasTime === true;
      }
    }
    await task.save();

    if (
      dto.assigneeId &&
      dto.assigneeId !== oldAssigneeId
    ) {
      await this._notifyAssigned(
        taskId,
        dto.assigneeId,
        task.title,
        task.projectId.toString(),
      );
    }

    this.gateway.emitToProject(task.projectId.toString(), 'task_updated', {
      taskId:    task._id.toString(),
      status:    task.status,
      title:     task.title,
      task:      task.toObject ? task.toObject() : task,
      projectId: task.projectId.toString(),
    });

    return task;
  }

  async moveTask(taskId: string, dto: MoveTaskDto, currentUserId?: string) {
    const parsedTaskId = this._objectIdOrFail(taskId, 'taskId');
    const task = await this.taskModel.findById(parsedTaskId);
    if (!task) throw new NotFoundException('Không tìm thấy task');

    if (currentUserId !== undefined) {
      await this.access.assertIsMember(task.projectId.toString(), currentUserId);
    }

    const projectId = task.projectId;
    const fromStatus = task.status;
    const toStatus = dto.status;

    const columnIds = async (status: Task['status']) =>
      (
        await this.taskModel
          .find({ projectId, status, _id: { $ne: task._id } })
          .sort({ order: 1, createdAt: 1 })
          .select('_id')
      ).map((t) => t._id.toString());

    // Tính lại order liên tục 0..n-1 cho cột đích (và cột nguồn nếu đổi cột)
    // để không bao giờ trùng/lệch order sau nhiều lần kéo thả.
    const destIds = placeInColumn(
      await columnIds(toStatus),
      task._id.toString(),
      dto.targetIndex,
    );
    const orders: Record<string, string[]> = { [toStatus]: destIds };

    const ops: any[] = destIds.map((id, i) => ({
      updateOne: {
        filter: { _id: id },
        update: { $set: id === task._id.toString() ? { order: i, status: toStatus } : { order: i } },
      },
    }));

    if (fromStatus !== toStatus) {
      const sourceIds = await columnIds(fromStatus);
      orders[fromStatus] = sourceIds;
      sourceIds.forEach((id, i) =>
        ops.push({ updateOne: { filter: { _id: id }, update: { $set: { order: i } } } }),
      );
    }

    // Không dùng transaction (cần replica set); cửa sổ race nhỏ được chấp nhận cho MVP.
    await this.taskModel.bulkWrite(ops);

    const moved = await this.taskModel.findById(task._id);
    if (!moved) throw new NotFoundException('Không tìm thấy task');

    this.gateway.emitToProject(projectId.toString(), 'task_moved', {
      taskId:    task._id.toString(),
      status:    toStatus,
      order:     moved.order,
      orders, // thứ tự id của các cột bị ảnh hưởng
      task:      moved.toObject ? moved.toObject() : moved,
      projectId: projectId.toString(),
    });

    return moved;
  }

  async deleteTask(taskId: string, currentUserId?: string) {
    const parsedTaskId = this._objectIdOrFail(taskId, 'taskId');
    const task = await this.taskModel.findById(parsedTaskId);
    if (!task) throw new NotFoundException('Không tìm thấy task');

    if (currentUserId !== undefined) {
      await this.access.assertIsMember(task.projectId.toString(), currentUserId);
      await this._assertCanDeleteTask(task, currentUserId);
    }

    await task.deleteOne();

    this.gateway.emitToProject(task.projectId.toString(), 'task_deleted', {
      taskId:    task._id.toString(),
      projectId: task.projectId.toString(),
    });

    return { message: 'Đã xóa task' };
  }

  private async _notifyAssigned(
    taskId: string,
    assigneeId: string,
    taskTitle: string,
    projectId?: string,
  ) {
    const user = await this.userModel.findById(assigneeId);
    const project = projectId
      ? await this.projectModel.findById(projectId)
      : null;

    const notif = await this.notificationModel.create({
      userId:  this._objectIdOrFail(assigneeId, 'assigneeId'),
      type:    'task_assigned',
      title:   'Bạn được giao việc mới',
      body:    `Công việc: "${taskTitle}"`,
      refId:   this._objectIdOrFail(taskId, 'taskId'),
      refType: 'task',
      isRead:  false,
    });

    if (user?.email) {
      await this._sendEmail(
        user.email,
        'Bạn được giao một công việc mới',
        `<b>Xin chào ${user.fullName ?? user.email}</b><br/>Bạn được giao công việc <b>${taskTitle}</b>${project?.name ? ` trong dự án <b>${project.name}</b>` : ''}.<br/>Hãy mở ứng dụng để xem chi tiết.`,
      );
    }

    this.gateway.emitToUser(assigneeId, 'notification', {
      id:    notif._id,
      type:  notif.type,
      title: notif.title,
      body:  notif.body,
      refId: taskId,
      refType: 'task',
    });

    if (projectId) {
      this.gateway.emitToUser(assigneeId, 'new_task_assigned', {
        type: 'task_assigned',
        title: 'Bạn được giao việc mới',
        body: `Công việc: "${taskTitle}"`,
        taskId,
        taskTitle,
        projectId,
        projectName: project?.name ?? '',
      });
    }
  }

  // ── Bình luận trên task ──

  private _formatComment(c: any) {
    const obj = c.toObject ? c.toObject() : c;
    return {
      _id:       obj._id,
      content:   obj.content,
      createdAt: obj.createdAt,
      userId:    obj.userId,
    };
  }

  async getComments(taskId: string, currentUserId?: string) {
    const parsedTaskId = this._objectIdOrFail(taskId, 'taskId');
    const task = await this.taskModel.findById(parsedTaskId);
    if (!task) throw new NotFoundException('Không tìm thấy task');

    if (currentUserId !== undefined) {
      await this.access.assertIsMember(task.projectId.toString(), currentUserId);
    }

    const comments = await this.taskCommentModel
      .find({ taskId: parsedTaskId })
      .sort({ createdAt: 1 })
      .populate('userId', 'fullName avatarUrl');

    return comments.map((c) => this._formatComment(c));
  }

  async addComment(taskId: string, dto: CreateCommentDto, currentUserId: string) {
    const parsedTaskId = this._objectIdOrFail(taskId, 'taskId');
    const task = await this.taskModel.findById(parsedTaskId);
    if (!task) throw new NotFoundException('Không tìm thấy task');

    await this.access.assertIsMember(task.projectId.toString(), currentUserId);

    const created = await this.taskCommentModel.create({
      taskId:  parsedTaskId,
      userId:  this._objectIdOrFail(currentUserId, 'userId'),
      content: dto.content.trim(),
    });
    const populated = await created.populate('userId', 'fullName avatarUrl');
    const comment = this._formatComment(populated);
    const projectId = task.projectId.toString();

    this.gateway.emitToProject(projectId, 'task_comment_added', {
      taskId,
      projectId,
      comment,
    });

    // Báo cho "phía còn lại": ưu tiên assignee (nếu khác người bình luận),
    // nếu không có hoặc chính là người bình luận thì báo cho người tạo task.
    const assigneeId = task.assigneeId?.toString();
    const creatorId = task.createdBy.toString();
    const notifyUserId =
      assigneeId && assigneeId !== currentUserId
        ? assigneeId
        : creatorId !== currentUserId
          ? creatorId
          : null;

    if (notifyUserId) {
      const commenter = await this.userModel.findById(currentUserId);
      const commenterName = commenter?.fullName ?? commenter?.email ?? 'Một thành viên';
      const notif = await this.notificationModel.create({
        userId:  this._objectIdOrFail(notifyUserId, 'userId'),
        type:    'task_comment',
        title:   'Có bình luận mới',
        body:    `${commenterName} đã bình luận vào công việc "${task.title}"`,
        refId:   parsedTaskId,
        refType: 'task',
        isRead:  false,
      });
      this.gateway.emitToUser(notifyUserId, 'notification', {
        id:    notif._id,
        type:  notif.type,
        title: notif.title,
        body:  notif.body,
        refId: taskId,
        refType: 'task',
      });
    }

    return comment;
  }

  async deleteComment(taskId: string, commentId: string, currentUserId: string) {
    const parsedTaskId = this._objectIdOrFail(taskId, 'taskId');
    const parsedCommentId = this._objectIdOrFail(commentId, 'commentId');

    const comment = await this.taskCommentModel.findOne({
      _id: parsedCommentId,
      taskId: parsedTaskId,
    });
    if (!comment) throw new NotFoundException('Không tìm thấy bình luận');
    if (comment.userId.toString() !== currentUserId) {
      throw new ForbiddenException('Bạn chỉ được xóa bình luận của chính mình');
    }

    await comment.deleteOne();

    const task = await this.taskModel.findById(parsedTaskId);
    const projectId = task?.projectId.toString();
    if (projectId) {
      this.gateway.emitToProject(projectId, 'task_comment_deleted', {
        taskId,
        projectId,
        commentId,
      });
    }

    return { message: 'Đã xóa bình luận' };
  }
}