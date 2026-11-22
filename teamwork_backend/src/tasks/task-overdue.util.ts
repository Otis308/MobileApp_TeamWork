export const DAY_MS = 86_400_000;

// Task chỉ có ngày (hasTime=false): dueDate là 00:00 UTC của ngày hạn, quá hạn khi cả ngày đó đã trôi qua.
// Task có giờ (hasTime=true): dueDate là thời điểm chính xác, quá hạn ngay khi qua thời điểm đó.
export function isOverdue(
  status: string,
  dueDate: Date | null | undefined,
  now: Date = new Date(),
  hasTime = false,
): boolean {
  if (!dueDate || status === 'done') return false;
  const deadline = hasTime ? dueDate.getTime() : dueDate.getTime() + DAY_MS;
  return deadline <= now.getTime();
}

// Với task chỉ có ngày: dueDate <= cutoff là quá hạn.
export function overdueCutoff(now: Date = new Date()): Date {
  return new Date(now.getTime() - DAY_MS);
}
