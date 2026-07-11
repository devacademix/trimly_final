import { Injectable } from '@nestjs/common';
import * as client from 'prom-client';

@Injectable()
export class MetricsService {
  private readonly registry: client.Registry;

  constructor() {
    this.registry = new client.Registry();
    this.registry.setDefaultLabels({
      app: 'trimly-backend',
    });
    client.collectDefaultMetrics({ register: this.registry });
  }

  async getMetrics(): Promise<string> {
    return this.registry.metrics();
  }
}
