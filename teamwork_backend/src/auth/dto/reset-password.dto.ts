import { IsEmail, IsString, Length, MaxLength, MinLength } from 'class-validator';

export class ResetPasswordDto {
  @IsEmail({}, { message: 'Email không hợp lệ' })
  email: string;

  @IsString()
  @Length(6, 6, { message: 'Mã OTP gồm 6 ký tự' })
  otp: string;

  @IsString()
  @MinLength(6, { message: 'Mật khẩu tối thiểu 6 ký tự' })
  @MaxLength(100, { message: 'Mật khẩu tối đa 100 ký tự' })
  newPassword: string;
}
