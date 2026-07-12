import { createLogger, format, transports } from 'winston';
import type { LoggerService } from '@nestjs/common';

export const winstonLogger = createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: format.combine(
    format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
    format.errors({ stack: true }),
    format.splat(),
    format.json(),
  ),
  defaultMeta: { service: 'trimly-backend' },
  transports: [
    new transports.Console({
      format: format.combine(
        format.colorize(),
        format.printf(({ level, message, timestamp, stack }) => {
          if (stack) {
            return `[${timestamp}] ${level}: ${message}\n${stack}`;
          }
          return `[${timestamp}] ${level}: ${message}`;
        }),
      ),
    }),
  ],
});

// Adapts the winston instance above to Nest's LoggerService interface so it
// can be installed as the framework logger via app.useLogger().
export class NestWinstonLogger implements LoggerService {
  log(message: any, ...optionalParams: any[]) {
    winstonLogger.info(this.stringify(message), ...this.context(optionalParams));
  }

  error(message: any, ...optionalParams: any[]) {
    winstonLogger.error(this.stringify(message), ...this.context(optionalParams));
  }

  warn(message: any, ...optionalParams: any[]) {
    winstonLogger.warn(this.stringify(message), ...this.context(optionalParams));
  }

  debug(message: any, ...optionalParams: any[]) {
    winstonLogger.debug(this.stringify(message), ...this.context(optionalParams));
  }

  verbose(message: any, ...optionalParams: any[]) {
    winstonLogger.verbose(this.stringify(message), ...this.context(optionalParams));
  }

  private stringify(message: any): string {
    return typeof message === 'string' ? message : JSON.stringify(message);
  }

  // Nest passes a trailing "context" string (e.g. controller name) after the
  // message; keep it as structured meta rather than string-concatenating it.
  private context(optionalParams: any[]): any[] {
    if (optionalParams.length === 0) return [];
    return [{ context: optionalParams }];
  }
}
