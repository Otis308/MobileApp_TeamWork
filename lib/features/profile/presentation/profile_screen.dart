import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/workflow_widgets.dart';
import '../../auth/presentation/auth_provider.dart';
import 'profile_card.dart';
import 'profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({required this.onNavigate, super.key});
  final NavigateTo onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 40),
                const SizedBox(height: 12),
                Text('Không tải được\n$e', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () =>
                      ref.read(profileProvider.notifier).loadProfile(),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
          data: (profile) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ScreenHeader(
                  title: 'Profile',
                  eyebrow: 'KHÔNG GIAN CÁ NHÂN',
                  action: CircleAction(
                    icon: Icons.more_horiz_rounded,
                    onPressed: () {},
                  ),
                ),
                const SizedBox(height: 24),
                ProfileCard(profile: profile),
                const SizedBox(height: 28),
                const SectionTitle(
                  eyebrow: 'PREFERENCES',
                  title: 'Cài đặt',
                ),
                const SizedBox(height: 14),
                _AccountSettingsTile(profile: profile),
                const SizedBox(height: 28),
                _LogoutButton(onNavigate: onNavigate),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        active: AppScreen.profile,
        onNavigate: onNavigate,
      ),
    );
  }
}

// ── Account Settings tile ──
class _AccountSettingsTile extends StatelessWidget {
  const _AccountSettingsTile({required this.profile});
  final Map<String, dynamic> profile;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _PermissionsSheet(profile: profile),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.manage_accounts_outlined,
                  color: AppColors.ink, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cài đặt tài khoản', style: TextStyle(
                    color: AppColors.ink, fontSize: 12,
                    fontWeight: FontWeight.w700)),
                SizedBox(height: 2),
                Text('Quyền truy cập thiết bị', style: TextStyle(
                    color: AppColors.soft, fontSize: 10)),
              ],
            )),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.soft, size: 20),
          ]),
        ),
      ),
    );
  }
}

// ── Logout button ──
class _LogoutButton extends ConsumerWidget {
  const _LogoutButton({required this.onNavigate});
  final NavigateTo onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: () async {
        await ref.read(authControllerProvider.notifier).logout();
        onNavigate(AppScreen.login);
      },
      icon: const Icon(Icons.logout_rounded, size: 19),
      label: const Text('Đăng xuất'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.accent,
        minimumSize: const Size.fromHeight(50),
        side: const BorderSide(color: AppColors.accent, width: 1.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _PermissionsSheet extends ConsumerWidget {
  const _PermissionsSheet({required this.profile});
  final Map<String, dynamic> profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data  = ref.watch(profileProvider).value ?? profile;
    final perms = data['permissions'] as Map? ?? {'camera': false};

    final camGranted  = perms['camera'] as bool? ?? false;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          )),
          const SizedBox(height: 16),
          Text('Cài đặt tài khoản',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          const Text('Cấp quyền để sử dụng đầy đủ tính năng',
              style: TextStyle(color: AppColors.muted, fontSize: 12)),
          const SizedBox(height: 20),

          _PermTile(
            icon: Icons.camera_alt_outlined,
            title: 'Camera',
            subtitle: 'Thay đổi ảnh đại diện',
            isGranted: camGranted,
            onGrant: () => _request(context, ref,
                permission: Permission.camera,
                label: 'Camera',
                onGranted: () => ref.read(profileProvider.notifier)
                    .updatePermissions(camera: true)),
          ),
        ],
      ),
    );
  }

  Future<void> _request(
    BuildContext context, WidgetRef ref, {
    required Permission permission,
    required String label,
    required Future<void> Function() onGranted,
  }) async {
    if (await permission.isGranted) { await onGranted(); return; }

    final result = await permission.request();
    if (result.isGranted) {
      await onGranted();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Đã cấp quyền $label'),
          backgroundColor: Colors.green,
        ));
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Bạn chưa cấp quyền $label'),
          backgroundColor: Colors.orange,
          action: SnackBarAction(
            label: 'Mở cài đặt',
            textColor: Colors.white,
            onPressed: openAppSettings,
          ),
        ));
      }
    }
  }
}

class _PermTile extends StatelessWidget {
  const _PermTile({
    required this.icon, required this.title, required this.subtitle,
    required this.isGranted, required this.onGrant,
  });
  final IconData icon;
  final String title, subtitle;
  final bool isGranted;
  final VoidCallback onGrant;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: isGranted ? const Color(0xFFFFDDD7) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon,
            color: isGranted ? AppColors.accent : AppColors.muted, size: 20),
      ),
      title: Text(title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 10, color: AppColors.muted)),
      trailing: isGranted
          ? const Icon(Icons.check_circle_rounded,
              color: Colors.green, size: 22)
          : FilledButton(
              onPressed: onGrant,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(fontSize: 11),
              ),
              child: const Text('Cấp quyền'),
            ),
    );
  }
}