class AppConfig {
  // Ghi đè khi build dev: flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
  // Mặc định trỏ thẳng server production — để nếu lỡ build release nào quên
  // truyền --dart-define thì app vẫn gọi đúng server thật, không rơi về localhost
  // (localhost không tồn tại trên điện thoại thật, gây lỗi đăng nhập/đăng ký).
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://mobileappteamwork-production.up.railway.app',
  );

  /// Đường dẫn tương đối từ server (vd /uploads/avatars/x.jpg) → URL đầy đủ.
  static String resolveUrl(String url) {
    if (url.isEmpty || url.startsWith('http')) return url;
    return '$baseUrl${url.startsWith('/') ? '' : '/'}$url';
  }
}
