import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../data/models/task_model.dart';
import '../data/task_repository.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/services/websocket_service.dart';

final taskRepositoryProvider = Provider((ref) => TaskRepository());

class KanbanTarget {
  final String projectId;
  final String projectName;
  const KanbanTarget({this.projectId = '', this.projectName = 'Dự án'});
}

final kanbanTargetProvider =
    StateProvider<KanbanTarget>((ref) => const KanbanTarget());

const kanbanStatuses = ['todo', 'doing', 'done'];

class TaskFilter {
  final String? assigneeId;
  final String? priority;
  const TaskFilter({this.assigneeId, this.priority});

  bool get isActive => assigneeId != null || priority != null;
}

class TaskBoardState {
  final List<TaskModel> todo;
  final List<TaskModel> doing;
  final List<TaskModel> done;
  final TaskFilter filter;
  final bool isLoading;
  final String? error;

  const TaskBoardState({
    this.todo  = const [],
    this.doing = const [],
    this.done  = const [],
    this.filter = const TaskFilter(),
    this.isLoading = false,
    this.error,
  });

  List<TaskModel> column(String status) => switch (status) {
        'todo'  => todo,
        'doing' => doing,
        _       => done,
      };

  TaskModel? findById(String id) {
    for (final t in [...todo, ...doing, ...done]) {
      if (t.id == id) return t;
    }
    return null;
  }

  TaskBoardState copyWith({
    List<TaskModel>? todo,
    List<TaskModel>? doing,
    List<TaskModel>? done,
    TaskFilter? filter,
    bool? isLoading,
    String? error,
  }) =>
      TaskBoardState(
        todo:  todo  ?? this.todo,
        doing: doing ?? this.doing,
        done:  done  ?? this.done,
        filter: filter ?? this.filter,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );

  TaskBoardState withColumn(String status, List<TaskModel> tasks) =>
      switch (status) {
        'todo'  => copyWith(todo: tasks),
        'doing' => copyWith(doing: tasks),
        _       => copyWith(done: tasks),
      };
}

final taskBoardProvider =
    StateNotifierProvider<TaskBoardController, TaskBoardState>((ref) {
  return TaskBoardController(
    ref.read(taskRepositoryProvider),
    ref.read(webSocketServiceProvider),
  );
});

class TaskBoardController extends StateNotifier<TaskBoardState> {
  final TaskRepository _repo;
  final WebSocketService _ws;
  final List<StreamSubscription<dynamic>> _subs = [];
  String _currentProjectId = '';
  String? _boundProjectId;

  TaskBoardController(this._repo, [WebSocketService? ws])
      : _ws = ws ?? WebSocketService(),
        super(const TaskBoardState());

  static String _msg(Object e) => e.toString().replaceFirst('Exception: ', '');

  // silent = tải lại nền (sự kiện real-time), không hiện spinner làm nháy bảng.
  Future<void> loadTasks(String projectId, {bool silent = false}) async {
    if (projectId.isEmpty) return;

    final switched = _currentProjectId != projectId;
    _currentProjectId = projectId;
    state = state.copyWith(isLoading: !silent || switched, error: null);

    try {
      final data = await _repo.getBoard(
        projectId,
        assigneeId: state.filter.assigneeId,
        priority: state.filter.priority,
      );
      state = state.copyWith(
        todo: data.todo,
        doing: data.doing,
        done: data.done,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _msg(e));
    }

    _bindProject(projectId);
  }

  // Vào phòng dự án và lắng nghe thay đổi; chỉ đăng ký lại khi đổi dự án.
  void _bindProject(String projectId) {
    if (_boundProjectId == projectId) return;
    _unbind();
    _boundProjectId = projectId;
    _ws.joinProject(projectId);
    for (final event in const [
      'task_created', 'task_updated', 'task_moved', 'task_deleted',
    ]) {
      _subs.add(_ws.events(event).listen(
            (_) => loadTasks(projectId, silent: true),
          ));
    }
  }

  void _unbind() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    final old = _boundProjectId;
    if (old != null) _ws.leaveProject(old);
    _boundProjectId = null;
  }

  void leaveRoom() => _unbind();

  @override
  void dispose() {
    _unbind();
    super.dispose();
  }

  Future<void> setFilter(TaskFilter filter) async {
    state = state.copyWith(filter: filter);
    await loadTasks(_currentProjectId, silent: true);
  }

  // Trả về null nếu thành công, hoặc lỗi THẬT nếu thất bại
  Future<String?> createTask({
    required String title,
    String? description,
    String? assigneeId,
    String? dueDate,
    String priority = 'medium',
  }) async {
    if (_currentProjectId.isEmpty) {
      return 'Chưa xác định được dự án — vui lòng mở lại bảng Kanban';
    }
    try {
      await _repo.createTask(
        projectId:   _currentProjectId,
        title:       title,
        description: description,
        assigneeId:  assigneeId,
        dueDate:     dueDate,
        priority:    priority,
      );
      await loadTasks(_currentProjectId, silent: true);
      return null;
    } catch (e) {
      return _msg(e);
    }
  }

  // Kéo thả: cập nhật giao diện ngay, lỗi thì hoàn tác.
  // targetIndex là vị trí trong cột đích TÍNH SAU KHI bỏ task đang kéo ra.
  Future<String?> moveTask(
    String taskId,
    String newStatus,
    int targetIndex,
  ) async {
    final before = state;
    final task = before.findById(taskId);
    if (task == null) return 'Không tìm thấy công việc';

    final source = before.column(task.status).where((t) => t.id != taskId).toList();
    final dest = task.status == newStatus
        ? source
        : before.column(newStatus).toList();
    final index = targetIndex.clamp(0, dest.length);
    dest.insert(index, task.copyWith(status: newStatus));

    var next = before.withColumn(task.status, source);
    next = next.withColumn(newStatus, dest);
    state = next;

    try {
      await _repo.moveTask(taskId, newStatus, targetIndex: targetIndex);
      await loadTasks(_currentProjectId, silent: true);
      return null;
    } catch (e) {
      state = before;
      return _msg(e);
    }
  }

  Future<String?> updateTask(
    String taskId, {
    String? title,
    String? description,
    String? priority,
    String? assigneeId,
    String? dueDate,
    bool dueHasTime = false,
    bool clearAssignee = false,
    bool clearDueDate = false,
  }) async {
    try {
      await _repo.updateTask(
        taskId,
        title: title,
        description: description,
        priority: priority,
        assigneeId: assigneeId,
        dueDate: dueDate,
        dueHasTime: dueHasTime,
        clearAssignee: clearAssignee,
        clearDueDate: clearDueDate,
      );
      await loadTasks(_currentProjectId, silent: true);
      return null;
    } catch (e) {
      return _msg(e);
    }
  }

  Future<String?> updateAssignee(String taskId, String assigneeId) =>
      updateTask(taskId, assigneeId: assigneeId);

  Future<String?> deleteTask(String taskId) async {
    try {
      await _repo.deleteTask(taskId);
      await loadTasks(_currentProjectId, silent: true);
      return null;
    } catch (e) {
      return _msg(e);
    }
  }
}
