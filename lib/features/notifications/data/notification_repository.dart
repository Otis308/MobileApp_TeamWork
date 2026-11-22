import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import 'models/notification_model.dart';

class NotificationRepository {
  final Dio _dio = ApiClient().dio;

  // GET /notifications
  Future<List<NotificationModel>> getMyNotifications() async {
    try {
      final res = await _dio.get('/notifications');
      return (res.data as List)
          .map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi lấy thông báo');
    }
  }

  // GET /notifications/unread-count
  Future<int> getUnreadCount() async {
    try {
      final res = await _dio.get('/notifications/unread-count');
      // Server trả số thuần (text/html) nên res.data có thể là String.
      return res.data is int ? res.data as int : int.tryParse('${res.data}'.trim()) ?? 0;
    } on DioException catch (_) {
      return 0;
    }
  }

  // PATCH /notifications/read-all
  Future<void> markAllRead() async {
    try {
      await _dio.patch('/notifications/read-all');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi đánh dấu đã đọc');
    }
  }

  // PATCH /notifications/:id/read
  Future<void> markOneRead(String id) async {
    try {
      await _dio.patch('/notifications/$id/read');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi đánh dấu đã đọc');
    }
  }
}
