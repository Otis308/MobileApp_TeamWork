import { IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class CreateProjectDto {
  @IsString()
  @MinLength(1, { message: 'Tên dự án không được để trống' })
  @MaxLength(100, { message: 'Tên dự án tối đa 100 ký tự' })
  name: string;

  @IsOptional()
  @IsString()
  @MaxLength(1000, { message: 'Mô tả tối đa 1000 ký tự' })
  description?: string;
}

export class UpdateProjectDto {
  @IsOptional()
  @IsString()
  @MinLength(1, { message: 'Tên dự án không được để trống' })
  @MaxLength(100, { message: 'Tên dự án tối đa 100 ký tự' })
  name?: string;

  @IsOptional()
  @IsString()
  @MaxLength(1000, { message: 'Mô tả tối đa 1000 ký tự' })
  description?: string;
}
