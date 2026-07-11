import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe, VersioningType } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import cookieParser from 'cookie-parser';
import helmet from 'helmet';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Enable CORS
  app.enableCors({
    origin: process.env.CORS_ORIGINS ? process.env.CORS_ORIGINS.split(',') : 'http://localhost:3000',
    credentials: true,
  });

  // Enable Security Headers
  app.use(helmet());

  // Enable Cookie Parser
  app.use(cookieParser());

  // Global Prefix & Versioning
  app.setGlobalPrefix('api');
  app.enableVersioning({
    type: VersioningType.URI,
    defaultVersion: '1',
  });

  // Global Validation Pipe
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
    }),
  );

  // Swagger Documentation Setup
  const config = new DocumentBuilder()
    .setTitle('Trimly Business OS API')
    .setDescription('Enterprise multi-tenant salon & appointment booking platform API')
    .setVersion('1.0')
    .addBearerAuth()
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/v1/docs', app, document);

  const port = process.env.PORT || 4000;
  await app.listen(port);
  console.info(`🚀 Trimly Backend API running on: http://localhost:${port}/api/v1`);
  console.info(`📖 Swagger Docs available at: http://localhost:${port}/api/v1/docs`);
}

bootstrap();
