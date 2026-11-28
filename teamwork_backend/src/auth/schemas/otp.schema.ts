import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({ timestamps: true })
export class Otp extends Document {
  @Prop({ required: true })
  email: string;

  @Prop({ required: true })
  otpCode: string;

  @Prop({ required: true })
  expiresAt: Date;

  @Prop({ default: 0 })
  failedAttempts: number;

  createdAt: Date;
  updatedAt: Date;
}
export const OtpSchema = SchemaFactory.createForClass(Otp);
