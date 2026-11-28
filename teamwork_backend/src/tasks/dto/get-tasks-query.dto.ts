import { Transform } from 'class-transformer';
import { IsBoolean, IsIn, IsISO8601, IsMongoId, IsOptional } from 'class-validator';
import { TASK_PRIORITIES } from './task.dto';

export class GetTasksQueryDto {
  @IsOptional()
  @IsMongoId({ message: 'assigneeId không hợp lệ' })
  assigneeId?: string;

  @IsOptional()
  @IsIn(TASK_PRIORITIES, { message: 'Độ ưu tiên không hợp lệ' })
  priority?: 'low' | 'medium' | 'high';

  @IsOptional()
  @IsISO8601({}, { message: 'dueAfter không hợp lệ' })
  dueAfter?: string;

  @IsOptional()
  @IsISO8601({}, { message: 'dueBefore không hợp lệ' })
  dueBefore?: string;

  // ?overdue=true → chỉ task chưa xong và đã quá hạn
  @IsOptional()
  @Transform(({ value }) => value === 'true' || value === true)
  @IsBoolean({ message: 'overdue phải là true/false' })
  overdue?: boolean;
}
