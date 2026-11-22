// Đặt `movingId` vào vị trí `targetIndex` của một cột (danh sách id đã sắp theo order).
// targetIndex nằm ngoài khoảng hợp lệ thì được kẹp lại; thiếu thì đặt cuối cột.
export function placeInColumn(
  ids: string[],
  movingId: string,
  targetIndex?: number,
): string[] {
  const rest = ids.filter((id) => id !== movingId);
  const index =
    targetIndex === undefined
      ? rest.length
      : Math.min(Math.max(targetIndex, 0), rest.length);
  rest.splice(index, 0, movingId);
  return rest;
}
