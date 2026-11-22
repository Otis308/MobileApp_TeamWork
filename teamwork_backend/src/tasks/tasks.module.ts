import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { TasksController } from './tasks.controller';
import { TasksService } from './tasks.service';
import { Task, TaskSchema } from './schemas/task.schema';
import { Notification, NotificationSchema } from '../notifications/schemas/notification.schema';
import { Project, ProjectSchema } from '../projects/schemas/project.schema';
import { ProjectMember, ProjectMemberSchema } from '../projects/schemas/project-member.schema';
import { User, UserSchema } from '../auth/schemas/user.schema';
import { GatewayModule } from '../gateway/gateway.module';
import { ProjectAccessModule } from '../common/project-access/project-access.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Task.name, schema: TaskSchema },
      { name: Notification.name, schema: NotificationSchema },
      { name: Project.name, schema: ProjectSchema },
      { name: ProjectMember.name, schema: ProjectMemberSchema },
      { name: User.name, schema: UserSchema },
    ]),
    GatewayModule,
    ProjectAccessModule,
  ],
  controllers: [TasksController],
  providers:   [TasksService],
  exports:     [TasksService],
})
export class TasksModule {}