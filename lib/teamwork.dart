import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/core_providers.dart';
import 'core/router/app_router.dart';
import 'core/services/in_app_notification_service.dart';
import 'core/services/websocket_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_status_provider.dart';
import 'features/notifications/presentation/notification_provider.dart';
import 'features/profile/presentation/profile_provider.dart';
import 'features/project/presentation/project_provider.dart';
import 'features/task_board/presentation/task_provider.dart';
import 'features/team/presentation/team_provider.dart';
import 'features/timeline/presentation/timeline_provider.dart';

class TeamWork extends ConsumerStatefulWidget {
  const TeamWork({super.key});

  @override
  ConsumerState<TeamWork> createState() => _TeamWorkState();
}

class _TeamWorkState extends ConsumerState<TeamWork> {
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  StreamSubscription<InAppNotification>? _notificationSub;

  @override
  void initState() {
    super.initState();
    _notificationSub =
        InAppNotificationService().stream.listen(_showNotificationSnackBar);
  }

  @override
  void dispose() {
    _notificationSub?.cancel();
    super.dispose();
  }

  void _showNotificationSnackBar(InAppNotification notification) {
    _messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          notification.body.isNotEmpty
              ? '${notification.title}: ${notification.body}'
              : notification.title,
        ),
        backgroundColor: AppColors.charcoal,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  // Đăng nhập/đăng xuất: bỏ state gắn với tài khoản cũ để tài khoản mới không thấy
  // dữ liệu (dự án, thông báo…) của người trước.
  void _resetUserState() {
    ref
      ..invalidate(projectProvider)
      ..invalidate(teamProvider)
      ..invalidate(taskBoardProvider)
      ..invalidate(kanbanTargetProvider)
      ..invalidate(timelineProvider)
      ..invalidate(notificationProvider)
      ..invalidate(profileProvider);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthStatus>(authStatusProvider, (prev, next) {
      // Mở lại app khi đã có token chỉ đi qua splash → dashboard, không qua màn đăng nhập,
      // nên phải tự kết nối real-time ở đây (connect() idempotent).
      if (next == AuthStatus.authenticated) {
        ref.read(webSocketServiceProvider).connect();
      } else if (next == AuthStatus.unauthenticated) {
        ref.read(webSocketServiceProvider).disconnect();
      }
      final changed = prev != null &&
          prev != AuthStatus.unknown &&
          next != AuthStatus.unknown &&
          prev != next;
      if (changed) _resetUserState();
    });

    return MaterialApp.router(
      title: 'TeamWork',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      scaffoldMessengerKey: _messengerKey,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) => Stack(
        children: [
          child ?? const SizedBox.shrink(),
          const Positioned(top: 0, left: 0, right: 0, child: _ConnectionBanner()),
        ],
      ),
    );
  }
}

// Hiện khi đang mất kết nối real-time; Socket.IO tự nối lại nên chỉ cần báo cho người dùng.
class _ConnectionBanner extends ConsumerWidget {
  const _ConnectionBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(socketStatusProvider).value;
    if (status != SocketStatus.reconnecting) return const SizedBox.shrink();
    return Material(
      color: const Color(0xFFB26A00),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 8),
              Text(
                'Mất kết nối — đang kết nối lại…',
                style: TextStyle(color: Colors.white, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
