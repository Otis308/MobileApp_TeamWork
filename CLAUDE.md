# CLAUDE.md — TeamWork

Bản đồ kiến trúc dự án, dùng để định hướng nhanh cho các phiên làm việc sau. Đọc file này trước khi sửa code.

## Tổng quan

Mono-repo gồm 2 phần độc lập:

- **Mobile client** (root `/lib`): Flutter app, tên package `teamwork`.
- **Backend** (`teamwork_backend/`): NestJS + MongoDB (Mongoose) + Socket.IO.
- `test/e2e/`: bộ test e2e riêng (Jest) gọi thẳng vào API, không phụ thuộc Flutter.
- `.andromity/`: cấu hình cron nội bộ, không phải mã nguồn app.

Ứng dụng quản lý công việc nhóm: đăng ký/đăng nhập, tạo dự án, mời thành viên theo vai trò (Admin/Manager/Member), bảng Kanban (todo/doing/done) với kéo-thả, deadline, thông báo real-time qua WebSocket, timeline, profile + avatar.

## Backend (`teamwork_backend/`)

Tech stack: NestJS 12, Mongoose 9 (MongoDB), `@nestjs/jwt` + Passport JWT, Socket.IO (`@nestjs/websockets`, `@nestjs/platform-socket.io`), Nodemailer (Gmail) cho email, Multer cho upload avatar. Test: Jest (unit `*.spec.ts` cạnh file nguồn, e2e trong `test/`). Lint: oxlint.

Entry point: [src/main.ts](teamwork_backend/src/main.ts) — bật `ValidationPipe({whitelist: true, transform: true})`, CORS mở (`origin: true`), phục vụ file tĩnh `/uploads` (avatar).

Cấu hình qua `.env` ([.env.example](teamwork_backend/.env.example)): `MONGODB_URI`, `PORT`, `JWT_SECRET`, `EMAIL_USER`/`EMAIL_PASS` (Gmail app password). Validate bằng [src/config/env.validation.ts](teamwork_backend/src/config/env.validation.ts).

### Module theo tính năng ([src/app.module.ts](teamwork_backend/src/app.module.ts))
- `AuthModule` — đăng ký/đăng nhập (bcrypt + JWT), quên mật khẩu qua OTP email (hết hạn 60 giây, giới hạn gửi lại 60 giây/lần). Trả `otp_demo` trong response khi `NODE_ENV !== production` (chỉ cho dev).
- `ProjectsModule` — CRUD dự án, quản lý thành viên + vai trò.
- `TasksModule` — CRUD task, kéo-thả đổi cột/thứ tự ([task-order.util.ts](teamwork_backend/src/tasks/task-order.util.ts)), tính overdue ([task-overdue.util.ts](teamwork_backend/src/tasks/task-overdue.util.ts)).
- `UsersModule` — hồ sơ cá nhân, avatar (lưu `uploads/avatars/`, tên file random UUID để tránh path traversal/ghi đè), permissions (camera/contacts/messages — cờ phía client, backend chỉ lưu).
- `NotificationsModule` — thông báo trong app (task_assigned, task_comment, member_added, system), đánh dấu đã đọc.
- `GatewayModule` → [AppGateway](teamwork_backend/src/gateway/app.gateway.ts) — Socket.IO, xác thực bằng JWT trong `handshake.auth.token`, auto-join room `user_<id>`; client tự `join_project`/`leave_project` để vào room `project_<id>` (có kiểm tra quyền thành viên).

### Phân quyền (RBAC)
Nguồn chân lý tập trung ở [ProjectAccessService](teamwork_backend/src/common/project-access/project-access.service.ts):
- `ownerId` của Project luôn là Admin hiệu lực (dù không có `ProjectMember` record).
- 3 vai trò: `Admin` > `Manager` > `Member`.
- `RolesGuard` ([src/common/guards/roles.guard.ts](teamwork_backend/src/common/guards/roles.guard.ts)) đọc metadata `@Roles(...)`, lấy `projectId` từ `:id` hoặc `:projectId` trong route params.
- Một số rule chi tiết (vd "Manager không xoá được Admin/Manager khác") nằm thẳng trong `ProjectsService`, không qua `RolesGuard` — khi sửa quyền, kiểm tra cả hai nơi.

### Real-time
Service nghiệp vụ (`ProjectsService`, `TasksService`) gọi trực tiếp `AppGateway.emitToProject()` / `emitToUser()` sau mỗi thay đổi — không có event bus/queue trung gian. Client Flutter lắng nghe theo tên event cụ thể (`task_created`, `task_updated`, `task_moved`, `task_deleted`, `project_updated`, `member_added`, `notification`, `you_were_added_to_project`, `new_task_assigned`, `presence`...).

## Mobile client (`lib/`)

Tech stack: Flutter, **Riverpod** (`flutter_riverpod` v3, dùng cả API mới `Provider`/`StreamProvider` và API cũ `StateNotifierProvider` qua `flutter_riverpod/legacy`), **go_router** cho điều hướng, **Dio** cho HTTP, **socket_io_client** cho real-time, **flutter_secure_storage** cho token, **freezed**/**json_serializable** cho model (`*.freezed.dart`, `*.g.dart` — sinh tự động, không sửa tay, chạy lại `build_runner` khi đổi model).

Entry point: [lib/main.dart](lib/main.dart) → [lib/teamwork.dart](lib/teamwork.dart).

### Cấu trúc theo feature (`lib/features/<name>/{data,presentation}`)
`auth`, `dashboard`, `notifications`, `profile`, `project`, `task_board` (Kanban), `team`, `timeline`, `work_organization`. Mỗi feature có `data/` (repository gọi Dio trực tiếp tới API) và `presentation/` (Riverpod provider + screen/widget).

### Điều hướng
[lib/app_routes.dart](lib/app_routes.dart) định nghĩa enum `AppScreen` + nhãn tiếng Việt. [lib/core/router/app_router.dart](lib/core/router/app_router.dart) map sang path `go_router` thật và áp dụng `redirect` dựa trên `authStatusProvider` (3 trạng thái: `unknown` → splash, `unauthenticated` → `/login`, `authenticated` → không cho ở lại splash/login).

### Tầng network & session
- [ApiClient](lib/core/network/api_client.dart) — singleton Dio, interceptor tự gắn `Authorization: Bearer <token>`, tự `clearAll()` + gọi `onUnauthorized` khi gặp 401.
- [SessionService](lib/core/services/session_service.dart) — lưu token/userId/projectId trong `flutter_secure_storage`.
- [WebSocketService](lib/core/services/websocket_service.dart) — singleton socket.io, broadcast stream theo tên event qua `events(event)`, đếm ref-count phòng dự án (`joinProject`/`leaveProject`) để không rời phòng khi còn người dùng khác cần.
- [AppConfig](lib/core/config/app_config.dart) — `baseUrl` lấy từ `--dart-define=API_BASE_URL`, mặc định `http://localhost:3000`.

### State management pattern
Các *Controller (vd `AuthController`, `TaskBoardController`) là `StateNotifier`, trả `String?` lỗi (null = thành công) cho các hành động ghi — UI tự hiển thị lỗi, không throw lên widget. `TaskBoardController` áp dụng optimistic update khi kéo-thả (`moveTask`): cập nhật UI ngay, rollback nếu API lỗi; đồng thời lắng nghe socket event để tự `loadTasks(silent: true)` khi có thay đổi real-time từ người khác.

## Điểm cần lưu ý

- **Bảo mật/validate đáng chú ý:**
  - CORS backend đang mở hoàn toàn (`origin: true`) và Socket.IO gateway cũng `origin: '*'` — chấp nhận được cho dev/MVP nhưng cần siết lại nếu lên production thật.
  - `ValidationPipe` chưa bật `forbidNonWhitelisted` (cố ý, để không vỡ client đang gửi field thừa) — field lạ bị âm thầm loại bỏ, không báo lỗi.
  - OTP quên mật khẩu chỉ 6 số, hết hạn sau 60 giây, không giới hạn số lần thử sai (không thấy rate-limit chống brute-force OTP trong `resetPassword`).
  - `AuthService.register`/`login` nhận `body: any` (chưa dùng DTO strict kiểu như Tasks/Projects) — ít type-safety hơn các module khác.
  - Email/App password Gmail (`EMAIL_USER`/`EMAIL_PASS`) lưu plaintext trong `.env`; `.env` đã có sẵn trong repo cùng `.env.example` — cần xác nhận `.env` không bị commit thật (đã có trong `.gitignore`? kiểm tra lại nếu sửa CI).
  - `teamwork_backend/uploads/avatars/` chứa ảnh thật đã upload — không phải thư mục trống, cẩn thận khi dọn dẹp.
- **Kiến trúc:**
  - `moveTask` dùng `bulkWrite` không transaction (cần replica set MongoDB) — chấp nhận race nhỏ cho MVP, đã ghi chú trong code.
  - Business logic gọi gateway trực tiếp (không qua event emitter nội bộ) — thêm tính năng real-time mới nghĩa là sửa thẳng vào Service.
  - `teamwork_backend/AGENTS.md` có hướng dẫn cài đặt NestJS Observe (`npx @nestjs/observe link`) để gửi telemetry production ra dịch vụ ngoài — **đừng tự ý chạy lệnh này**, cần hỏi người dùng trước vì nó ghi API key vào `.env` và gửi dữ liệu ra ngoài.
- **CI/CD:** [.github/workflows/build_apk.yml](.github/workflows/build_apk.yml) build APK, dùng `API_BASE_URL` production qua `--dart-define`; Flutter version bị pin để khớp môi trường local (xem lịch sử commit gần đây).
