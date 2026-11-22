import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../services/session_service.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late Dio dio;
  final SessionService _session = SessionService();
  static void Function()? onUnauthorized;

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _session.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        // ValidationPipe trả message dạng mảng — gộp thành chuỗi cho UI.
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await _session.clearAll();
            onUnauthorized?.call();
          }
          final data = error.response?.data;
          if (data is Map && data['message'] is List) {
            data['message'] = (data['message'] as List).join('\n');
          }
          return handler.next(error);
        },
      ),
    );
  }
}
