export const DAY_MS = 86_400_000;
export const VN_OFFSET_MS = 7 * 60 * 60 * 1000; // UTC+7 — giờ Việt Nam

// Task chỉ có ngày (hasTime=false): dueDate là 00:00 UTC của ngày hạn (ngày lịch VN được mã hoá bằng UTC),
// quá hạn khi đã sang ngày mới THEO GIỜ VIỆT NAM, không phải theo UTC.
// Task có giờ (hasTime=true): dueDate là thời điểm chính xác, quá hạn ngay khi qua thời điểm đó.
export function isOverdue(
  status: string,
  dueDate: Date | null | undefined,
  now: Date = new Date(),
  hasTime = false,
): boolean {
  if (!dueDate || status === 'done') return false;
  const deadline = hasTime
    ? dueDate.getTime()
    : dueDate.getTime() + DAY_MS - VN_OFFSET_MS;
  return deadline <= now.getTime();
}

// Với task chỉ có ngày: dueDate <= cutoff là quá hạn (dùng cho query Mongo).
export function overdueCutoff(now: Date = new Date()): Date {
  return new Date(now.getTime() - DAY_MS + VN_OFFSET_MS);
}
