import {
  IsBoolean, IsIn, IsInt, IsISO8601, IsMongoId, IsOptional, IsString, MaxLength, Min, MinLength,
} from 'class-validator';

export const TASK_STATUSES = ['todo', 'doing', 'done'] as const;
export const TASK_PRIORITIES = ['low', 'medium', 'high'] as const;

export class CreateTaskDto {
  @IsString()
  @MinLength(1, { message: 'Tiêu đề không được để trống' })
  @MaxLength(200)
  title: string;

  @IsOptional()
  @IsString()
  @MaxLength(5000)
  description?: string;

  @IsMongoId()
  projectId: string;

  @IsOptional()
  @IsMongoId()
  assigneeId?: string;

  @IsOptional()
  @IsISO8601()
  dueDate?: string;

  @IsOptional()
  @IsBoolean()
  dueHasTime?: boolean;

  @IsOptional()
  @IsIn(TASK_PRIORITIES)
  priority?: 'low' | 'medium' | 'high';
}

export class UpdateTaskDto {
  @IsOptional()
  @IsString()
  @MinLength(1, { message: 'Tiêu đề không được để trống' })
  @MaxLength(200)
  title?: string;

  @IsOptional()
  @IsString()
  @MaxLength(5000)
  description?: string;

  @IsOptional()
  @IsIn(TASK_STATUSES)
  status?: 'todo' | 'doing' | 'done';

  @IsOptional()
  @IsMongoId()
  assigneeId?: string;

  @IsOptional()
  @IsISO8601()
  dueDate?: string;

  @IsOptional()
  @IsBoolean()
  dueHasTime?: boolean;

  @IsOptional()
  @IsIn(TASK_PRIORITIES)
  priority?: 'low' | 'medium' | 'high';
}

export class MoveTaskDto {
  @IsIn(TASK_STATUSES)
  status: 'todo' | 'doing' | 'done';

  // Vị trí trong cột đích (0 = đầu cột); bỏ trống = cuối cột.
  @IsOptional()
  @IsInt()
  @Min(0)
  targetIndex?: number;
}
