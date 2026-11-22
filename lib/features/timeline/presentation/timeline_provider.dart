import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/services/websocket_service.dart';
import '../../task_board/data/models/task_model.dart';
import '../data/timeline_repository.dart';

final timelineRepositoryProvider = Provider((ref) => TimelineRepository());

enum TimelineMode { day, overdue }

// Ngày được quy về 00:00 UTC — cùng quy ước với dueDate server lưu.
DateTime dayKey(DateTime d) => DateTime.utc(d.year, d.month, d.day);

DateTime todayKey([DateTime? now]) => dayKey(now ?? DateTime.now());

bool sameDay(DateTime a, DateTime b) => dayKey(a) == dayKey(b);

class TimelineState {
  final DateTime weekStart;
  final DateTime selectedDay;
  final TimelineMode mode;
  final List<TaskModel> weekTasks;
  final List<TaskModel> overdueTasks;
  final bool isLoading;
  final String? error;

  const TimelineState({
    required this.weekStart,
    required this.selectedDay,
    this.mode = TimelineMode.day,
    this.weekTasks = const [],
    this.overdueTasks = const [],
    this.isLoading = false,
    this.error,
  });

  List<DateTime> get days =>
      List.generate(7, (i) => weekStart.add(Duration(days: i)));

  List<TaskModel> get dayTasks => weekTasks
      .where((t) => t.dueDayKey != null && sameDay(t.dueDayKey!, selectedDay))
      .toList();

  bool hasTasksOn(DateTime day) =>
      weekTasks.any((t) => t.dueDayKey != null && sameDay(t.dueDayKey!, day));

  List<TaskModel> get visibleTasks =>
      mode == TimelineMode.overdue ? overdueTasks : dayTasks;

  TimelineState copyWith({
    DateTime? weekStart,
    DateTime? selectedDay,
    TimelineMode? mode,
    List<TaskModel>? weekTasks,
    List<TaskModel>? overdueTasks,
    bool? isLoading,
    String? error,
  }) =>
      TimelineState(
        weekStart: weekStart ?? this.weekStart,
        selectedDay: selectedDay ?? this.selectedDay,
        mode: mode ?? this.mode,
        weekTasks: weekTasks ?? this.weekTasks,
        overdueTasks: overdueTasks ?? this.overdueTasks,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

final timelineProvider =
    StateNotifierProvider<TimelineController, TimelineState>((ref) {
  return TimelineController(
    ref.read(timelineRepositoryProvider),
    ref.read(webSocketServiceProvider),
  );
});

class TimelineController extends StateNotifier<TimelineState> {
  final TimelineRepository _repo;
  final WebSocketService _ws;
  final DateTime Function() _clock;
  final List<StreamSubscription<dynamic>> _subs = [];
  String _projectId = '';

  TimelineController(this._repo, this._ws, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now,
        super(TimelineState(
          weekStart: todayKey((clock ?? DateTime.now)()),
          selectedDay: todayKey((clock ?? DateTime.now)()),
        ));

  static String _msg(Object e) => e.toString().replaceFirst('Exception: ', '');

  Future<void> setProject(String projectId) async {
    if (projectId == _projectId) return;
    _unbind();
    _projectId = projectId;
    if (projectId.isEmpty) {
      state = state.copyWith(weekTasks: const [], overdueTasks: const [], error: null);
      return;
    }
    _bind(projectId);
    await refresh();
  }

  void _bind(String projectId) {
    _ws.joinProject(projectId);
    for (final event in const [
      'task_created', 'task_updated', 'task_moved', 'task_deleted',
    ]) {
      _subs.add(_ws.events(event).listen((_) => refresh(silent: true)));
    }
  }

  void _unbind() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    if (_projectId.isNotEmpty) _ws.leaveProject(_projectId);
  }

  Future<void> refresh({bool silent = false}) async {
    if (_projectId.isEmpty) return;
    final projectId = _projectId;
    final from = state.weekStart;
    if (!silent) state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        _repo.dueBetween(projectId, from, from.add(const Duration(days: 7))),
        _repo.overdue(projectId),
      ]);
      // Bỏ kết quả cũ nếu người dùng đã đổi dự án/tuần trong lúc chờ.
      if (projectId != _projectId || from != state.weekStart) return;
      state = state.copyWith(
        weekTasks: results[0],
        overdueTasks: results[1],
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _msg(e));
    }
  }

  void selectDay(DateTime day) {
    state = state.copyWith(selectedDay: dayKey(day), mode: TimelineMode.day);
  }

  void setMode(TimelineMode mode) => state = state.copyWith(mode: mode);

  Future<void> shiftWeek(int weeks) async {
    final start = state.weekStart.add(Duration(days: 7 * weeks));
    state = state.copyWith(weekStart: start, selectedDay: start, mode: TimelineMode.day);
    await refresh();
  }

  Future<void> goToToday() async {
    final today = todayKey(_clock());
    state = state.copyWith(weekStart: today, selectedDay: today, mode: TimelineMode.day);
    await refresh();
  }

  @override
  void dispose() {
    _unbind();
    super.dispose();
  }
}
