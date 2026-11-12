import { Body, Controller, Get, Headers, HttpCode, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { IsOptional, IsString } from 'class-validator';
import { AuthUser, CurrentUser, Public } from '../../common/auth';
import {
  ChangePasswordDto,
  EmailDto,
  RefreshDto,
  ResendCodeDto,
  ResetPasswordDto,
  SignInDto,
  SignUpDto,
  VerifyCodeDto,
} from './auth.dto';
import { AuthService } from './auth.service';

class SignOutDto {
  @IsOptional()
  @IsString()
  refreshToken?: string;
}

/** Strict limit for endpoints that can be brute-forced. */
const AUTH_LIMIT = { default: { limit: 10, ttl: 60_000 } };

@ApiTags('Auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Public()
  @Throttle(AUTH_LIMIT)
  @Post('sign-in')
  @HttpCode(200)
  signIn(@Body() dto: SignInDto, @Headers('user-agent') ua?: string) {
    return this.auth.signIn(dto.email, dto.password, ua);
  }

  @Public()
  @Throttle(AUTH_LIMIT)
  @Post('sign-up')
  @HttpCode(204)
  async signUp(@Body() dto: SignUpDto) {
    await this.auth.signUp(dto);
  }

  @Public()
  @Throttle(AUTH_LIMIT)
  @Post('verify-code')
  @HttpCode(200)
  verifyCode(@Body() dto: VerifyCodeDto, @Headers('user-agent') ua?: string) {
    return this.auth.verifyCode(dto.email, dto.code, dto.purpose, ua);
  }

  @Public()
  @Throttle(AUTH_LIMIT)
  @Post('resend-code')
  @HttpCode(204)
  async resendCode(@Body() dto: ResendCodeDto) {
    await this.auth.resendCode(dto.email, dto.purpose);
  }

  @Public()
  @Throttle(AUTH_LIMIT)
  @Post('forgot-password')
  @HttpCode(204)
  async forgotPassword(@Body() dto: EmailDto) {
    await this.auth.forgotPassword(dto.email);
  }

  @Public()
  @Throttle(AUTH_LIMIT)
  @Post('reset-password')
  @HttpCode(204)
  async resetPassword(@Body() dto: ResetPasswordDto) {
    await this.auth.resetPassword(dto.resetToken, dto.password);
  }

  @ApiBearerAuth()
  @Throttle(AUTH_LIMIT)
  @Post('change-password')
  @HttpCode(204)
  async changePassword(@CurrentUser() user: AuthUser, @Body() dto: ChangePasswordDto) {
    await this.auth.changePassword(user.id, dto.currentPassword, dto.newPassword);
  }

  @Public()
  @Post('refresh')
  @HttpCode(200)
  refresh(@Body() dto: RefreshDto, @Headers('user-agent') ua?: string) {
    return this.auth.refresh(dto.refreshToken, ua);
  }

  @ApiBearerAuth()
  @Post('sign-out')
  @HttpCode(204)
  async signOut(@CurrentUser() user: AuthUser, @Body() dto: SignOutDto) {
    await this.auth.signOut(user.id, dto?.refreshToken);
  }
}

@ApiTags('Users')
@ApiBearerAuth()
@Controller('users')
export class UsersController {
  constructor(private readonly auth: AuthService) {}

  @Get('me')
  me(@CurrentUser() user: AuthUser) {
    return this.auth.me(user.id);
  }
}
