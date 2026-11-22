import { BadRequestException, Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Notification } from './schemas/notification.schema';

@Injectable()
export class NotificationsService {
  constructor(
    @InjectModel(Notification.name)
    private notificationModel: Model<Notification>,
  ) {}

  // Lấy thông báo của user — chưa đọc lên đầu
  async getMyNotifications(userId: string) {
    return this.notificationModel
      .find({ userId: new Types.ObjectId(userId) })
      .sort({ createdAt: -1 })
      .limit(50);
  }

  // Đếm thông báo chưa đọc
  async countUnread(userId: string): Promise<number> {
    return this.notificationModel.countDocuments({
      userId: new Types.ObjectId(userId),
      isRead: false,
    });
  }

  // Đánh dấu đã đọc tất cả
  async markAllRead(userId: string) {
    await this.notificationModel.updateMany(
      { userId: new Types.ObjectId(userId), isRead: false },
      { $set: { isRead: true } },
    );
    return { message: 'Đã đọc tất cả thông báo' };
  }

  // Đánh dấu đã đọc 1 thông báo
  async markOneRead(notifId: string, userId: string) {
    if (!Types.ObjectId.isValid(notifId)) {
      throw new BadRequestException('Mã thông báo không hợp lệ');
    }
    // Chỉ chủ sở hữu mới đánh dấu được thông báo của mình.
    await this.notificationModel.updateOne(
      { _id: notifId, userId: new Types.ObjectId(userId) },
      { $set: { isRead: true } },
    );
    return { message: 'Đã đọc' };
  }
}