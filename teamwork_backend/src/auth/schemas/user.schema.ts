import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({ timestamps: true })
export class User extends Document {
  @Prop({ required: true })
  fullName: string;

  @Prop({ required: true, unique: true })
  email: string;

  @Prop({ required: true })
  passwordHash: string;

  @Prop()
  resetPasswordOtp: string;

  @Prop()
  otpExpiresAt: Date;

  @Prop({ default: '' })
  phone: string;

  // Không có default: người dùng cũ chưa có username, index sparse bỏ qua họ.
  @Prop({ unique: true, sparse: true, lowercase: true, trim: true })
  username?: string;

  // 'YYYY-MM-DD' — lưu chuỗi để không bị lệch múi giờ.
  @Prop({ default: '' })
  birthDate: string;

  @Prop({ default: '', enum: ['', 'male', 'female', 'other'] })
  gender: string;

  @Prop({ default: '' })
  avatarUrl: string;

  @Prop({
    type: {
      camera:   { type: Boolean, default: false },
      contacts: { type: Boolean, default: false },
      messages: { type: Boolean, default: false },
    },
    default: () => ({ camera: false, contacts: false, messages: false }),
  })
  permissions: {
    camera: boolean;
    contacts: boolean;
    messages: boolean;
  };
}
export const UserSchema = SchemaFactory.createForClass(User);