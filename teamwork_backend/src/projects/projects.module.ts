import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ProjectsController } from './projects.controller';
import { ProjectsService } from './projects.service';
import { Project, ProjectSchema } from './schemas/project.schema';
import { ProjectMember, ProjectMemberSchema } from './schemas/project-member.schema';
import { User, UserSchema } from '../auth/schemas/user.schema';
import { Task, TaskSchema } from '../tasks/schemas/task.schema';
import { Notification, NotificationSchema } from '../notifications/schemas/notification.schema';
import { GatewayModule } from '../gateway/gateway.module';
import { ProjectAccessModule } from '../common/project-access/project-access.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Project.name,      schema: ProjectSchema },
      { name: ProjectMember.name, schema: ProjectMemberSchema },
      { name: User.name,         schema: UserSchema },
      { name: Task.name,         schema: TaskSchema },
      { name: Notification.name, schema: NotificationSchema },  
    ]),
    GatewayModule,
    ProjectAccessModule,  
  ],
  controllers: [ProjectsController],
  providers:   [ProjectsService],
})
export class ProjectsModule {}