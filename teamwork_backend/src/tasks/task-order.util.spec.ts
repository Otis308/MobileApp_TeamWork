import { placeInColumn } from './task-order.util';

describe('placeInColumn', () => {
  it('chèn vào giữa cột', () => {
    expect(placeInColumn(['a', 'b', 'c'], 'x', 1)).toEqual(['a', 'x', 'b', 'c']);
  });

  it('thiếu targetIndex thì đặt cuối cột', () => {
    expect(placeInColumn(['a', 'b'], 'x')).toEqual(['a', 'b', 'x']);
  });

  it('cột rỗng', () => {
    expect(placeInColumn([], 'x', 0)).toEqual(['x']);
  });

  it('kẹp targetIndex vượt biên', () => {
    expect(placeInColumn(['a', 'b'], 'x', 99)).toEqual(['a', 'b', 'x']);
    expect(placeInColumn(['a', 'b'], 'x', -5)).toEqual(['x', 'a', 'b']);
  });

  it('di chuyển trong cùng cột không nhân đôi task', () => {
    expect(placeInColumn(['a', 'b', 'c'], 'a', 2)).toEqual(['b', 'c', 'a']);
    expect(placeInColumn(['a', 'b', 'c'], 'c', 0)).toEqual(['c', 'a', 'b']);
  });
});
