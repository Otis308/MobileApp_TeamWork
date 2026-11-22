# TeamWork - Mobile Task Management

Ứng dụng quản lý công việc nhóm dành cho nội bộ team clone về chạy test local và build file APK phát hành trực tiếp qua GitHub Releases.

---

## 1. Khởi động Backend (Local)

Yêu cầu máy đã cài **Node.js** và **MongoDB**.

```bash
cd teamwork_backend
npm install
# Tạo file .env từ template (nếu chưa có)
cp .env.example .env
# Chạy backend ở chế độ dev (mặc định port 3000)
npm run start:dev
```

---

## 2. Chạy ứng dụng Flutter

Tại thư mục gốc của dự án (`teamwork/`), cài đặt package và chạy với biến môi trường `API_BASE_URL` tương ứng thiết bị test:

```bash
flutter pub get
```

### 📱 Android Emulator (Máy ảo Android)
> Máy ảo Android ánh xạ `localhost` của máy tính qua IP `10.0.2.2`:
```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

### 🌐 Trình duyệt Web (Chrome / Edge)
```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000
```

### 📲 Thiết bị Android thật (Cùng mạng Wi-Fi với máy tính)
> Thay `192.168.1.X` bằng địa chỉ IP LAN máy tính của bạn:
```bash
flutter run -d <device_id> --dart-define=API_BASE_URL=http://192.168.1.X:3000
```

---

## 3. Hướng dẫn Build APK Release để phát hành GitHub Releases

Dự án đã cấu hình tự động: nếu **chưa có** `key.properties`, hệ thống sẽ tạm fallback sang debug signing để team vẫn test build được. Khi cần ký release chính thức để up lên GitHub:

### Bước 1: Tạo Keystore
Mở terminal và chạy lệnh `keytool` (có sẵn trong JDK):
```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
*(Ghi nhớ mật khẩu store và key)*

### Bước 2: Tạo file `android/key.properties`
Tạo file `android/key.properties` (file này đã được chặn trong `.gitignore`, không lo lộ mã):
```properties
storePassword=mat_khau_keystore_cua_ban
keyPassword=mat_khau_alias_cua_ban
keyAlias=upload
storeFile=upload-keystore.jks
```

### Bước 3: Build APK Release
Chạy lệnh build APK:
```bash
flutter build apk --release --dart-define=API_BASE_URL=https://api-domain-cua-ban.com
```
File APK hoàn thiện sẽ nằm tại:
`build/app/outputs/flutter-apk/app-release.apk`
Bạn chỉ cần upload file này lên phần **Releases** của repository GitHub!
