import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/workflow_widgets.dart';
import '../../project/presentation/project_provider.dart';
import '../../project/presentation/project_widgets.dart';
import '../../task_board/presentation/task_provider.dart';

class WorkOrganizationScreen extends ConsumerStatefulWidget {
  const WorkOrganizationScreen({required this.onNavigate, super.key});
  final NavigateTo onNavigate;

  @override
  ConsumerState<WorkOrganizationScreen> createState() =>
      _WorkOrganizationScreenState();
}

class _WorkOrganizationScreenState extends ConsumerState<WorkOrganizationScreen> {
  NavigateTo get onNavigate => widget.onNavigate;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    // Dự án mới được thêm vào (hoặc tiến độ đổi) phải hiện ngay khi mở tab này.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(projectProvider.notifier).loadProjects(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openProject(WidgetRef ref, String id, String title) {
    ref.read(kanbanTargetProvider.notifier).state =
        KanbanTarget(projectId: id, projectName: title);
    onNavigate(AppScreen.kanbanBoard);
  }

  @override
  Widget build(BuildContext context) {
    final projectState = ref.watch(projectProvider);
    final allProjects  = projectState.projects;
    final apiProjects  = _query.isEmpty
        ? allProjects
        : allProjects.where((p) {
            final q = _query.toLowerCase();
            return p.name.toLowerCase().contains(q) ||
                p.description.toLowerCase().contains(q);
          }).toList();
    final count = apiProjects.length;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
          child: Column(
            children: [
              ScreenHeader(
                title: 'CÁC DỰ ÁN',
                eyebrow: '${allProjects.length} DỰ ÁN ĐANG HOẠT ĐỘNG',
                action: CircleAction(
                  icon: Icons.add_rounded,
                  onPressed: () =>
                      showCreateProjectSheet(context, ref),
                ),
              ),
              const SizedBox(height: 22),
              SearchField(
                'Tìm kiếm dự án',
                controller: _searchController,
                onChanged: (val) => setState(() => _query = val.trim()),
              ),
              const SizedBox(height: 24),
              SectionTitle(
                eyebrow: 'DANH MỤC',
                title: 'Tất cả dự án',
                trailing: _CountBadge(count: count),
              ),
              const SizedBox(height: 14),
              if (allProjects.isEmpty)
                ProjectEmptyState(
                  onCreateTap: () => showCreateProjectSheet(context, ref),
                )
              else if (apiProjects.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'Không tìm thấy dự án phù hợp',
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.92,
                  ),
                  itemCount: count,
                  itemBuilder: (context, index) {
                    final p     = apiProjects[index];
                    final title = p.name;
                    final id    = p.id;
                    return _ProjectCard(
                      title:    title,
                      detail:   p.description,
                      progress: (p.progress / 100).clamp(0.0, 1.0).toDouble(),
                      icon:     Icons.folder_outlined,
                      color:    AppColors.lilac,
                      onTap:    () => _openProject(ref, id, title),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        active:     AppScreen.workOrganization,
        onNavigate: onNavigate,
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.title,
    required this.detail,
    required this.progress,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String   title;
  final String   detail;
  final double   progress;
  final IconData icon;
  final Color    color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 150;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 41,
                        height: 41,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon,
                          size: 20,
                          color: color == AppColors.charcoal
                              ? Colors.white
                              : AppColors.ink,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.soft,
                        size: 18,
                      ),
                    ],
                  ),
                  if (!compact) const Spacer(),
                  if (compact) const SizedBox(height: 12),
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Flexible(
                    child: Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.soft, fontSize: 7),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          minHeight: 4,
                          color: AppColors.accent,
                          backgroundColor: AppColors.surface,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        '${(progress * 100).round()}%',
                        style: const TextStyle(
                            fontSize: 7, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({this.count = 0});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        count.toString().padLeft(2, '0'),
        style: const TextStyle(color: AppColors.muted, fontSize: 8),
      ),
    );
  }
}
