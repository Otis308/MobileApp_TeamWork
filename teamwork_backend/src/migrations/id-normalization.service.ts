import { Injectable, Logger, OnApplicationBootstrap } from '@nestjs/common';
import { InjectConnection } from '@nestjs/mongoose';
import { Connection } from 'mongoose';

// Trước đây các schema khai báo `type: Types.ObjectId` nên Mongoose coi là Mixed và lưu
// nguyên chuỗi được truyền vào. Dữ liệu cũ vì thế có id dạng chuỗi lẫn với ObjectId và
// không khớp truy vấn. Bước này đổi mọi id dạng chuỗi hợp lệ về ObjectId. Idempotent:
// chạy lại không làm gì nếu không còn chuỗi nào.
const ID_FIELDS: Record<string, string[]> = {
  projectmembers: ['projectId', 'userId'],
  tasks: ['projectId', 'assigneeId', 'createdBy'],
  projects: ['ownerId'],
  notifications: ['userId', 'refId'],
};

@Injectable()
export class IdNormalizationService implements OnApplicationBootstrap {
  private readonly logger = new Logger(IdNormalizationService.name);

  constructor(@InjectConnection() private readonly connection: Connection) {}

  async onApplicationBootstrap() {
    try {
      for (const [collection, fields] of Object.entries(ID_FIELDS)) {
        for (const field of fields) {
          const result = await this.connection.collection(collection).updateMany(
            { [field]: { $type: 'string', $regex: /^[0-9a-fA-F]{24}$/ } },
            [{ $set: { [field]: { $toObjectId: `$${field}` } } }],
          );
          if (result.modifiedCount > 0) {
            this.logger.warn(
              `Đã chuẩn hóa ${result.modifiedCount} giá trị ${collection}.${field} từ chuỗi sang ObjectId`,
            );
          }
        }
      }
    } catch (err) {
      // Không chặn khởi động server nếu bước dọn dữ liệu lỗi.
      this.logger.error('Chuẩn hóa id thất bại', err as Error);
    }
  }
}
