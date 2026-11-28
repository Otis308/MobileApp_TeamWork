import { BadRequestException, ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { User } from '../auth/schemas/user.schema';
import { ProjectMember } from '../projects/schemas/project-member.schema';
import { AppGateway } from '../gateway/app.gateway';
import { isValidBirthDate } from './birth-date.util';
import { UpdateProfileDto, UpdatePermissionsDto } from './dto/update-profile.dto';

const PROFILE_FIELDS = 'fullName email username phone birthDate gender avatarUrl permissions';

function toProfile(user: User) {
  return {
    id:          user._id,
    fullName:    user.fullName,
    email:       user.email,
    username:    user.username  ?? '',
    phone:       user.phone     ?? '',
    birthDate:   user.birthDate ?? '',
    gender:      user.gender    ?? '',
    avatarUrl:   user.avatarUrl ?? '',
    permissions: user.permissions ?? { camera: false, contacts: false, messages: false },
  };
}

@Injectable()
export class UsersService {
  constructor(
    @InjectModel(User.name) private userModel: Model<User>,
    @InjectModel(ProjectMember.name) private projectMemberModel: Model<ProjectMember>,
    private readonly gateway: AppGateway,
  ) {}

  // Đẩy hồ sơ mới nhất tới mọi dự án mà user đang là thành viên, để danh sách
  // nhóm của người khác (vd số điện thoại) cập nhật ngay, không cần tải lại.
  private async _broadcastProfileUpdate(userId: string, profile: ReturnType<typeof toProfile>) {
    const memberships = await this.projectMemberModel.find({ userId }).select('projectId');
    for (const m of memberships) {
      this.gateway.emitToProject(m.projectId.toString(), 'member_profile_updated', {
        userId,
        fullName:  profile.fullName,
        email:     profile.email,
        phone:     profile.phone,
        avatarUrl: profile.avatarUrl,
      });
    }
  }

  async getProfile(userId: string) {
    const user = await this.userModel.findById(userId).select(PROFILE_FIELDS);
    if (!user) throw new NotFoundException('Không tìm thấy người dùng');
    return toProfile(user);
  }

  async updateProfile(userId: string, dto: UpdateProfileDto) {
    const set: Record<string, string> = {};
    const unset: Record<string, 1> = {};

    if (dto.fullName !== undefined) {
      if (dto.fullName.trim() === '') throw new BadRequestException('Họ và tên không được để trống');
      set.fullName = dto.fullName.trim();
    }
    if (dto.avatarUrl !== undefined) set.avatarUrl = dto.avatarUrl;
    if (dto.phone     !== undefined) set.phone     = dto.phone.trim();
    if (dto.gender    !== undefined) set.gender    = dto.gender;

    if (dto.birthDate !== undefined) {
      if (dto.birthDate !== '' && !isValidBirthDate(dto.birthDate)) {
        throw new BadRequestException('Ngày sinh không hợp lệ');
      }
      set.birthDate = dto.birthDate;
    }

    if (dto.username !== undefined) {
      const username = dto.username.trim().toLowerCase();
      if (username === '') {
        unset.username = 1; // index sparse: bỏ hẳn field thay vì lưu ''
      } else {
        const taken = await this.userModel.exists({ username, _id: { $ne: userId } });
        if (taken) throw new ConflictException('Username đã được sử dụng');
        set.username = username;
      }
    }

    const update: Record<string, unknown> = {};
    if (Object.keys(set).length)   update.$set = set;
    if (Object.keys(unset).length) update.$unset = unset;

    try {
      const updated = Object.keys(update).length
        ? await this.userModel
            .findByIdAndUpdate(userId, update, { new: true })
            .select(PROFILE_FIELDS)
        : await this.userModel.findById(userId).select(PROFILE_FIELDS);

      if (!updated) throw new NotFoundException('Không tìm thấy người dùng');
      const profile = toProfile(updated);
      await this._broadcastProfileUpdate(userId, profile);
      return { ...profile, message: 'Cập nhật thành công' };
    } catch (err: any) {
      if (err?.code === 11000) throw new ConflictException('Username đã được sử dụng');
      throw err;
    }
  }

  async setAvatar(userId: string, filename: string) {
    return this.updateProfile(userId, { avatarUrl: `/uploads/avatars/${filename}` });
  }

  async getPermissions(userId: string) {
    const user = await this.userModel
      .findById(userId)
      .select('permissions');

    if (!user) throw new NotFoundException('Không tìm thấy người dùng');
    return user.permissions ?? { camera: false, contacts: false, messages: false };
  }

  async updatePermissions(userId: string, dto: UpdatePermissionsDto) {
    const set: Record<string, boolean> = {};
    if (dto.camera   !== undefined) set['permissions.camera']   = dto.camera;
    if (dto.contacts !== undefined) set['permissions.contacts'] = dto.contacts;
    if (dto.messages !== undefined) set['permissions.messages'] = dto.messages;

    await this.userModel.findByIdAndUpdate(userId, { $set: set });
    return { message: 'Cập nhật quyền thành công' };
  }
}
