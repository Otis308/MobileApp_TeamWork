import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../data/models/notification_model.dart';
import '../data/notification_repository.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/services/websocket_service.dart';

final notificationRepositoryProvider =
    Provider((ref) => NotificationRepository());

class NotificationState {
  final List<NotificationModel> items;
  final int unreadCount;
  final bool isLoading;
  final String? error;

  const NotificationState({
    this.items       = const [],
    this.unreadCount = 0,
    this.isLoading   = false,
    this.error,
  });

  NotificationState copyWith({
    List<NotificationModel>? items,
    int? unreadCount,
    bool? isLoading,
    String? error,
  }) =>
      NotificationState(
        items:       items       ?? this.items,
        unreadCount: unreadCount ?? this.unreadCount,
        isLoading:   isLoading   ?? this.isLoading,
        error:       error,
      );
}

final notificationProvider =
    StateNotifierProvider<NotificationController, NotificationState>((ref) {
  return NotificationController(
    ref.read(notificationRepositoryProvider),
    ref.read(webSocketServiceProvider),
  );
});

class NotificationController extends StateNotifier<NotificationState> {
  final NotificationRepository _repo;
  final WebSocketService _ws;
  final List<StreamSubscription<dynamic>> _subs = [];

  NotificationController(this._repo, this._ws) : super(const NotificationState()) {
    Future.microtask(() {
      loadNotifications();
      _attachRealtimeListener();
    });
  }

  static String _msg(Object e) => e.toString().replaceFirst('Exception: ', '');

  // Server phát 'notification' kèm bản ghi vừa lưu; 'new_task_assigned' và
  // 'you_were_added_to_project' chỉ để hiện toast nên không thêm vào danh sách (tránh trùng).
  void _attachRealtimeListener() {
    _subs.add(_ws.events('notification').listen(_onNotification));

    // Mất kết nối rồi nối lại → có thể đã lỡ thông báo, tải lại từ server.
    _subs.add(_ws.statusStream
        .where((s) => s == SocketStatus.connected)
        .listen((_) => loadNotifications(silent: true)));
  }

  void _onNotification(dynamic data) {
    if (data is! Map) return;
    final incoming = NotificationModel.fromJson(Map<String, dynamic>.from(data));
    if (state.items.any((n) => n.id == incoming.id)) return;
    final item = incoming.createdAt == null
        ? incoming.copyWith(createdAt: DateTime.now())
        : incoming;
    state = state.copyWith(
      items:       [item, ...state.items],
      unreadCount: state.unreadCount + 1,
    );
  }

  Future<void> loadNotifications({bool silent = false}) async {
    if (!silent) state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _repo.getMyNotifications();
      final unread = await _repo.getUnreadCount();
      state = state.copyWith(
        items: items, unreadCount: unread, isLoading: false, error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _msg(e));
    }
  }

  Future<String?> markAllRead() async {
    try {
      await _repo.markAllRead();
      state = state.copyWith(
        items: state.items.map((n) => n.copyWith(isRead: true)).toList(),
        unreadCount: 0,
      );
      return null;
    } catch (e) {
      return _msg(e);
    }
  }

  Future<String?> markOneRead(String id) async {
    final target = state.items.where((n) => n.id == id).firstOrNull;
    if (target == null || target.isRead) return null;
    try {
      await _repo.markOneRead(id);
      state = state.copyWith(
        items: state.items
            .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
            .toList(),
        unreadCount: (state.unreadCount - 1).clamp(0, 999),
      );
      return null;
    } catch (e) {
      return _msg(e);
    }
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }
}
