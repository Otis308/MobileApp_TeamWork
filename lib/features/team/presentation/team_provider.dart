import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../data/models/project_member_model.dart';
import '../data/team_repository.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/services/session_service.dart';
import '../../../core/services/websocket_service.dart';
import 'team_permissions.dart';

final teamRepositoryProvider = Provider((ref) => TeamRepository());

class TeamState {
  final List<ProjectMemberModel> members;
  final String projectId;
  final String? myRole;
  final Set<String> onlineUserIds;
  final bool isLoading;
  final String? error;

  const TeamState({
    this.members       = const [],
    this.projectId     = '',
    this.myRole,
    this.onlineUserIds = const {},
    this.isLoading     = false,
    this.error,
  });

  TeamPermissions get permissions => TeamPermissions(myRole);
  bool isOnline(String userId) => onlineUserIds.contains(userId);

  TeamState copyWith({
    List<ProjectMemberModel>? members,
    String? projectId,
    String? myRole,
    bool clearMyRole = false,
    Set<String>? onlineUserIds,
    bool? isLoading,
    String? error,
  }) =>
      TeamState(
        members:       members       ?? this.members,
        projectId:     projectId     ?? this.projectId,
        myRole:        clearMyRole ? null : (myRole ?? this.myRole),
        onlineUserIds: onlineUserIds ?? this.onlineUserIds,
        isLoading:     isLoading     ?? this.isLoading,
        error:         error,                    // null = xóa lỗi cũ
      );
}

final teamProvider =
    StateNotifierProvider<TeamController, TeamState>((ref) {
  return TeamController(
    ref.read(teamRepositoryProvider),
    ref.read(webSocketServiceProvider),
  );
});

class TeamController extends StateNotifier<TeamState> {
  final TeamRepository _repo;
  final WebSocketService _ws;
  final _session = SessionService();
  final List<StreamSubscription<dynamic>> _subs = [];
  String? _boundProjectId;

  TeamController(this._repo, this._ws) : super(const TeamState()) {
    Future.microtask(loadMembers);
  }

  static String _msg(Object e) => e.toString().replaceFirst('Exception: ', '');

  Future<void> loadMembers() async {
    final projectId = await _session.getProjectId();
    if (projectId == null || projectId.isEmpty) {
      // No project selected → honest empty state, no fake API call.
      state = state.copyWith(
        members: const [], projectId: '', clearMyRole: true, isLoading: false,
      );
      return;
    }
    await loadMembersForProject(projectId);
  }

  Future<void> loadMembersForProject(String projectId, {bool silent = false}) async {
    if (projectId.isEmpty) {
      state = state.copyWith(
        members: const [], projectId: '', clearMyRole: true, isLoading: false,
      );
      return;
    }
    if (!silent) state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        _repo.getMembers(projectId),
        _repo.getMyRole(projectId),
      ]);
      state = state.copyWith(
        members:   results[0] as List<ProjectMemberModel>,
        myRole:    results[1] as String,
        projectId: projectId,
        isLoading: false,
      );
      _bindProject(projectId);
    } catch (e) {
      state = state.copyWith(isLoading: false, clearMyRole: true, error: _msg(e));
    }
  }

  // Vào phòng dự án + lắng nghe thay đổi thành viên và trạng thái online.
  void _bindProject(String projectId) {
    if (_boundProjectId == projectId) return;
    _unbind();
    state = state.copyWith(onlineUserIds: const {});
    _boundProjectId = projectId;
    _ws.joinProject(projectId);

    void reload(dynamic _) => loadMembersForProject(projectId, silent: true);
    for (final event in const [
      'member_added', 'member_removed', 'member_role_changed',
    ]) {
      _subs.add(_ws.events(event).listen(reload));
    }

    _subs.add(_ws.events('presence').listen((data) {
      if (data is! Map || data['projectId']?.toString() != projectId) return;
      final userId = data['userId']?.toString();
      if (userId == null) return;
      final next = {...state.onlineUserIds};
      data['online'] == true ? next.add(userId) : next.remove(userId);
      state = state.copyWith(onlineUserIds: next);
    }));

    _subs.add(_ws.events('presence_snapshot').listen((data) {
      if (data is! Map || data['projectId']?.toString() != projectId) return;
      final ids = (data['userIds'] as List? ?? []).map((e) => e.toString());
      state = state.copyWith(onlineUserIds: {...state.onlineUserIds, ...ids});
    }));
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

  // Các hàm dưới trả về null nếu thành công, hoặc thông báo lỗi THẬT của server.
  Future<String?> addMember(String email) async {
    try {
      await _repo.addMember(state.projectId, email);
      await loadMembersForProject(state.projectId, silent: true);
      return null;
    } catch (e) {
      return _msg(e);
    }
  }

  Future<String?> removeMember(String targetUserId) async {
    try {
      await _repo.removeMember(state.projectId, targetUserId);
      // Xóa khỏi list local ngay để UI phản hồi tức thì
      state = state.copyWith(
        members: state.members.where((m) => m.id != targetUserId).toList(),
      );
      return null;
    } catch (e) {
      return _msg(e);
    }
  }

  Future<String?> updateMemberRole(String targetUserId, String newRole) async {
    try {
      await _repo.updateMemberRole(state.projectId, targetUserId, newRole);
      state = state.copyWith(
        members: state.members
            .map((m) => m.id == targetUserId ? m.copyWith(role: newRole) : m)
            .toList(),
      );
      return null;
    } catch (e) {
      return _msg(e);
    }
  }

  @override
  void dispose() {
    _unbind();
    super.dispose();
  }
}
