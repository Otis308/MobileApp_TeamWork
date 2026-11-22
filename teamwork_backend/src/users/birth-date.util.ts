// Ngày hợp lệ (loại 2024-02-31) và không ở tương lai.
export function isValidBirthDate(value: string, now = new Date()): boolean {
  const d = new Date(`${value}T00:00:00.000Z`);
  if (Number.isNaN(d.getTime()) || d.toISOString().slice(0, 10) !== value) return false;
  return d.getTime() <= now.getTime();
}
