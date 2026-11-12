import { Transform } from 'class-transformer';
import { IsEmail, IsIn, IsNotEmpty, IsString, Length, Matches, MaxLength, MinLength } from 'class-validator';

const trimLower = ({ value }: { value: unknown }) => (typeof value === 'string' ? value.trim().toLowerCase() : value);
const trim = ({ value }: { value: unknown }) => (typeof value === 'string' ? value.trim() : value);

/** Same rule as the app (`Validators.password`): 8+ characters. */
export const PASSWORD_RULE_MESSAGE = 'Use at least 8 characters for your password.';

export class SignInDto {
  @Transform(trimLower)
  @IsEmail({}, { message: 'Enter a valid email address.' })
  email: string;

  @IsString()
  @IsNotEmpty({ message: 'Password is required.' })
  password: string;
}

export class SignUpDto {
  @Transform(trim)
  @IsString()
  @IsNotEmpty({ message: 'First name is required.' })
  @MaxLength(60)
  firstName: string;

  @Transform(trim)
  @IsString()
  @IsNotEmpty({ message: 'Last name is required.' })
  @MaxLength(60)
  lastName: string;

  @Transform(trimLower)
  @IsEmail({}, { message: 'Enter a valid email address.' })
  email: string;

  @IsString()
  @MinLength(8, { message: PASSWORD_RULE_MESSAGE })
  @MaxLength(128)
  password: string;
}

export const PURPOSES = ['signUp', 'resetPassword'] as const;
export type Purpose = (typeof PURPOSES)[number];

export class VerifyCodeDto {
  @Transform(trimLower)
  @IsEmail({}, { message: 'Enter a valid email address.' })
  email: string;

  @Transform(trim)
  @Matches(/^\d{6}$/, { message: 'Enter the 6-digit code.' })
  code: string;

  @IsIn(PURPOSES, { message: 'Unknown verification purpose.' })
  purpose: Purpose;
}

export class ResendCodeDto {
  @Transform(trimLower)
  @IsEmail({}, { message: 'Enter a valid email address.' })
  email: string;

  @IsIn(PURPOSES, { message: 'Unknown verification purpose.' })
  purpose: Purpose;
}

export class EmailDto {
  @Transform(trimLower)
  @IsEmail({}, { message: 'Enter a valid email address.' })
  email: string;
}

export class ResetPasswordDto {
  @IsString()
  @IsNotEmpty()
  resetToken: string;

  @IsString()
  @MinLength(8, { message: PASSWORD_RULE_MESSAGE })
  @MaxLength(128)
  password: string;
}

export class ChangePasswordDto {
  @IsString()
  @IsNotEmpty({ message: 'Enter your current password.' })
  currentPassword: string;

  @IsString()
  @MinLength(8, { message: PASSWORD_RULE_MESSAGE })
  @MaxLength(128)
  newPassword: string;
}

export class RefreshDto {
  @IsString()
  @Length(20, 200)
  refreshToken: string;
}
