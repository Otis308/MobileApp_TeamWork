# TeamWork Backend

NestJS + MongoDB (Mongoose) + Socket.IO cho ứng dụng TeamWork (Flutter).

## Chạy

```bash
cp .env.example .env   # điền JWT_SECRET, EMAIL_USER, EMAIL_PASS
npm install --legacy-peer-deps
npm run start:dev
```

Kiểm tra: `GET /health`.

## Quyết định thiết kế

- **Project == Workspace.** Không có thực thể Workspace riêng; một `Project` vừa là
  không gian làm việc vừa là đơn vị nhóm/phân quyền. Đây là đơn giản hoá có chủ đích.
- **Vai trò theo dự án:** `Admin` / `Manager` / `Member` lưu ở `ProjectMember.role`.
  Chủ dự án (`ownerId`) luôn là Admin ngầm định. Logic kiểm tra quyền nằm tập trung
  trong `src/common/project-access/project-access.service.ts`; route dùng `@Roles(...)`
  cùng `RolesGuard`.
- **Mời thành viên:** thêm ngay theo email (chưa có bước chờ chấp nhận).
- **JWT:** `JwtStrategy` tra DB mỗi request nên token của user đã bị xoá bị từ chối (401).

## Socket.IO

Phòng: `user_<userId>` (tự join khi kết nối với JWT) và `project_<projectId>`
(client gửi `join_project`, server kiểm tra thành viên).

## Task API

- `PATCH /tasks/:id/move` nhận `{ status, targetIndex? }`; server tính lại `order` 0..n-1
  cho cột đích (và cột nguồn). Không dùng transaction nên còn cửa sổ race nhỏ.
- `GET /tasks/project/:id` nhận `assigneeId`, `priority`, `dueAfter`, `dueBefore`, `overdue=true`.
  Mỗi task trả kèm `isOverdue` (tính khi truy vấn, không lưu DB): chưa `done` và ngày hạn
  (00:00 UTC) đã trôi qua hết.

## Real-time

- `presence` `{projectId, userId, online}`: chỉ báo offline khi user không còn socket nào trong phòng.
- `presence_snapshot` `{projectId, userIds}`: gửi riêng cho client vừa `join_project`.
- `task_moved` kèm `orders` (thứ tự id của các cột bị ảnh hưởng).
