import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/app_config.dart';
import 'in_app_notification_service.dart';
import 'session_service.dart';

enum SocketStatus { idle, connected, reconnecting }

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal() {
    _attachTargetedAlerts();
  }

  io.Socket? _socket;
  final _session = SessionService();
  final _notifications = InAppNotificationService();

  // Mỗi tên sự kiện có đúng 1 broadcast stream; nhiều nơi cùng lắng nghe mà không
  // giẫm lên nhau, và hủy subscription là đủ để dọn (không còn off(event) toàn cục).
  final Map<String, StreamController<dynamic>> _controllers = {};

  // Đếm số nơi đang dùng mỗi phòng dự án — chỉ rời phòng khi không còn ai dùng.
  final Map<String, int> _rooms = {};

  final _statusController = StreamController<SocketStatus>.broadcast();
  SocketStatus _status = SocketStatus.idle;

  bool get isConnected => _socket?.connected ?? false;
  SocketStatus get status => _status;
  Stream<SocketStatus> get statusStream => _statusController.stream;

  void _setStatus(SocketStatus s) {
    if (_status == s) return;
    _status = s;
    _statusController.add(s);
  }

  // Stream sự kiện từ server. An toàn khi gọi trước lúc kết nối.
  Stream<dynamic> events(String event) {
    final controller = _controllers.putIfAbsent(event, () {
      final c = StreamController<dynamic>.broadcast();
      _bind(event, c);
      return c;
    });
    return controller.stream;
  }

  // Chỉ dùng trong test: giả lập server phát sự kiện.
  @visibleForTesting
  void debugEmit(String event, dynamic data) => _controllers[event]?.add(data);

  void _bind(String event, StreamController<dynamic> controller) {
    _socket?.on(event, (data) {
      controller.add(data);
    });
  }

  void _attachTargetedAlerts() {
    events('you_were_added_to_project').listen((data) {
      if (data is! Map) return;
      _notifications.push(
        title: data['title']?.toString() ?? 'Thông báo mới',
        body: data['body']?.toString() ?? '',
        type: data['type']?.toString() ?? 'member_added',
        projectId: data['projectId']?.toString(),
      );
    });

    events('new_task_assigned').listen((data) {
      if (data is! Map) return;
      _notifications.push(
        title: data['title']?.toString() ?? 'Thông báo mới',
        body: data['body']?.toString() ?? '',
        type: data['type']?.toString() ?? 'task_assigned',
        projectId: data['projectId']?.toString(),
        taskId: data['taskId']?.toString(),
      );
    });
  }

  // Kết nối tới server — gọi 1 lần sau khi login
  Future<void> connect() async {
    if (_socket != null) return; // đã có socket: Socket.IO tự kết nối lại

    final token = await _session.getToken();

    _socket = io.io(
      AppConfig.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token ?? ''})   // server verifies JWT on connect
          .disableAutoConnect()
          .build(),
    );

    // Socket mới → gắn lại mọi stream đã có người nghe.
    _controllers.forEach(_bind);

    _socket!.onConnect((_) {
      _setStatus(SocketStatus.connected);
      // Vào lại các phòng đang dùng (lần đầu và sau mỗi lần tự kết nối lại).
      for (final projectId in _rooms.keys) {
        _socket?.emit('join_project', {'projectId': projectId});
      }
    });

    _socket!.onDisconnect((_) {
      if (_socket != null) _setStatus(SocketStatus.reconnecting);
    });

    _socket!.connect();
  }

  // Vào phòng dự án để nhận cập nhật real-time của dự án đó.
  void joinProject(String projectId) {
    final count = (_rooms[projectId] ?? 0) + 1;
    _rooms[projectId] = count;
    if (count == 1 && isConnected) {
      _socket?.emit('join_project', {'projectId': projectId});
    }
  }

  void leaveProject(String projectId) {
    final count = _rooms[projectId];
    if (count == null) return;
    if (count > 1) {
      _rooms[projectId] = count - 1;
      return;
    }
    _rooms.remove(projectId);
    _socket?.emit('leave_project', {'projectId': projectId});
  }

  void disconnect() {
    final socket = _socket;
    _socket = null; // đặt trước để onDisconnect không báo "đang kết nối lại"
    socket?.disconnect();
    _rooms.clear();
    _setStatus(SocketStatus.idle);
  }
}
