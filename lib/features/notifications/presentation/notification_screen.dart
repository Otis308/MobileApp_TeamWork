import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/workflow_widgets.dart';
import '../data/models/notification_model.dart';
import 'notification_provider.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({required this.onNavigate, super.key});
  final NavigateTo onNavigate;

  static String ago(DateTime? time, [DateTime? now]) {
    if (time == null) return '';
    final diff = (now ?? DateTime.now()).difference(time);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return '${diff.inDays} ngày trước';
  }

  IconData _icon(String type) => switch (type) {
        'task_assigned' => Icons.assignment_ind_outlined,
        'member_added' => Icons.group_add_outlined,
        'task_comment' => Icons.chat_bubble_outline,
        _ => Icons.notifications_none_rounded,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationProvider);
    final controller = ref.read(notificationProvider.notifier);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: ScreenHeader(
                title: 'Thông báo',
                eyebrow: '${state.unreadCount} CHƯA ĐỌC',
                action: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (state.unreadCount > 0)
                      TextButton(
                        onPressed: () async {
                          final error = await controller.markAllRead();
                          if (error != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error), backgroundColor: Colors.red),
                            );
                          }
                        },
                        child: const Text('Đọc tất cả'),
                      ),
                    CircleAction(
                      icon: Icons.close_rounded,
                      onPressed: () => onNavigate(AppScreen.dashboard),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.loadNotifications,
                child: _body(context, state, controller),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    NotificationState state,
    NotificationController controller,
  ) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.items.isEmpty) {
      return ListView(children: [
        Padding(
          padding: const EdgeInsets.all(32),
          child: Center(child: Text('Lỗi: ${state.error}')),
        ),
      ]);
    }
    if (state.items.isEmpty) {
      return ListView(children: const [
        Padding(
          padding: EdgeInsets.all(48),
          child: Center(
            child: Text('Chưa có thông báo nào',
                style: TextStyle(color: AppColors.muted)),
          ),
        ),
      ]);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      itemCount: state.items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final n = state.items[i];
        return _NotificationTile(
          notification: n,
          icon: _icon(n.type),
          onTap: () => controller.markOneRead(n.id),
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.icon,
    required this.onTap,
  });

  final NotificationModel notification;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: unread ? const Color(0xFFFFF1EE) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: unread ? AppColors.accent : AppColors.line),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: unread ? AppColors.accent : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  size: 20, color: unread ? Colors.white : AppColors.muted),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                  if (notification.body.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(notification.body,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.muted)),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    NotificationScreen.ago(notification.createdAt),
                    style: const TextStyle(fontSize: 9, color: AppColors.soft),
                  ),
                ],
              ),
            ),
            if (unread)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
