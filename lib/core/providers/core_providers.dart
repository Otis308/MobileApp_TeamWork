import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../services/session_service.dart';
import '../services/websocket_service.dart';

final sessionServiceProvider = Provider<SessionService>((ref) => SessionService());

final webSocketServiceProvider = Provider<WebSocketService>((ref) => WebSocketService());

final dioProvider = Provider<Dio>((ref) => ApiClient().dio);

// Sự kiện Socket.IO theo tên, dùng được với ref.watch/ref.listen trong widget.
final socketEventProvider =
    StreamProvider.autoDispose.family<dynamic, String>((ref, event) {
  return ref.watch(webSocketServiceProvider).events(event);
});

// Trạng thái kết nối real-time (để hiện banner "đang kết nối lại").
final socketStatusProvider = StreamProvider.autoDispose<SocketStatus>((ref) async* {
  final ws = ref.watch(webSocketServiceProvider);
  yield ws.status;
  yield* ws.statusStream;
});
