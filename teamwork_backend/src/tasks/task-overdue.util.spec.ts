import { isOverdue, overdueCutoff } from './task-overdue.util';

const day = (iso: string) => new Date(iso);

describe('isOverdue', () => {
  const now = day('2026-11-13T10:00:00Z');

  it('hạn hôm nay chưa quá hạn', () => {
    expect(isOverdue('todo', day('2026-11-13T00:00:00Z'), now)).toBe(false);
  });

  it('hạn hôm qua đã quá hạn', () => {
    expect(isOverdue('todo', day('2026-11-12T00:00:00Z'), now)).toBe(true);
    expect(isOverdue('doing', day('2026-11-01T00:00:00Z'), now)).toBe(true);
  });

  it('task có giờ: quá hạn ngay khi qua giờ hạn', () => {
    expect(isOverdue('todo', day('2026-11-13T09:59:00Z'), now, true)).toBe(true);
    expect(isOverdue('todo', day('2026-11-13T10:01:00Z'), now, true)).toBe(false);
    // cùng mốc đó nhưng không có giờ thì vẫn còn hạn (tính cả ngày)
    expect(isOverdue('todo', day('2026-11-13T09:59:00Z'), now, false)).toBe(false);
  });

  it('đã done thì không bao giờ quá hạn', () => {
    expect(isOverdue('done', day('2026-01-01T00:00:00Z'), now)).toBe(false);
  });

  it('không có hạn thì không quá hạn', () => {
    expect(isOverdue('todo', undefined, now)).toBe(false);
    expect(isOverdue('todo', null, now)).toBe(false);
  });

  it('khớp với overdueCutoff dùng cho truy vấn', () => {
    const cutoff = overdueCutoff(now);
    expect(day('2026-11-12T00:00:00Z').getTime() <= cutoff.getTime()).toBe(true);
    expect(day('2026-11-13T00:00:00Z').getTime() <= cutoff.getTime()).toBe(false);
  });

  it('múi giờ Việt Nam: quá hạn đúng lúc 0h hôm sau theo giờ VN (UTC+7), không phải theo UTC', () => {
    const dueToday = day('2026-11-13T00:00:00Z'); // hạn ngày 13/11 (giờ VN)
    // 2026-11-13T17:00:00Z = 2026-11-14 00:00 giờ VN → vừa sang ngày mới ở VN → phải quá hạn
    expect(isOverdue('todo', dueToday, day('2026-11-13T17:00:00Z'))).toBe(true);
    // 1 phút trước mốc đó vẫn còn trong ngày 13/11 giờ VN → chưa quá hạn
    expect(isOverdue('todo', dueToday, day('2026-11-13T16:59:00Z'))).toBe(false);
  });
});
