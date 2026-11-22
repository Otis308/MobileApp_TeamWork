import { applyDecorators } from '@nestjs/common';
import { IsBoolean, IsIn, IsOptional, IsString, Matches, MaxLength, ValidateIf } from 'class-validator';

// Bỏ qua kiểm tra khi trường vắng mặt hoặc là chuỗi rỗng (rỗng = xóa giá trị).
const Present = (...extra: PropertyDecorator[]) =>
  applyDecorators(
    ValidateIf((_o, v) => v !== undefined && v !== null && v !== ''),
    ...extra,
  );

export class UpdateProfileDto {
  @IsOptional()
  @IsString()
  @MaxLength(100)
  fullName?: string;

  @Present(
    IsString(),
    Matches(/^[a-zA-Z0-9_.]{3,30}$/, {
      message: 'Username 3-30 ký tự, chỉ gồm chữ, số, dấu _ và .',
    }),
  )
  username?: string;

  @Present(
    IsString(),
    Matches(/^[0-9+\-\s().]{6,20}$/, { message: 'Số điện thoại không hợp lệ' }),
  )
  phone?: string;

  @Present(
    IsString(),
    Matches(/^\d{4}-\d{2}-\d{2}$/, { message: 'Ngày sinh phải có dạng YYYY-MM-DD' }),
  )
  birthDate?: string;

  @Present(
    IsIn(['male', 'female', 'other'], { message: 'Giới tính không hợp lệ' }),
  )
  gender?: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  avatarUrl?: string;
}

export class UpdatePermissionsDto {
  @IsOptional()
  @IsBoolean()
  camera?: boolean;

  @IsOptional()
  @IsBoolean()
  contacts?: boolean;

  @IsOptional()
  @IsBoolean()
  messages?: boolean;
}
