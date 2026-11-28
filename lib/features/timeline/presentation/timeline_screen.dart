import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/workflow_widgets.dart';
import '../../project/presentation/project_provider.dart';
import 'timeline_provider.dart';

const _overdueColor = Color(0xFFD64545);

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({required this.onNavigate, super.key});

  final NavigateTo onNavigate;

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  static const _weekdayLabels = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(timelineProvider.notifier)
          .setProject(ref.read(projectProvider).selected?.id ?? '');
    });
  }

  String _dayLabel(DateTime d) => _weekdayLabels[d.weekday % 7];

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    // Đổi dự án đang chọn → tải lại lịch của dự án mới.
    ref.listen(projectProvider.select((s) => s.selected?.id), (_, next) {
      ref.read(timelineProvider.notifier).setProject(next ?? '');
    });

    final state = ref.watch(timelineProvider);
    final controller = ref.read(timelineProvider.notifier);
    final hasProject = ref.watch(projectProvider).selected?.id != null;
    final selectedDay = state.selectedDay;
    final tasks = state.visibleTasks;
    final overdueMode = state.mode == TimelineMode.overdue;
    final today = todayKey();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              sliver: SliverToBoxAdapter(
                child: ScreenHeader(
                  title: 'Lịch làm việc',
                  eyebrow: 'THÁNG ${selectedDay.month}, ${selectedDay.year}',
                  action: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAction(
                        icon: Icons.today_rounded,
                        onPressed: controller.goToToday,
                      ),
                      const SizedBox(width: 8),
                      CircleAction(
                        icon: Icons.refresh_rounded,
                        onPressed: state.isLoading ? () {} : controller.refresh,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 20, 6, 12),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Tuần trước',
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: () => controller.shiftWeek(-1),
                    ),
                    for (final day in state.days)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: _DayButton(
                            day: _dayLabel(day),
                            date: day.day.toString(),
                            selected: !overdueMode && day == selectedDay,
                            isToday: day == today,
                            hasEvent: state.hasTasksOn(day),
                            onTap: () => controller.selectDay(day),
                          ),
                        ),
                      ),
                    IconButton(
                      tooltip: 'Tuần sau',
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: () => controller.shiftWeek(1),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Theo ngày'),
                      selected: !overdueMode,
                      onSelected: (_) => controller.setMode(TimelineMode.day),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      avatar: Icon(Icons.warning_amber_rounded,
                          size: 16,
                          color: overdueMode ? Colors.white : _overdueColor),
                      label: Text('Quá hạn (${state.overdueTasks.length})'),
                      selected: overdueMode,
                      selectedColor: _overdueColor,
                      labelStyle: TextStyle(
                        color: overdueMode
                            ? Colors.white
                            : (state.overdueTasks.isEmpty
                                ? AppColors.ink
                                : _overdueColor),
                      ),
                      onSelected: (_) => controller.setMode(TimelineMode.overdue),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: Divider(height: 1)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
              sliver: SliverToBoxAdapter(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Eyebrow(overdueMode
                              ? 'QUÁ HẠN'
                              : 'NGÀY ${selectedDay.day} THÁNG ${selectedDay.month}'),
                          const SizedBox(height: 4),
                          Text(
                            overdueMode ? 'Việc cần xử lý gấp' : 'Lịch trình của bạn',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${tasks.length} ',
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const TextSpan(
                            text: 'công việc',
                            style: TextStyle(color: AppColors.muted, fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: state.isLoading
                  ? const SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator()))
                  : state.error != null
                      ? SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline, size: 32),
                                const SizedBox(height: 8),
                                Text('Lỗi: ${state.error}'),
                                const SizedBox(height: 12),
                                FilledButton(
                                  onPressed: controller.refresh,
                                  child: const Text('Thử lại'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : tasks.isEmpty
                          ? SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                child: Text(
                                  !hasProject
                                      ? 'Chưa chọn dự án'
                                      : overdueMode
                                          ? 'Không có công việc nào quá hạn'
                                          : 'Không có công việc nào đến hạn ngày này',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: AppColors.muted, fontSize: 12),
                                ),
                              ),
                            )
                          : SliverList.builder(
                              itemCount: tasks.length,
                              itemBuilder: (context, index) {
                                final task = tasks[index];
                                final urgent = task.priority == 'high';
                                final overdue = task.isOverdue;
                                final due = task.dueDayKey;
                                final daysLate = due == null
                                    ? 0
                                    : today.difference(dayKey(due)).inDays;
                                final assignee = task.assignee?.fullName ??
                                    task.assignee?.email ??
                                    '';
                                return _TimelineItem(
                                  time: overdueMode && due != null
                                      ? '${_two(due.day)}/${_two(due.month)}'
                                      : (task.dueTimeLabel ?? 'CẢ NGÀY'),
                                  duration: task.status == 'done'
                                      ? 'HOÀN THÀNH'
                                      : overdue
                                          ? 'QUÁ $daysLate NGÀY'
                                          : vietnameseStatusLabel(task.status)
                                              .toUpperCase(),
                                  title: task.title,
                                  detail: assignee.isEmpty
                                      ? 'Chưa giao cho ai'
                                      : 'Giao cho $assignee',
                                  type: overdue
                                      ? 'QUÁ HẠN'
                                      : urgent
                                          ? 'ƯU TIÊN CAO'
                                          : 'CÔNG VIỆC',
                                  urgent: urgent,
                                  overdue: overdue,
                                  isLast: index == tasks.length - 1,
                                  assigneeName: assignee.isEmpty ? null : assignee,
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        active: AppScreen.timeline,
        onNavigate: widget.onNavigate,
      ),
    );
  }
}

class _DayButton extends StatelessWidget {
  const _DayButton({
    required this.day,
    required this.date,
    required this.selected,
    required this.isToday,
    required this.hasEvent,
    required this.onTap,
  });

  final String day;
  final String date;
  final bool selected;
  final bool isToday;
  final bool hasEvent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 62,
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: isToday && !selected
              ? Border.all(color: AppColors.accent, width: 1.2)
              : null,
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x33FF634A),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              day,
              style: TextStyle(
                color: selected ? Colors.white70 : AppColors.soft,
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              date,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (hasEvent)
              Container(
                width: 3,
                height: 3,
                margin: const EdgeInsets.only(top: 5),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.time,
    required this.duration,
    required this.title,
    required this.detail,
    required this.type,
    required this.urgent,
    required this.overdue,
    required this.isLast,
    required this.assigneeName,
  });

  final String time;
  final String duration;
  final String title;
  final String detail;
  final String type;
  final bool urgent;
  final bool overdue;
  final bool isLast;
  final String? assigneeName;

  @override
  Widget build(BuildContext context) {
    final highlight = overdue ? _overdueColor : (urgent ? AppColors.accent : null);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 47,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  duration,
                  style: TextStyle(
                    color: highlight ?? AppColors.soft,
                    fontSize: 6,
                    fontWeight:
                        highlight != null ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 18,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: highlight ?? AppColors.ink,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.background, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: highlight ?? AppColors.ink,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  const Expanded(
                    child: VerticalDivider(width: 1, color: AppColors.line),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: highlight ?? AppColors.line,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type,
                          style: TextStyle(
                            color: highlight ?? AppColors.muted,
                            fontSize: 7,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .5,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          detail,
                          style: const TextStyle(
                            color: AppColors.soft,
                            fontSize: 8,
                          ),
                        ),
                        if (assigneeName != null) ...[
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              MemberAvatar(name: assigneeName!, size: 25),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
