import 'reflect-metadata';
import { Logger, ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { mkdirSync } from 'node:fs';
import { resolve } from 'node:path';
import { AppModule } from './app.module';
import { env } from './config/env';

async function bootstrap() {
  const config = env();
  const app = await NestFactory.create<NestExpressApplication>(AppModule, {
    logger: config.isProduction ? ['error', 'warn', 'log'] : ['error', 'warn', 'log', 'debug'],
  });

  app.setGlobalPrefix('v1', { exclude: ['health'] });
  app.enableShutdownHooks();
  app.set('trust proxy', 1);
  app.enableCors({
    // The mobile app doesn't need CORS; this is for the admin panel in a browser.
    origin: config.corsOrigins.length ? config.corsOrigins : false,
    credentials: false,
  });
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidUnknownValues: false,
      stopAtFirstError: true,
    }),
  );

  const uploads = resolve(config.uploadDir);
  mkdirSync(uploads, { recursive: true });
  app.useStaticAssets(uploads, { prefix: '/uploads/', maxAge: '7d' });

  if (config.swaggerEnabled) {
    const doc = SwaggerModule.createDocument(
      app,
      new DocumentBuilder()
        .setTitle(`KamKaj Pro API (${config.appEnv})`)
        .setDescription('Money is in paisa (65000 = PKR 650). Errors are `{ statusCode, message }`.')
        .setVersion('1.0')
        .addBearerAuth()
        .build(),
    );
    SwaggerModule.setup('docs', app, doc);
  }

  await app.listen(config.port, '0.0.0.0');
  const log = new Logger('Bootstrap');
  log.log(`KamKaj API [${config.appEnv}] on http://localhost:${config.port}/v1`);
  if (config.swaggerEnabled) log.log(`API docs on http://localhost:${config.port}/docs`);
  if (config.fixedOtp) log.warn(`Staging: every verification code is ${config.fixedOtp}`);
}

void bootstrap();
