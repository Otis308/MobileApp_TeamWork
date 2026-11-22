import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';

class ProfileRepository {
  final Dio _dio = ApiClient().dio;

  String _message(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) return data['message'].toString();
    return fallback;
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final res = await _dio.get('/users/me');
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      throw Exception(_message(e, 'Lỗi lấy profile'));
    }
  }

  /// Trường nào null thì không gửi; chuỗi rỗng nghĩa là xóa giá trị đó.
  Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? username,
    String? phone,
    String? birthDate,
    String? gender,
    String? avatarUrl,
  }) async {
    final body = <String, dynamic>{
      'fullName': ?fullName,
      'username': ?username,
      'phone': ?phone,
      'birthDate': ?birthDate,
      'gender': ?gender,
      'avatarUrl': ?avatarUrl,
    };

    try {
      final res = await _dio.patch('/users/me', data: body);
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      throw Exception(_message(e, 'Lỗi cập nhật profile'));
    }
  }

  /// Tải ảnh đại diện lên (đọc bytes nên chạy được cả trên web).
  Future<Map<String, dynamic>> uploadAvatar(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: file.name.isEmpty ? 'avatar.jpg' : file.name,
          contentType: DioMediaType.parse(_mimeOf(file)),
        ),
      });
      final res = await _dio.post(
        '/users/me/avatar',
        data: form,
        options: Options(sendTimeout: const Duration(seconds: 30)),
      );
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      throw Exception(_message(e, 'Không tải được ảnh lên'));
    }
  }

  static String _mimeOf(XFile file) {
    final mime = file.mimeType;
    if (mime != null && mime.startsWith('image/')) return mime;
    final name = file.name.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<Map<String, dynamic>> getPermissions() async {
    try {
      final res = await _dio.get('/users/me/permissions');
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      throw Exception(_message(e, 'Lỗi lấy quyền'));
    }
  }

  Future<void> updatePermissions({
    bool? camera,
    bool? contacts,
    bool? messages,
  }) async {
    final body = <String, dynamic>{
      'camera': ?camera,
      'contacts': ?contacts,
      'messages': ?messages,
    };

    try {
      await _dio.patch('/users/me/permissions', data: body);
    } on DioException catch (e) {
      throw Exception(_message(e, 'Lỗi cập nhật quyền'));
    }
  }
}
