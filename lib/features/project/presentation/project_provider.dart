import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../data/models/project_model.dart';
import '../data/project_repository.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/services/session_service.dart';
import '../../../core/services/websocket_service.dart';

final projectRepositoryProvider = Provider((ref) => ProjectRepository());

class ProjectState {
  final List<ProjectModel> projects;
  final ProjectModel? selected;
  final bool isLoading;
  final String? error;

  const ProjectState({
    this.projects  = const [],
    this.selected,
    this.isLoading = false,
    this.error,
  });

  ProjectState copyWith({
    List<ProjectModel>? projects,
    ProjectModel? selected,
    bool clearSelected = false,
    bool? isLoading,
    String? error,
  }) =>
      ProjectState(
        projects:  projects  ?? this.projects,
        selected:  clearSelected ? null : (selected ?? this.selected),
        isLoading: isLoading ?? this.isLoading,
        error:     error,
      );
}

final projectProvider =
    StateNotifierProvider<ProjectController, ProjectState>((ref) {
  return ProjectController(
    ref.read(projectRepositoryProvider),
    ref.read(webSocketServiceProvider),
  );
});

class ProjectController extends StateNotifier<ProjectState> {
  final ProjectRepository _repo;
  final _session = SessionService();
  final WebSocketService _ws;
  final List<StreamSubscription<dynamic>> _subs = [];

  ProjectController(this._repo, this._ws) : super(const ProjectState()) {
    Future.microtask(() {
      loadProjects();
      _attachRealtimeListener();
    });
  }

  // Real-time: project list refreshes when a project is created, updated,
  // deleted, or when membership changes (member added/removed/role changed).
  void _attachRealtimeListener() {
    if (_subs.isNotEmpty) return;
    for (final event in const [
      'project_list_changed', 'project_updated', 'project_deleted',
    ]) {
      _subs.add(_ws.events(event).listen((_) => loadProjects()));
    }
    _subs.add(_ws.statusStream
        .where((s) => s == SocketStatus.connected)
        .listen((_) => loadProjects()));
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  Future<void> loadProjects() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final projects = await _repo.getMyProjects();
      state = state.copyWith(projects: projects, isLoading: false);

      final savedId = await _session.getProjectId();
      if (savedId != null) {
        final found = projects.where((p) => p.id == savedId).firstOrNull ??
            projects.firstOrNull;
        if (found != null) {
          await selectProject(found);
        } else {
          // Dự án đã lưu không còn tồn tại (có thể đã bị xóa) → bỏ chọn
          await _session.saveProjectId('');
          state = state.copyWith(clearSelected: true);
        }
      } else if (projects.isNotEmpty) {
        await selectProject(projects.first);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> selectProject(ProjectModel project) async {
    await _session.saveProjectId(project.id);
    state = state.copyWith(selected: project);
  }

  // Trả về null nếu thành công, hoặc chuỗi lỗi THẬT nếu thất bại
  Future<String?> createProject(
    String name, {
    String description = '',
  }) async {
    try {
      final result = await _repo.createProject(name, description: description);
      await loadProjects();
      await selectProject(ProjectModel(
        id:          result['id'].toString(),
        name:        name,
        description: description,
        role:        'Admin',
      ));
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<String?> updateProject(
    String projectId, {
    String? name,
    String? description,
  }) async {
    try {
      await _repo.updateProject(projectId, name: name, description: description);
      await loadProjects();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<String?> deleteProject(String projectId) async {
    try {
      await _repo.deleteProject(projectId);
      // Nếu đang xóa đúng dự án đang chọn → bỏ chọn ngay
      if (state.selected?.id == projectId) {
        await _session.saveProjectId('');
        state = state.copyWith(clearSelected: true);
      }
      await loadProjects();
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }
}
