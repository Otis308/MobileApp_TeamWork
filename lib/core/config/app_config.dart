class AppConfig {
  // Ghi đè khi build: flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  /// Đường dẫn tương đối từ server (vd /uploads/avatars/x.jpg) → URL đầy đủ.
  static String resolveUrl(String url) {
    if (url.isEmpty || url.startsWith('http')) return url;
    return '$baseUrl${url.startsWith('/') ? '' : '/'}$url';
  }
}
