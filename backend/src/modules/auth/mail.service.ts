import { Injectable, Logger } from '@nestjs/common';
import { env } from '../../config/env';

/**
 * Sends transactional email. No provider is connected yet: messages are written to the
 * server log. Plug in Resend / SendGrid / SMTP in `send()` before going live.
 */
@Injectable()
export class MailService {
  private readonly logger = new Logger('Mail');

  async sendVerificationCode(to: string, code: string, purpose: 'signUp' | 'resetPassword') {
    const subject = purpose === 'signUp' ? 'Your KamKaj verification code' : 'Reset your KamKaj password';
    const text = `Your code is ${code}. It expires in 10 minutes. If you did not request this, ignore this email.`;
    await this.send(to, subject, text);
    if (!env().isProduction) {
      this.logger.log(`[${env().appEnv}] ${purpose} code for ${to}: ${code}`);
    }
  }

  private async send(to: string, subject: string, _text: string) {
    // TODO(production): send through your email provider here.
    if (env().isProduction) {
      this.logger.warn(`No email provider configured — "${subject}" to ${to} was not delivered.`);
    }
  }
}
