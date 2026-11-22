import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import 'models/task_model.dart';

class TaskRepository {
  final Dio _dio = ApiClient().dio;

  // GET /tasks/project/:projectId — trả về { todo, doing, done }
  Future<Map<String, dynamic>> getProjectTasks(String projectId) async {
    try {
      final res = await _dio.get('/tasks/project/$projectId');
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi lấy công việc');
    }
  }

  // GET /tasks/project/:projectId với bộ lọc phía server — dùng cho bảng Kanban.
  Future<({List<TaskModel> todo, List<TaskModel> doing, List<TaskModel> done})>
      getBoard(
    String projectId, {
    String? assigneeId,
    String? priority,
    DateTime? dueAfter,
    DateTime? dueBefore,
    bool overdue = false,
  }) async {
    try {
      final res = await _dio.get(
        '/tasks/project/$projectId',
        queryParameters: {
          'assigneeId': ?assigneeId,
          'priority': ?priority,
          'dueAfter': ?dueAfter?.toUtc().toIso8601String(),
          'dueBefore': ?dueBefore?.toUtc().toIso8601String(),
          if (overdue) 'overdue': 'true',
        },
      );
      final data = Map<String, dynamic>.from(res.data);
      List<TaskModel> parse(String key) => (data[key] as List? ?? [])
          .map((e) => TaskModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      return (todo: parse('todo'), doing: parse('doing'), done: parse('done'));
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi lấy công việc');
    }
  }

  // GET /tasks/project/:projectId/progress
  Future<Map<String, dynamic>> getProgress(String projectId) async {
    try {
      final res = await _dio.get('/tasks/project/$projectId/progress');
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi lấy tiến độ');
    }
  }

  // POST /tasks
  Future<Map<String, dynamic>> createTask({
    required String projectId,
    required String title,
    String? description,
    String? assigneeId,
    String? dueDate,
    bool dueHasTime = false,
    String priority = 'medium',
  }) async {
    try {
      final res = await _dio.post('/tasks', data: {
        'projectId':   projectId.trim(),
        'title':       title.trim(),
        'description': description?.trim() ?? '',
        if (assigneeId?.trim().isNotEmpty ?? false)
          'assigneeId': assigneeId!.trim(),
        if (dueDate?.isNotEmpty ?? false) ...{
          'dueDate': dueDate!.trim(),
          'dueHasTime': dueHasTime,
        },
        'priority':    priority,
      });
      if (res.statusCode == null ||
          res.statusCode! < 200 ||
          res.statusCode! >= 300) {
        throw Exception('Lỗi tạo công việc');
      }
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi tạo công việc');
    }
  }

  // PATCH /tasks/:id
  Future<void> updateTask(
    String taskId, {
    String? title,
    String? description,
    String? status,
    String? assigneeId,
    String? dueDate,
    bool dueHasTime = false,
    String? priority,
    bool clearAssignee = false,
    bool clearDueDate = false,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title.trim();
    if (description != null) body['description'] = description.trim();
    if (status != null) body['status'] = status;
    if (assigneeId?.trim().isNotEmpty ?? false) {
      body['assigneeId'] = assigneeId!.trim();
    }
    if (dueDate?.trim().isNotEmpty ?? false) {
      body['dueDate'] = dueDate!.trim();
      body['dueHasTime'] = dueHasTime;
    }
    if (priority != null) body['priority'] = priority;
    if (clearAssignee) body['assigneeId'] = null;
    if (clearDueDate) body['dueDate'] = null;

    try {
      await _dio.patch('/tasks/$taskId', data: body);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi cập nhật');
    }
  }

  // PATCH /tasks/:id/move — kéo thả; targetIndex = vị trí trong cột đích
  Future<void> moveTask(String taskId, String status, {int? targetIndex}) async {
    final body = <String, dynamic>{'status': status};
    if (targetIndex != null) body['targetIndex'] = targetIndex;

    try {
      await _dio.patch('/tasks/$taskId/move', data: body);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi di chuyển');
    }
  }

  // DELETE /tasks/:id
  Future<void> deleteTask(String taskId) async {
    try {
      await _dio.delete('/tasks/$taskId');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi xóa');
    }
  }
}