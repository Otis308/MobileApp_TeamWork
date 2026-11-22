import { Controller, Get, Patch, Param, Request, UseGuards } from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@UseGuards(JwtAuthGuard)
@Controller('notifications')
export class NotificationsController {
  constructor(private readonly service: NotificationsService) {}

  // GET /notifications
  @Get()
  getMyNotifications(@Request() req: any) {
    return this.service.getMyNotifications(req.user.userId);
  }

  // GET /notifications/unread-count
  @Get('unread-count')
  countUnread(@Request() req: any) {
    return this.service.countUnread(req.user.userId);
  }

  // PATCH /notifications/read-all
  @Patch('read-all')
  markAllRead(@Request() req: any) {
    return this.service.markAllRead(req.user.userId);
  }

  // PATCH /notifications/:id/read
  @Patch(':id/read')
  markOneRead(@Param('id') id: string, @CurrentUser('userId') userId: string) {
    return this.service.markOneRead(id, userId);
  }
}