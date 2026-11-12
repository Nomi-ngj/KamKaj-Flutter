/**
 * Reads and validates environment variables once at start-up.
 * Values come from `.env.staging` / `.env.production` (loaded by dotenv-cli in package.json scripts)
 * or from the hosting platform's environment.
 */
export type AppEnv = 'staging' | 'production' | 'test';

function required(name: string): string {
  const value = process.env[name];
  if (!value || value.trim() === '') {
    throw new Error(`Missing required environment variable ${name}. See .env.example.`);
  }
  return value.trim();
}

function optional(name: string, fallback: string): string {
  const value = process.env[name];
  return value && value.trim() !== '' ? value.trim() : fallback;
}

function readEnv() {
  const appEnv = optional('APP_ENV', 'staging') as AppEnv;
  if (!['staging', 'production', 'test'].includes(appEnv)) {
    throw new Error(`APP_ENV must be staging, production or test (got "${appEnv}")`);
  }
  const isProduction = appEnv === 'production';

  const accessSecret = required('JWT_ACCESS_SECRET');
  const refreshSecret = required('JWT_REFRESH_SECRET');
  if (isProduction && (accessSecret.length < 32 || accessSecret.includes('change-me'))) {
    throw new Error('JWT_ACCESS_SECRET must be a long random value in production.');
  }

  const fixedOtp = process.env.FIXED_OTP?.trim() || null;
  if (isProduction && fixedOtp) {
    throw new Error('FIXED_OTP must not be set in production.');
  }

  return {
    appEnv,
    isProduction,
    port: Number(optional('PORT', '3000')),
    databaseUrl: required('DATABASE_URL'),
    jwt: {
      accessSecret,
      refreshSecret,
      accessTtl: optional('JWT_ACCESS_TTL', '15m'),
      refreshTtlDays: Number(optional('REFRESH_TOKEN_TTL_DAYS', '30')),
    },
    /** Staging only: every verification code equals this value. */
    fixedOtp,
    corsOrigins: optional('CORS_ORIGINS', '')
      .split(',')
      .map((o) => o.trim())
      .filter(Boolean),
    publicBaseUrl: optional('PUBLIC_BASE_URL', `http://localhost:${optional('PORT', '3000')}`).replace(/\/$/, ''),
    swaggerEnabled: optional('SWAGGER_ENABLED', isProduction ? 'false' : 'true') === 'true',
    uploadDir: optional('UPLOAD_DIR', 'uploads'),
  };
}

export type Env = ReturnType<typeof readEnv>;

let cached: Env | null = null;

export function env(): Env {
  cached ??= readEnv();
  return cached;
}
