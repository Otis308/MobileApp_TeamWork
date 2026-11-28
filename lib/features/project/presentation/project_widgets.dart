import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import 'project_provider.dart';

// Bottom sheet tạo dự án dùng chung cho màn chọn dự án và màn danh mục dự án.
// [onCreated] được gọi khi tạo thành công; nếu null thì hiện snackbar xác nhận.
void showCreateProjectSheet(
  BuildContext context,
  WidgetRef ref, {
  VoidCallback? onCreated,
}) {
  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFFFDDD7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.folder_outlined, color: AppColors.accent),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tạo dự án mới',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'Bạn sẽ là Quản trị viên của dự án này',
              style: TextStyle(color: AppColors.muted, fontSize: 11),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Tên dự án *',
                prefixIcon: Icon(Icons.folder_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Mô tả (tùy chọn)',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(ctx);
                final error = await ref
                    .read(projectProvider.notifier)
                    .createProject(name, description: descCtrl.text.trim());
                if (!context.mounted) return;
                if (error == null && onCreated != null) {
                  onCreated();
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error == null
                        ? 'Đã tạo dự án "$name"'
                        : 'Tạo dự án thất bại: $error'),
                    backgroundColor: error == null ? Colors.green : Colors.red,
                  ),
                );
              },
              icon: const Icon(Icons.rocket_launch_outlined),
              label: const Text('Tạo ngay'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class ProjectEmptyState extends StatelessWidget {
  const ProjectEmptyState({required this.onCreateTap, super.key});
  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFFDDD7),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.folder_open_outlined,
                  color: AppColors.accent, size: 36),
            ),
            const SizedBox(height: 16),
            const Text('Chưa có dự án nào',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text('Tạo dự án đầu tiên để bắt đầu',
                style: TextStyle(color: AppColors.muted, fontSize: 12)),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCreateTap,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tạo dự án'),
            ),
          ],
        ),
      ),
    );
  }
}
