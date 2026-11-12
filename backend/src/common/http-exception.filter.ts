import { ArgumentsHost, Catch, ExceptionFilter, HttpException, HttpStatus, Logger } from '@nestjs/common';
import type { Response } from 'express';

/**
 * Every error leaves the API as `{ "statusCode": 400, "message": "user-facing text" }`.
 * The Flutter app shows `message` as-is, so it must always be a single readable sentence.
 */
@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger('HTTP');

  catch(exception: unknown, host: ArgumentsHost) {
    const res = host.switchToHttp().getResponse<Response>();

    if (exception instanceof HttpException) {
      const status = exception.getStatus();
      const body = exception.getResponse();
      let message: string = exception.message;
      if (typeof body === 'object' && body !== null && 'message' in body) {
        const raw = (body as { message: unknown }).message;
        message = Array.isArray(raw) ? String(raw[0]) : String(raw);
        // Nested validation errors arrive as "items.0.Choose a quantity…" — keep only the sentence.
        message = message.replace(/^[\w]+(\.[\w]+)*\.(?=[A-Z])/, '');
      } else if (typeof body === 'string') {
        message = body;
      }
      if (/in JSON at position|Unexpected token|JSON/.test(message) && status === HttpStatus.BAD_REQUEST) {
        message = 'The request could not be read.';
      }
      if (status === HttpStatus.NOT_FOUND && message.startsWith('Cannot ')) {
        message = 'This endpoint does not exist.';
      }
      if (status === HttpStatus.TOO_MANY_REQUESTS) {
        message = 'Too many attempts. Please wait a minute and try again.';
      }
      res.status(status).json({ statusCode: status, message });
      return;
    }

    // Body-parser errors (malformed JSON) carry a status but are not HttpExceptions.
    const maybeStatus = (exception as { status?: number })?.status;
    if (typeof maybeStatus === 'number' && maybeStatus >= 400 && maybeStatus < 500) {
      res.status(maybeStatus).json({ statusCode: maybeStatus, message: 'The request could not be read.' });
      return;
    }

    this.logger.error(exception instanceof Error ? exception.stack : String(exception));
    res
      .status(HttpStatus.INTERNAL_SERVER_ERROR)
      .json({ statusCode: 500, message: 'Something went wrong on our side. Please try again.' });
  }
}
