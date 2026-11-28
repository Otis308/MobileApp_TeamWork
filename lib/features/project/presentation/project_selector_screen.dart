import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/workflow_widgets.dart';
import '../data/models/project_model.dart';
import 'project_provider.dart';
import 'project_widgets.dart';

class ProjectSelectorScreen extends ConsumerWidget {
  const ProjectSelectorScreen({required this.onNavigate, super.key});
  final NavigateTo onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(projectProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAction(
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => onNavigate(AppScreen.dashboard),
                  ),
                  const SizedBox(width: 14),
                  const WorkFlowLogo(),
                ],
              ),
              const SizedBox(height: 28),
              const Eyebrow('CHỌN DỰ ÁN', color: AppColors.accent),
              const SizedBox(height: 8),
              Text(
                'CÁC DỰ ÁN',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 6),
              const Text(
                'Chọn dự án để tiếp tục hoặc tạo mới.',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 28),

              // Danh sách dự án
              Expanded(
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : state.error != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.error_outline_rounded,
                                      color: Colors.red, size: 44),
                                  const SizedBox(height: 12),
                                  Text(
                                    state.error!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: AppColors.ink,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  FilledButton.icon(
                                    onPressed: () => ref
                                        .read(projectProvider.notifier)
                                        .loadProjects(),
                                    icon: const Icon(Icons.refresh_rounded, size: 18),
                                    label: const Text('Thử lại'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : state.projects.isEmpty
                            ? ProjectEmptyState(
                                onCreateTap: () => showCreateProjectSheet(
                                  context, ref,
                                  onCreated: () => onNavigate(AppScreen.dashboard),
                                ),
                              )
                            : ListView.separated(
                            itemCount: state.projects.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (ctx, i) {
                              final p = state.projects[i];
                              final isSelected = state.selected?.id == p.id;
                              return _ProjectCard(
                                project: p,
                                isSelected: isSelected,
                                onTap: () async {
                                  await ref
                                      .read(projectProvider.notifier)
                                      .selectProject(p);
                                  onNavigate(AppScreen.dashboard);
                                },
                              );
                            },
                          ),
              ),

              const SizedBox(height: 16),
              // Nút tạo dự án mới
              OutlinedButton.icon(
                onPressed: () => showCreateProjectSheet(
                  context, ref,
                  onCreated: () => onNavigate(AppScreen.dashboard),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Tạo dự án mới'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  foregroundColor: AppColors.accent,
                  side: const BorderSide(color: AppColors.accent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

// ── Project card ──
class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.isSelected,
    required this.onTap,
  });
  final ProjectModel project;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final role = project.role;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFDDD7) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.line,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accent : AppColors.surface,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(Icons.folder_outlined,
                color: isSelected ? Colors.white : AppColors.muted,
                size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                project.name,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: AppColors.ink),
              ),
              if (project.description.isNotEmpty)
                Text(
                  project.description,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          )),
          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _roleLabel(role),
              style: TextStyle(
                  fontSize: 9, fontWeight: FontWeight.w700,
                  color: isSelected
                      ? AppColors.accent
                      : AppColors.muted),
            ),
          ),
        ]),
      ),
    );
  }

  String _roleLabel(String role) => switch (role) {
    'Admin'   => 'Quản trị viên',
    'Manager' => 'Quản lý',
    _         => 'Thành viên',
  };
}