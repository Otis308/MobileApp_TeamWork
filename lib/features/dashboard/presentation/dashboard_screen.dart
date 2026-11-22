import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/workflow_widgets.dart';
import '../../notifications/presentation/notification_provider.dart';
import '../../project/presentation/project_provider.dart';
import '../../task_board/data/models/task_model.dart';
import '../../task_board/data/task_repository.dart';
import '../../task_board/presentation/task_provider.dart';

// Đổi StatefulWidget → ConsumerStatefulWidget
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({required this.onNavigate, super.key});
  final NavigateTo onNavigate;

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

// Đổi State → ConsumerState
class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _repo = TaskRepository();

  Map<String, num>? _progress; // { total, done, percent } của project đang chọn

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProgress());
  }

  Future<void> _loadProgress() async {
    final projectId =
        ref.read(projectProvider).selected?.id ?? '';
    if (projectId.isEmpty) {
      setState(() => _progress = null);
      return;
    }
    try {
      final p = await _repo.getProgress(projectId);
      setState(() {
        _progress = {
          'total':   (p['total']   as num?) ?? 0,
          'done':    (p['done']    as num?) ?? 0,
          'percent': (p['percent'] as num?) ?? 0,
        };
      });
    } catch (_) {
      setState(() => _progress = null); // số liệu thật không lấy được → ẩn
    }
  }

  @override
  Widget build(BuildContext context) {
    // ── Lắng nghe thay đổi dự án đang chọn ──
    ref.listen<String?>(
      projectProvider.select((s) => s.selected?.id),
      (prev, next) {
        if (prev != next) {
          _loadProgress();
        }
      },
    );

    // ── Lắng nghe thay đổi công việc để cập nhật tiến độ tức thì ──
    ref.listen(taskBoardProvider, (_, _) {
      _loadProgress();
    });

    // ── ĐỌC project đang chọn từ provider ──
    final projectState    = ref.watch(projectProvider);
    final unreadCount     = ref.watch(notificationProvider.select((s) => s.unreadCount));
    final projectName     = projectState.selected?.name ??
        'Chưa chọn dự án';
    final projectCount    = projectState.projects.length;
    final repoProgress    = _progress;
    final taskTotal       = repoProgress?['total']   ?? 0;
    final taskDone        = repoProgress?['done']    ?? 0;
    final taskPercent     = repoProgress?['percent'] ?? 0;
    final hasData         = repoProgress != null;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
              sliver: SliverList.list(
                children: [
                  // ── Header: eyebrow hiển thị tên dự án ──
                  ScreenHeader(
                    title:'TEAMWORK XIN CHÀO',
                    eyebrow: projectName.toUpperCase(),    
                    action: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Nút đổi dự án
                        CircleAction(
                          icon: Icons.swap_horiz_rounded,
                          onPressed: () =>
                              widget.onNavigate(AppScreen.projectSelector),
                        ),
                        const SizedBox(width: 8),
                        Badge(
                          isLabelVisible: unreadCount > 0,
                          label: Text('$unreadCount'),
                          child: CircleAction(
                            icon: Icons.notifications_none_rounded,
                            onPressed: () =>
                                widget.onNavigate(AppScreen.notifications),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Focus card: số liệu thật từ progress API ──
                  if (hasData)
                    _FocusCard(
                      done: taskDone,
                      total: taskTotal,
                      percent: taskPercent,
                      onOpenBoard: () {
                        widget.onNavigate(AppScreen.kanbanBoard);
                      },
                    )
                  else
                    _EmptyCard(
                      onChooseProject: () =>
                          widget.onNavigate(AppScreen.projectSelector),
                    ),
                  const SizedBox(height: 12),
                  _MiniStats(
                    tasks: taskTotal,
                    projects: projectCount,
                  ),
                  const SizedBox(height: 28),
                  SectionTitle(
                    eyebrow: 'TẬP TRUNG HOÀN THÀNH',
                    title:   'Việc cần gấp',
                    trailing: TextButton(
                      onPressed: () =>
                          widget.onNavigate(AppScreen.timeline),
                      child: const Text('Xem tất cả'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Danh sách việc cần gấp: lấy từ tasks thật (done < total)
                  _UrgentTasks(
                    projectId: projectState.selected?.id ?? '',
                    onNavigate: widget.onNavigate,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        active:     AppScreen.dashboard,
        onNavigate: widget.onNavigate,
      ),
    );
  }
}

// ── Focus card — số liệu thật từ /tasks/project/:id/progress ──
class _FocusCard extends StatelessWidget {
  const _FocusCard({
    required this.done,
    required this.total,
    required this.percent,
    required this.onOpenBoard,
  });

  final num done;
  final num total;
  final num percent;
  final VoidCallback onOpenBoard;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 212,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.black, size: 14),
                      SizedBox(width: 5),
                      Text(
                        'MỤC TIÊU HÔM NAY',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Bạn đang đạt\ntiến độ rất tốt.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    height: 1.12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Đã hoàn thành ${done.toInt()}/${total.toInt()} công việc',
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: onOpenBoard,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    minimumSize: const Size(136, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text(
                    'Xem tất cả công việc',
                    style: TextStyle(fontSize: 9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 103,
            height: 103,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: (percent / 100).clamp(0.0, 1.0).toDouble(),
                    strokeWidth: 9,
                    color: Colors.white,
                    backgroundColor: Colors.white24,
                  ),
                ),
                Text(
                  '${percent.toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty card — chưa chọn dự án / chưa có dữ liệu ──
class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.onChooseProject});

  final VoidCallback onChooseProject;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chưa có dữ liệu',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Chọn một dự án để xem tiến độ công việc.',
            style: TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onChooseProject,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              minimumSize: const Size(150, 40),
            ),
            child: const Text('Chọn dự án'),
          ),
        ],
      ),
    );
  }
}

// ── Mini stats — chỉ hiển thị số thật có được từ API ──
class _MiniStats extends StatelessWidget {
  const _MiniStats({required this.tasks, required this.projects});

  final num tasks;
  final int projects;

  @override
  Widget build(BuildContext context) {
    final stats = [
      ('${tasks.toInt()}', 'Công việc', 'Trong dự án', AppColors.accent),
      ('$projects', 'Dự án', 'Đang hoạt động', AppColors.charcoal),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            for (final (index, stat) in stats.indexed) ...[
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 31,
                      height: 31,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: stat.$4, width: 4),
                      ),
                      child: Text(
                        stat.$1,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stat.$2,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          stat.$3,
                          style: const TextStyle(
                            color: AppColors.soft,
                            fontSize: 7,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (index < stats.length - 1)
                const SizedBox(
                  height: 32,
                  child: VerticalDivider(width: 1),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Việc cần gấp — tasks thật chưa done, ưu tiên dueDate gần ──
class _UrgentTasks extends ConsumerStatefulWidget {
  const _UrgentTasks({required this.projectId, required this.onNavigate});

  final String projectId;
  final NavigateTo onNavigate;

  @override
  ConsumerState<_UrgentTasks> createState() => _UrgentTasksState();
}

class _UrgentTasksState extends ConsumerState<_UrgentTasks> {
  final _repo = TaskRepository();
  List<TaskModel> _tasks = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_UrgentTasks oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectId != widget.projectId) _load();
  }

  Future<void> _load() async {
    if (widget.projectId.isEmpty) {
      setState(() => _tasks = const []);
      return;
    }
    try {
      final board = await _repo.getBoard(widget.projectId);
      // Quá hạn lên đầu, sau đó theo hạn gần nhất; không có hạn xếp cuối.
      final all = [...board.todo, ...board.doing]..sort((a, b) {
          if (a.isOverdue != b.isOverdue) return a.isOverdue ? -1 : 1;
          return (a.dueDate ?? DateTime(2100)).compareTo(b.dueDate ?? DateTime(2100));
        });
      setState(() => _tasks = all.take(3).toList());
    } catch (_) {
      setState(() => _tasks = const []);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(taskBoardProvider, (_, _) => _load());

    if (_tasks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Không có việc nào đang chờ xử lý.',
          style: TextStyle(color: AppColors.muted, fontSize: 11),
        ),
      );
    }
    return Column(
      children: [
        for (final task in _tasks)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _TaskRow(
              title: task.title,
              project: widget.projectId,
              time: task.dueDateLabel ?? '',
              tag: task.isOverdue ? 'QUÁ HẠN' : task.status,
              completed: task.status == 'done',
              onToggle: () => widget.onNavigate(AppScreen.kanbanBoard),
            ),
          ),
      ],
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.title,
    required this.project,
    required this.time,
    required this.tag,
    required this.completed,
    required this.onToggle,
  });

  final String title;
  final String project;
  final String time;
  final String tag;
  final bool completed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: completed ? .45 : 1,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              InkWell(
                onTap: onToggle,
                borderRadius: BorderRadius.circular(7),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: completed ? AppColors.accent : Colors.transparent,
                    border: Border.all(
                      color: completed ? AppColors.accent : AppColors.line,
                    ),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: completed
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tag,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 7,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        decoration:
                            completed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    Text(
                      project,
                      style: const TextStyle(
                        color: AppColors.soft,
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.schedule_rounded, size: 14, color: AppColors.muted),
              const SizedBox(width: 4),
              Text(
                time,
                style: const TextStyle(color: AppColors.muted, fontSize: 8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
