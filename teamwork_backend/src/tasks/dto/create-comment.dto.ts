import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class CreateCommentDto {
  @IsString()
  @IsNotEmpty({ message: 'Nội dung bình luận không được để trống' })
  @MaxLength(2000, { message: 'Bình luận tối đa 2000 ký tự' })
  content: string;
}
