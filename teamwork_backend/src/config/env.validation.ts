// Fail fast khi thiếu biến bắt buộc, thay vì chạy với giá trị mặc định âm thầm.
export function validateEnv(config: Record<string, unknown>) {
  const jwtSecret = config.JWT_SECRET;
  if (typeof jwtSecret !== 'string' || jwtSecret.trim() === '') {
    throw new Error('Thiếu biến môi trường bắt buộc: JWT_SECRET');
  }
  return config;
}
