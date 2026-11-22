import { isValidBirthDate } from './birth-date.util';

describe('isValidBirthDate', () => {
  const now = new Date('2026-11-09T00:00:00Z');
  it('chấp nhận ngày hợp lệ trong quá khứ', () => {
    expect(isValidBirthDate('2000-02-29', now)).toBe(true);
  });
  it('từ chối ngày không tồn tại', () => {
    expect(isValidBirthDate('2001-02-29', now)).toBe(false);
    expect(isValidBirthDate('2024-13-01', now)).toBe(false);
  });
  it('từ chối ngày ở tương lai', () => {
    expect(isValidBirthDate('2030-01-01', now)).toBe(false);
  });
});
