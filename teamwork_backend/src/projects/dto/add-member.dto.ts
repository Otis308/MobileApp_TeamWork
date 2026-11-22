import { IsEmail } from 'class-validator';

export class AddMemberDto {
  @IsEmail({}, { message: 'Email không hợp lệ' })
  email: string;
}
