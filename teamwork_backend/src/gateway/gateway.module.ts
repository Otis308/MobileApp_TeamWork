import { Module } from '@nestjs/common';
import { AppGateway } from './app.gateway';
import { AuthModule } from '../auth/auth.module';
import { ProjectAccessModule } from '../common/project-access/project-access.module';

@Module({
  imports: [AuthModule, ProjectAccessModule],
  providers: [AppGateway],
  exports:   [AppGateway],
})
export class GatewayModule {}
