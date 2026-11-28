import {
  IsBoolean, IsIn, IsInt, IsISO8601, IsMongoId, IsOptional, IsString, MaxLength, Min, MinLength,
} from 'class-validator';

export const TASK_STATUSES = ['todo', 'doing', 'done'] as const;
export const TASK_PRIORITIES = ['low', 'medium', 'high'] as const;

export class CreateTaskDto {
  @IsString()
  @MinLength(1, { message: 'Tiêu đề không được để trống' })
  @MaxLength(200, { message: 'Tiêu đề tối đa 200 ký tự' })
  title: string;

  @IsOptional()
  @IsString()
  @MaxLength(5000, { message: 'Mô tả tối đa 5000 ký tự' })
  description?: string;

  @IsMongoId({ message: 'projectId không hợp lệ' })
  projectId: string;

  @IsOptional()
  @IsMongoId({ message: 'assigneeId không hợp lệ' })
  assigneeId?: string;

  @IsOptional()
  @IsISO8601({}, { message: 'dueDate không hợp lệ' })
  dueDate?: string;

  @IsOptional()
  @IsBoolean({ message: 'dueHasTime phải là true/false' })
  dueHasTime?: boolean;

  @IsOptional()
  @IsIn(TASK_PRIORITIES, { message: 'Độ ưu tiên không hợp lệ' })
  priority?: 'low' | 'medium' | 'high';
}

export class UpdateTaskDto {
  @IsOptional()
  @IsString()
  @MinLength(1, { message: 'Tiêu đề không được để trống' })
  @MaxLength(200, { message: 'Tiêu đề tối đa 200 ký tự' })
  title?: string;

  @IsOptional()
  @IsString()
  @MaxLength(5000, { message: 'Mô tả tối đa 5000 ký tự' })
  description?: string;

  @IsOptional()
  @IsIn(TASK_STATUSES, { message: 'Trạng thái không hợp lệ' })
  status?: 'todo' | 'doing' | 'done';

  @IsOptional()
  @IsMongoId({ message: 'assigneeId không hợp lệ' })
  assigneeId?: string;

  @IsOptional()
  @IsISO8601({}, { message: 'dueDate không hợp lệ' })
  dueDate?: string;

  @IsOptional()
  @IsBoolean({ message: 'dueHasTime phải là true/false' })
  dueHasTime?: boolean;

  @IsOptional()
  @IsIn(TASK_PRIORITIES, { message: 'Độ ưu tiên không hợp lệ' })
  priority?: 'low' | 'medium' | 'high';
}

export class MoveTaskDto {
  @IsIn(TASK_STATUSES, { message: 'Trạng thái không hợp lệ' })
  status: 'todo' | 'doing' | 'done';

  // Vị trí trong cột đích (0 = đầu cột); bỏ trống = cuối cột.
  @IsOptional()
  @IsInt({ message: 'targetIndex phải là số nguyên' })
  @Min(0, { message: 'targetIndex không được âm' })
  targetIndex?: number;
}
