import { ArgumentsHost, Catch, ExceptionFilter, HttpException, HttpStatus, Logger } from '@nestjs/common';
import type { Response } from 'express';
import { Prisma } from '@trimly/database';
import { ErrorCode, type ApiError } from '@trimly/types';

interface Resolved {
  status: number;
  error: ApiError;
}

// Normalizes every thrown error (HttpException, Prisma error, or anything
// unexpected) into the app's { success: false, error } contract, and makes
// sure internal details (stack traces, Prisma query info) never reach the
// client — only get logged server-side.
@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  private readonly logger = new Logger('ExceptionFilter');

  catch(exception: unknown, host: ArgumentsHost): void {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<{ method: string; url: string }>();

    console.error("RAW EXCEPTION CAUGHT:", exception);
    
    const { status, error } = this.resolve(exception);

    if (status >= HttpStatus.INTERNAL_SERVER_ERROR) {
      const detail = exception instanceof Error ? exception.stack : String(exception);
      this.logger.error(`${request.method} ${request.url} -> ${status}`, detail);
    }

    response.status(status).json({ success: false, error });
  }

  private resolve(exception: unknown): Resolved {
    if (exception instanceof HttpException) {
      return { status: exception.getStatus(), error: this.fromHttpException(exception) };
    }

    if (exception instanceof Prisma.PrismaClientKnownRequestError) {
      return this.fromPrismaError(exception);
    }

    return {
      status: HttpStatus.INTERNAL_SERVER_ERROR,
      error: { code: ErrorCode.INTERNAL_ERROR, message: 'Something went wrong. Please try again later.' },
    };
  }

  private fromHttpException(exception: HttpException): ApiError {
    const status = exception.getStatus();
    const body = exception.getResponse();

    // class-validator's ValidationPipe throws a BadRequestException whose
    // response body is { message: string[], ... } — surface those as
    // per-field-ish validation details instead of one generic message.
    if (typeof body === 'object' && body !== null && Array.isArray((body as any).message)) {
      return {
        code: ErrorCode.VALIDATION_FAILED,
        message: 'Request validation failed',
        fields: { _: (body as any).message },
      };
    }

    const message =
      typeof body === 'string' ? body : (body as any)?.message || exception.message || 'Request failed';

    return { code: this.codeForStatus(status), message };
  }

  private codeForStatus(status: number): string {
    switch (status) {
      case HttpStatus.UNAUTHORIZED:
        return ErrorCode.UNAUTHORIZED;
      case HttpStatus.FORBIDDEN:
        return ErrorCode.FORBIDDEN;
      case HttpStatus.NOT_FOUND:
        return ErrorCode.NOT_FOUND;
      case HttpStatus.CONFLICT:
        return ErrorCode.CONFLICT;
      case HttpStatus.TOO_MANY_REQUESTS:
        return ErrorCode.RATE_LIMITED;
      case HttpStatus.BAD_REQUEST:
        return ErrorCode.VALIDATION_FAILED;
      case HttpStatus.SERVICE_UNAVAILABLE:
        return ErrorCode.SERVICE_UNAVAILABLE;
      default:
        return status >= 500 ? ErrorCode.INTERNAL_ERROR : ErrorCode.VALIDATION_FAILED;
    }
  }

  private fromPrismaError(exception: Prisma.PrismaClientKnownRequestError): Resolved {
    switch (exception.code) {
      case 'P2002': // unique constraint violation
        return {
          status: HttpStatus.CONFLICT,
          error: { code: ErrorCode.CONFLICT, message: 'A record with these details already exists.' },
        };
      case 'P2025': // record not found
        return {
          status: HttpStatus.NOT_FOUND,
          error: { code: ErrorCode.NOT_FOUND, message: 'The requested record was not found.' },
        };
      case 'P2003': // foreign key constraint violation
        return {
          status: HttpStatus.BAD_REQUEST,
          error: { code: ErrorCode.VALIDATION_FAILED, message: 'This action references a record that does not exist.' },
        };
      default:
        return {
          status: HttpStatus.INTERNAL_SERVER_ERROR,
          error: { code: ErrorCode.INTERNAL_ERROR, message: 'A database error occurred.' },
        };
    }
  }
}
