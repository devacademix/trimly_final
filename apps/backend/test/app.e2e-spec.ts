import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from '../src/app.module';

describe('Trimly Backend (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  it('/metrics (GET) returns Prometheus metrics text', () => {
    return request(app.getHttpServer())
      .get('/metrics')
      .expect(200)
      .expect('Content-Type', /text\/plain/);
  });

  it('/api/v1/auth/register (POST) rejects missing request fields', () => {
    return request(app.getHttpServer())
      .post('/api/v1/auth/register')
      .send({})
      .expect(400);
  });
});
