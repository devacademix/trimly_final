import { Controller, Get, Header } from '@nestjs/common';
import { MetricsService } from './metrics.service';
import { ApiTags, ApiOperation } from '@nestjs/swagger';

@ApiTags('System Metrics Gateway')
@Controller('metrics')
export class MetricsController {
  constructor(private metricsService: MetricsService) {}

  @Get()
  @Header('Content-Type', 'text/plain; version=0.0.4; charset=utf-8')
  @ApiOperation({ summary: 'Prometheus scraper target metrics endpoint' })
  async getMetrics(): Promise<string> {
    return this.metricsService.getMetrics();
  }
}
