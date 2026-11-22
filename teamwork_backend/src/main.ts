import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import { join } from 'path';
import { ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);

  // Phục vụ ảnh đại diện đã tải lên: GET /uploads/avatars/<file>
  app.useStaticAssets(join(process.cwd(), 'uploads'), { prefix: '/uploads' });

  // whitelist: bỏ field lạ; chưa forbidNonWhitelisted để không làm vỡ client Flutter đang gửi field thừa.
  app.useGlobalPipes(
    new ValidationPipe({ whitelist: true, transform: true }),
  );

  app.enableCors({
    origin: true, // Mở cửa cho tất cả các port của Flutter Web
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    credentials: true,
  });

  const port = app.get(ConfigService).get<number>('PORT') ?? 3000;
  await app.listen(port);
}
bootstrap();
