import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { UsersController } from './users.controller';
import { UsersService } from './users.service';
import { User, UserSchema } from '../auth/schemas/user.schema';
import { ProjectMember, ProjectMemberSchema } from '../projects/schemas/project-member.schema';
import { GatewayModule } from '../gateway/gateway.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: User.name, schema: UserSchema },
      { name: ProjectMember.name, schema: ProjectMemberSchema },
    ]),
    GatewayModule,
  ],
  controllers: [UsersController],
  providers: [UsersService],
})
export class UsersModule {}