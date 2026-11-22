import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/workflow_widgets.dart';
import '../../project/presentation/project_provider.dart';
import '../../team/presentation/team_provider.dart';
import '../../team/data/models/project_member_model.dart';
import '../data/models/task_model.dart';
import 'kanban_widgets.dart';
import 'task_detail_screen.dart';
import 'task_provider.dart';

class KanbanBoardScreen extends ConsumerStatefulWidget {
  const KanbanBoardScreen({required this.onNavigate, super.key});
  final NavigateTo onNavigate;

  @override
  ConsumerState<KanbanBoardScreen> createState() => _KanbanBoardScreenState();
}

class _KanbanBoardScreenState extends ConsumerState<KanbanBoardScreen> {
  final _boardController = ScrollController();
  final _columnControllers = {
    for (final s in kanbanStatuses) s: ScrollController(),
  };
  final _columnKeys = {for (final s in kanbanStatuses) s: GlobalKey()};
  final _pointer = ValueNotifier<Offset?>(null);
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = ref.read(kanbanTargetProvider);
      if (target.projectId.isNotEmpty) {
        ref.read(taskBoardProvider.notifier).loadTasks(target.projectId);
        ref.read(teamProvider.notifier).loadMembersForProject(target.projectId);
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pointer.dispose();
    _boardController.dispose();
    for (final c in _columnControllers.values) {
      c.dispose();
    }
    ref.read(taskBoardProvider.notifier).leaveRoom();
    super.dispose();
  }

  // ── Kéo thả: tự cuộn khi con trỏ chạm mép ──
  void _onDragStart() {
    _autoScrollTimer ??=
        Timer.periodic(const Duration(milliseconds: 16), (_) => _autoScroll());
  }

  void _onDragUpdate(Offset position) => _pointer.value = position;

  void _onDragEnd() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    _pointer.value = null;
  }

  void _autoScroll() {
    final p = _pointer.value;
    if (p == null || !mounted) return;
    const edge = 56.0;
    const step = 14.0;

    if (_boardController.hasClients) {
      final pos = _boardController.position;
      final width = MediaQuery.sizeOf(context).width;
      double? target;
      if (p.dx < edge) target = pos.pixels - step;
      if (p.dx > width - edge) target = pos.pixels + step;
      if (target != null) {
        _boardController.jumpTo(
          target.clamp(pos.minScrollExtent, pos.maxScrollExtent),
        );
      }
    }

    for (final status in kanbanStatuses) {
      final box = _columnKeys[status]?.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.attached) continue;
      final rect = box.localToGlobal(Offset.zero) & box.size;
      if (!rect.contains(p)) continue;
      final c = _columnControllers[status]!;
      if (!c.hasClients) break;
      double? target;
      if (p.dy < rect.top + 90) target = c.offset - step;
      if (p.dy > rect.bottom - 110) target = c.offset + step;
      if (target != null) {
        c.jumpTo(target.clamp(
          c.position.minScrollExtent,
          c.position.maxScrollExtent,
        ));
      }
      break;
    }
  }

  void _openTask(TaskModel task) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TaskDetailScreen(taskId: task.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final target     = ref.watch(kanbanTargetProvider);
    final boardState = ref.watch(taskBoardProvider);
    final teamState  = ref.watch(teamProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Column(
                children: [
                  ScreenHeader(
                    title: target.projectName,
                    eyebrow: 'BẢNG KANBAN',
                    action: CircleAction(
                      icon: Icons.more_horiz,
                      onPressed: () => _showProjectMenu(context, ref, target),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _MemberStackWidget(members: teamState.members),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: () =>
                            _showFilterSheet(context, ref, teamState.members),
                        icon: Icon(Icons.tune_rounded,
                            size: 16,
                            color: boardState.filter.isActive
                                ? AppColors.accent
                                : null),
                        label: Text(boardState.filter.isActive
                            ? 'Bộ lọc •'
                            : 'Bộ lọc'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.ink,
                          side: const BorderSide(color: AppColors.line),
                          textStyle: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: boardState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : boardState.error != null
                      ? Center(child: Text('Lỗi: ${boardState.error}'))
                      : _buildColumns(context, boardState, teamState),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        active: AppScreen.workOrganization,
        onNavigate: widget.onNavigate,
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Build 3 cột Kanban (kéo thả)
  // ─────────────────────────────────────────────
  Widget _buildColumns(
    BuildContext context,
    TaskBoardState boardState,
    TeamState teamState,
  ) {
    final columns = [
      ('todo',  'Cần làm',        AppColors.ink),
      ('doing', 'Đang thực hiện', AppColors.accent),
      ('done',  'Hoàn thành',     const Color(0xFF77AD8B)),
    ];

    return ListView.separated(
      controller: _boardController,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      itemCount: columns.length,
      separatorBuilder: (_, _) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        final (statusKey, title, color) = columns[index];
        return KeyedSubtree(
          key: _columnKeys[statusKey],
          child: KanbanColumnView(
            status: statusKey,
            title: title,
            color: color,
            tasks: boardState.column(statusKey),
            pointer: _pointer,
            scrollController: _columnControllers[statusKey]!,
            onDropped: (task, targetIndex) => _handleDrop(task, statusKey, targetIndex),
            onDragStart: _onDragStart,
            onDragUpdate: _onDragUpdate,
            onDragEnd: _onDragEnd,
            onOpenTask: _openTask,
            onTapAssignee: (task) =>
                _showAssigneeSheet(context, ref, task, teamState.members),
            onDeleteTask: (task) => _confirmDeleteTask(context, task),
            onAddTask: () => _showAddTaskSheet(context, ref, teamState.members),
          ),
        );
      },
    );
  }

  Future<void> _handleDrop(TaskModel task, String status, int targetIndex) async {
    final error = await ref
        .read(taskBoardProvider.notifier)
        .moveTask(task.id, status, targetIndex);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không di chuyển được: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ─────────────────────────────────────────────
  // Sheet bộ lọc (lọc phía server)
  // ─────────────────────────────────────────────
  void _showFilterSheet(
    BuildContext context,
    WidgetRef ref,
    List<ProjectMemberModel> members,
  ) {
    var filter = ref.read(taskBoardProvider).filter;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          void apply(TaskFilter next) {
            setModal(() => filter = next);
            ref.read(taskBoardProvider.notifier).setFilter(next);
          }

          Widget chip(String label, bool selected, VoidCallback onTap) =>
              ChoiceChip(
                label: Text(label),
                selected: selected,
                onSelected: (_) => onTap(),
              );

          return Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Bộ lọc',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    if (filter.isActive)
                      TextButton(
                        onPressed: () => apply(const TaskFilter()),
                        child: const Text('Xóa bộ lọc'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('ĐỘ ƯU TIÊN',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.muted,
                        letterSpacing: 1.2)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final (value, label) in const [
                      ('high', 'Cao'),
                      ('medium', 'Trung bình'),
                      ('low', 'Thấp'),
                    ])
                      chip(
                        label,
                        filter.priority == value,
                        () => apply(TaskFilter(
                          assigneeId: filter.assigneeId,
                          priority: filter.priority == value ? null : value,
                        )),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('NGƯỜI PHỤ TRÁCH',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.muted,
                        letterSpacing: 1.2)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final m in members)
                      chip(
                        m.name,
                        filter.assigneeId == m.id,
                        () => apply(TaskFilter(
                          assigneeId: filter.assigneeId == m.id
                              ? null
                              : m.id,
                          priority: filter.priority,
                        )),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Sheet thêm công việc mới
  // ─────────────────────────────────────────────
  void _showAddTaskSheet(
    BuildContext context,
    WidgetRef ref,
    List<ProjectMemberModel> members,
  ) {
    final titleCtrl = TextEditingController();
    String? selectedAssigneeId;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(ctx).bottom,
          ),
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
                const Text(
                  'Thêm công việc',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Tên công việc *',
                    prefixIcon: Icon(Icons.task_alt_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'GIAO CHO',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppColors.muted,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                if (members.isEmpty)
                  const Text(
                    'Chưa có thành viên trong dự án',
                    style: TextStyle(color: AppColors.muted, fontSize: 11),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: members.map((m) {
                      final id   = m.id;
                      final name = m.name;
                      final isSelected = selectedAssigneeId == id;
                      return GestureDetector(
                        onTap: () => setModal(() {
                          selectedAssigneeId = isSelected ? null : id;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.accent
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              MemberAvatar(name: name, size: 20),
                              const SizedBox(width: 6),
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.ink,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () async {
                    final title = titleCtrl.text.trim();
                    if (title.isEmpty) return;
                    Navigator.pop(ctx);
                    final error = await ref.read(taskBoardProvider.notifier).createTask(
                          title: title,
                          assigneeId: selectedAssigneeId?.trim().isNotEmpty == true
                              ? selectedAssigneeId!.trim()
                              : null,
                        );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(error == null ? 'Đã thêm công việc' : 'Lỗi: $error'),
                          backgroundColor: error == null ? Colors.green : Colors.red,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.add_task_rounded),
                  label: const Text('Thêm vào bảng'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Sheet đổi người phụ trách
  // ─────────────────────────────────────────────
  void _showAssigneeSheet(
    BuildContext context,
    WidgetRef ref,
    TaskModel task,
    List<ProjectMemberModel> members,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Giao cho',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            if (members.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Dự án chưa có thành viên nào',
                  style: TextStyle(color: AppColors.muted),
                ),
              )
            else
              ...members.map((m) {
                final id   = m.id;
                final name = m.name;
                final isSelected = task.assignee?.id == id;

                return ListTile(
                  leading: MemberAvatar(name: name, size: 36),
                  title: Text(name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppColors.accent)
                      : null,
                  onTap: () async {
                    Navigator.pop(context);
                    final ok = await ref
                        .read(taskBoardProvider.notifier)
                        .updateAssignee(task.id, id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text(ok != null ? 'Đã giao cho $name' : 'Thất bại'),
                          backgroundColor: ok != null ? Colors.green : Colors.red,
                        ),
                      );
                    }
                  },
                );
              }),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteTask(BuildContext context, TaskModel task) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa công việc'),
        content: Text('Xóa "${task.title}" khỏi bảng?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(taskBoardProvider.notifier)
                  .deleteTask(task.id);
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Menu 3 chấm — Sửa / Xóa dự án
  // ─────────────────────────────────────────────
  void _showProjectMenu(
    BuildContext context,
    WidgetRef ref,
    KanbanTarget target,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              target.projectName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const Divider(height: 24),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: AppColors.accent),
              title: const Text('Sửa tên / mô tả dự án'),
              onTap: () {
                Navigator.pop(context);
                _showEditProjectSheet(context, ref, target);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Xóa dự án', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteProject(context, ref, target);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProjectSheet(
    BuildContext context,
    WidgetRef ref,
    KanbanTarget target,
  ) {
    final nameCtrl = TextEditingController(text: target.projectName);
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
              const Text(
                'Sửa dự án',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Tên dự án'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Mô tả'),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () async {
                  final newName = nameCtrl.text.trim();
                  if (newName.isEmpty) return;
                  Navigator.pop(ctx);
                  final error = await ref.read(projectProvider.notifier).updateProject(
                        target.projectId,
                        name:        newName,
                        description: descCtrl.text.trim(),
                      );
                  if (error == null) {
                    ref.read(kanbanTargetProvider.notifier).state =
                        KanbanTarget(projectId: target.projectId, projectName: newName);
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(error == null ? 'Đã cập nhật' : 'Lỗi: $error'),
                        backgroundColor: error == null ? Colors.green : Colors.red,
                      ),
                    );
                  }
                },
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                child: const Text('Lưu thay đổi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteProject(
    BuildContext context,
    WidgetRef ref,
    KanbanTarget target,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa dự án'),
        content: Text(
          'Xóa "${target.projectName}"? Toàn bộ công việc và thành viên sẽ mất.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              final error = await ref.read(projectProvider.notifier).deleteProject(target.projectId);
              if (error == null) {
                widget.onNavigate(AppScreen.workOrganization);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error == null ? 'Đã xóa dự án' : 'Lỗi: $error'),
                    backgroundColor: error == null ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════
// CÁC WIDGET CON — TOP-LEVEL, NẰM NGOÀI STATE CLASS
// ═════════════════════════════════════════════

class _MemberStackWidget extends StatelessWidget {
  const _MemberStackWidget({required this.members});
  final List<ProjectMemberModel> members;

  @override
  Widget build(BuildContext context) {
    final shown = members.take(4).toList();
    return SizedBox(
      width: shown.length * 20 + 10,
      height: 32,
      child: Stack(
        children: [
          for (final (i, m) in shown.indexed)
            Positioned(
              left: i * 20,
              child: MemberAvatar(
                name: m.name,
                size: 30,
              ),
            ),
        ],
      ),
    );
  }
}
