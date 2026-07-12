// Fails app startup fast when required secrets are missing/weak, instead of
// silently falling back to a hardcoded default (which would let anyone forge
// valid JWTs against a well-known secret).
export function validateEnv(config: Record<string, unknown>): Record<string, unknown> {
  const required = ['JWT_ACCESS_SECRET', 'DATABASE_URL'];
  const missing = required.filter((key) => {
    const value = config[key];
    return value === undefined || value === null || String(value).trim() === '';
  });

  if (missing.length > 0) {
    throw new Error(`Missing required environment variable(s): ${missing.join(', ')}`);
  }

  const jwtSecret = String(config['JWT_ACCESS_SECRET']);
  if (jwtSecret.length < 32) {
    throw new Error('JWT_ACCESS_SECRET must be at least 32 characters long');
  }

  return config;
}
