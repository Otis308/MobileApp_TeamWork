import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Schema as MongooseSchema, Types } from 'mongoose';

@Schema({ timestamps: true })
export class TaskComment extends Document {
  @Prop({ type: MongooseSchema.Types.ObjectId, ref: 'Task', required: true })
  taskId: Types.ObjectId;

  @Prop({ type: MongooseSchema.Types.ObjectId, ref: 'User', required: true })
  userId: Types.ObjectId;

  @Prop({ required: true })
  content: string;
}
export const TaskCommentSchema = SchemaFactory.createForClass(TaskComment);
