import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import 'models/project_model.dart';

class ProjectRepository {
  final Dio _dio = ApiClient().dio;

  static bool _isSuccess(int? statusCode) =>
      statusCode != null && statusCode >= 200 && statusCode < 300;

  // GET /projects/mine
  Future<List<ProjectModel>> getMyProjects() async {
    try {
      final res = await _dio.get('/projects/mine');
      return (res.data as List)
          .map((e) => ProjectModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi lấy danh sách dự án',
      );
    }
  }

  // POST /projects
  Future<Map<String, dynamic>> createProject(
    String name, {
    String description = '',
  }) async {
    try {
      final res = await _dio.post('/projects', data: {
        'name':        name,
        'description': description,
      });
      // NestJS returns 201 Created for POST by default — that's success.
      if (!_isSuccess(res.statusCode) || res.data is! Map<String, dynamic>) {
        throw Exception('Lỗi tạo dự án');
      }
      return res.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi tạo dự án');
    }
  }

  // PATCH /projects/:id
  Future<void> updateProject(
    String id, {
    String? name,
    String? description,
  }) async {
    final body = <String, dynamic>{};
    if (name        != null) body['name']        = name;
    if (description != null) body['description'] = description;

    try {
      await _dio.patch('/projects/$id', data: body);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi sửa dự án');
    }
  }

  // DELETE /projects/:id
  Future<void> deleteProject(String id) async {
    try {
      await _dio.delete('/projects/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi xóa dự án');
    }
  }
}