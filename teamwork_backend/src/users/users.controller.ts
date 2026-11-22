import {
  BadRequestException, Body, Controller, Get, Patch, Post, UploadedFile, UseGuards, UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { existsSync, mkdirSync } from 'fs';
import { join } from 'path';
import { randomUUID } from 'crypto';
import { UsersService } from './users.service';
import { UpdateProfileDto, UpdatePermissionsDto } from './dto/update-profile.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';

export const AVATAR_DIR = join(process.cwd(), 'uploads', 'avatars');
const ALLOWED_IMAGE_EXT: Record<string, string> = {
  'image/jpeg': '.jpg',
  'image/png': '.png',
  'image/webp': '.webp',
};

@UseGuards(JwtAuthGuard)
@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('me')
  getProfile(@CurrentUser('userId') userId: string) {
    return this.usersService.getProfile(userId);
  }

  @Patch('me')
  updateProfile(@CurrentUser('userId') userId: string, @Body() dto: UpdateProfileDto) {
    return this.usersService.updateProfile(userId, dto);
  }

  // Ảnh đại diện: multipart field `file`, tối đa 5MB, chỉ jpeg/png/webp.
  @Post('me/avatar')
  @UseInterceptors(
    FileInterceptor('file', {
      limits: { fileSize: 5 * 1024 * 1024 },
      fileFilter: (_req, file, cb) =>
        ALLOWED_IMAGE_EXT[file.mimetype]
          ? cb(null, true)
          : cb(new BadRequestException('Chỉ nhận ảnh JPG, PNG hoặc WEBP'), false),
      storage: diskStorage({
        destination: (_req, _file, cb) => {
          if (!existsSync(AVATAR_DIR)) mkdirSync(AVATAR_DIR, { recursive: true });
          cb(null, AVATAR_DIR);
        },
        // Tên ngẫu nhiên: không dùng tên client gửi (tránh path traversal / ghi đè).
        filename: (_req, file, cb) =>
          cb(null, `${randomUUID()}${ALLOWED_IMAGE_EXT[file.mimetype]}`),
      }),
    }),
  )
  uploadAvatar(
    @CurrentUser('userId') userId: string,
    @UploadedFile() file?: { filename: string },
  ) {
    if (!file) throw new BadRequestException('Thiếu file ảnh');
    return this.usersService.setAvatar(userId, file.filename);
  }

  @Get('me/permissions')
  getPermissions(@CurrentUser('userId') userId: string) {
    return this.usersService.getPermissions(userId);
  }

  @Patch('me/permissions')
  updatePermissions(@CurrentUser('userId') userId: string, @Body() dto: UpdatePermissionsDto) {
    return this.usersService.updatePermissions(userId, dto);
  }
}
