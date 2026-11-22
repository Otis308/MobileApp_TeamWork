import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import 'models/project_member_model.dart';

class TeamRepository {
  final Dio _dio = ApiClient().dio;

  // GET /projects/:id/members
  Future<List<ProjectMemberModel>> getMembers(String projectId) async {
    try {
      final res = await _dio.get('/projects/$projectId/members');
      return (res.data as List)
          .map((e) => ProjectMemberModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Lỗi lấy danh sách thành viên',
      );
    }
  }

  // GET /projects/:id/members/me/role — vai trò thật do server xác định
  Future<String> getMyRole(String projectId) async {
    try {
      final res = await _dio.get('/projects/$projectId/members/me/role');
      return (res.data as Map)['role'] as String;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi lấy vai trò');
    }
  }

  // POST /projects/:id/members  body: { email }
  Future<void> addMember(String projectId, String email) async {
    try {
      await _dio.post(
        '/projects/$projectId/members',
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi thêm thành viên');
    }
  }

  // DELETE /projects/:id/members/:userId (JWT identity server-side)
  Future<void> removeMember(String projectId, String targetUserId) async {
    try {
      await _dio.delete('/projects/$projectId/members/$targetUserId');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi xóa thành viên');
    }
  }

  // PATCH /projects/:id/members/:userId/role (JWT identity server-side)
  Future<void> updateMemberRole(
    String projectId,
    String targetUserId,
    String newRole,
  ) async {
    try {
      await _dio.patch(
        '/projects/$projectId/members/$targetUserId/role',
        data: {'role': newRole},
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi đổi vai trò');
    }
  }
}
