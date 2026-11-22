import { IsEmail } from 'class-validator';

export class RequestResetDto {
  @IsEmail({}, { message: 'Email không hợp lệ' })
  email: string;
}
