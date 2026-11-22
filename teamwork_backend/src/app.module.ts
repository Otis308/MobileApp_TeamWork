import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { AppController } from './app.controller';
import { validateEnv } from './config/env.validation';
import { IdNormalizationService } from './migrations/id-normalization.service';
import { AuthModule }          from './auth/auth.module';
import { ProjectsModule }      from './projects/projects.module';
import { UsersModule }         from './users/users.module';
import { TasksModule }         from './tasks/tasks.module';
import { NotificationsModule } from './notifications/notifications.module';
import { GatewayModule }       from './gateway/gateway.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true, validate: validateEnv }),
    MongooseModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        uri: config.get<string>('MONGODB_URI') ?? 'mongodb://127.0.0.1:27017/teamwork',
      }),
    }),
    AuthModule,
    ProjectsModule,
    UsersModule,
    TasksModule,
    NotificationsModule,
    GatewayModule,
  ],
  controllers: [AppController],
  providers: [IdNormalizationService],
})
export class AppModule {}
