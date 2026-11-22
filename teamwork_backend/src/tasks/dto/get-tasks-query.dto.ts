import { Transform } from 'class-transformer';
import { IsBoolean, IsIn, IsISO8601, IsMongoId, IsOptional } from 'class-validator';
import { TASK_PRIORITIES } from './task.dto';

export class GetTasksQueryDto {
  @IsOptional()
  @IsMongoId()
  assigneeId?: string;

  @IsOptional()
  @IsIn(TASK_PRIORITIES)
  priority?: 'low' | 'medium' | 'high';

  @IsOptional()
  @IsISO8601()
  dueAfter?: string;

  @IsOptional()
  @IsISO8601()
  dueBefore?: string;

  // ?overdue=true → chỉ task chưa xong và đã quá hạn
  @IsOptional()
  @Transform(({ value }) => value === 'true' || value === true)
  @IsBoolean()
  overdue?: boolean;
}
