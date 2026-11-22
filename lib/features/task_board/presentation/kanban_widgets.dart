import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/workflow_widgets.dart';
import '../data/models/task_model.dart';

const kKanbanColumnWidth = 280.0;

class KanbanColumnView extends StatefulWidget {
  const KanbanColumnView({
    required this.status,
    required this.title,
    required this.color,
    required this.tasks,
    required this.pointer,
    required this.scrollController,
    required this.onDropped,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onOpenTask,
    required this.onTapAssignee,
    required this.onDeleteTask,
    required this.onAddTask,
    super.key,
  });

  final String status;
  final String title;
  final Color color;
  final List<TaskModel> tasks;
  final ValueNotifier<Offset?> pointer;
  final ScrollController scrollController;
  final void Function(TaskModel task, int targetIndex) onDropped;
  final VoidCallback onDragStart;
  final ValueChanged<Offset> onDragUpdate;
  final VoidCallback onDragEnd;
  final ValueChanged<TaskModel> onOpenTask;
  final ValueChanged<TaskModel> onTapAssignee;
  final ValueChanged<TaskModel> onDeleteTask;
  final VoidCallback onAddTask;

  @override
  State<KanbanColumnView> createState() => _KanbanColumnViewState();
}

class _KanbanColumnViewState extends State<KanbanColumnView> {
  final Map<String, GlobalKey> _cardKeys = {};
  int? _hoverIndex;
  String? _draggingId;

  GlobalKey _keyFor(String id) => _cardKeys.putIfAbsent(id, GlobalKey.new);

  // Vị trí chèn = số thẻ (không tính thẻ đang kéo) có tâm nằm phía trên con trỏ.
  int _indexFor(Offset pointer, String draggingId) {
    var index = 0;
    for (final t in widget.tasks) {
      if (t.id == draggingId) continue;
      final box = _cardKeys[t.id]?.currentContext?.findRenderObject();
      if (box is RenderBox && box.attached) {
        final centerY = box.localToGlobal(box.size.center(Offset.zero)).dy;
        if (pointer.dy < centerY) return index;
      }
      index++;
    }
    return index;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: kKanbanColumnWidth,
      child: Column(
        children: [
          _ColumnHeader(
            title: widget.title,
            count: widget.tasks.length,
            color: widget.color,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: DragTarget<TaskModel>(
              onWillAcceptWithDetails: (_) => true,
              onMove: (details) {
                final p = widget.pointer.value;
                if (p == null) return;
                final index = _indexFor(p, details.data.id);
                if (index != _hoverIndex) setState(() => _hoverIndex = index);
              },
              onLeave: (_) => setState(() => _hoverIndex = null),
              onAcceptWithDetails: (details) {
                final p = widget.pointer.value;
                final index = p == null
                    ? widget.tasks.where((t) => t.id != details.data.id).length
                    : _indexFor(p, details.data.id);
                setState(() => _hoverIndex = null);
                widget.onDropped(details.data, index);
              },
              builder: (context, candidates, _) =>
                  _buildList(candidates.isNotEmpty),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onAddTask,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Thêm công việc'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.muted,
                side: const BorderSide(color: AppColors.line),
              ),
            ),
          ),
          const SizedBox(height: 90),
        ],
      ),
    );
  }

  Widget _buildList(bool dragOver) {
    final hover = dragOver ? _hoverIndex : null;
    final children = <Widget>[];
    var slot = 0;
    for (final task in widget.tasks) {
      if (hover == slot && !_isDragging(task)) children.add(const _DropLine());
      children.add(
        Padding(
          key: _keyFor(task.id),
          padding: const EdgeInsets.only(bottom: 9),
          child: LongPressDraggable<TaskModel>(
            data: task,
            delay: const Duration(milliseconds: 220),
            onDragStarted: () {
              _draggingId = task.id;
              widget.onDragStart();
            },
            onDragUpdate: (d) => widget.onDragUpdate(d.globalPosition),
            onDragEnd: (_) {
              _draggingId = null;
              widget.onDragEnd();
            },
            feedback: Material(
              color: Colors.transparent,
              child: SizedBox(
                width: kKanbanColumnWidth,
                child: Transform.rotate(
                  angle: 0.02,
                  child: KanbanCard(
                    task: task,
                    elevated: true,
                    onTap: () {},
                    onTapAssignee: () {},
                    onDelete: () {},
                  ),
                ),
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.3,
              child: KanbanCard(
                task: task,
                onTap: () {},
                onTapAssignee: () {},
                onDelete: () {},
              ),
            ),
            child: KanbanCard(
              task: task,
              onTap: () => widget.onOpenTask(task),
              onTapAssignee: () => widget.onTapAssignee(task),
              onDelete: () => widget.onDeleteTask(task),
            ),
          ),
        ),
      );
      if (!_isDragging(task)) slot++;
    }
    if (hover != null && hover >= slot) children.add(const _DropLine());

    return Container(
      decoration: BoxDecoration(
        color: dragOver ? widget.color.withValues(alpha: 0.06) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.only(bottom: 12),
        children: children.isEmpty
            ? [const SizedBox(height: 120)]
            : children,
      ),
    );
  }

  // Thẻ đang được kéo vẫn nằm trong cây widget (mờ đi) nên không tính vào chỉ số chèn.
  bool _isDragging(TaskModel task) => _draggingId == task.id;
}

class _DropLine extends StatelessWidget {
  const _DropLine();

  @override
  Widget build(BuildContext context) => Container(
        height: 3,
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(2),
        ),
      );
}

class _ColumnHeader extends StatelessWidget {
  const _ColumnHeader({
    required this.title,
    required this.count,
    required this.color,
  });

  final String title;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: 7),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('$count', style: const TextStyle(fontSize: 8)),
        ),
      ],
    );
  }
}

class KanbanCard extends StatelessWidget {
  const KanbanCard({
    required this.task,
    required this.onTap,
    required this.onTapAssignee,
    required this.onDelete,
    this.elevated = false,
    super.key,
  });

  final TaskModel task;
  final VoidCallback onTap;
  final VoidCallback onTapAssignee;
  final VoidCallback onDelete;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final assigneeName = task.assignee?.fullName ?? '';
    final due = task.dueDateLabel;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: AppColors.line),
          boxShadow: elevated
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCEDDEA),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    task.priority.toUpperCase(),
                    style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w800),
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, size: 19, color: AppColors.soft),
                  onSelected: (value) {
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'delete', child: Text('Xóa công việc')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              task.title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 21),
            Row(
              children: [
                GestureDetector(
                  onTap: onTapAssignee,
                  child: assigneeName.isNotEmpty
                      ? MemberAvatar(name: assigneeName, size: 26)
                      : Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.line),
                          ),
                          child: const Icon(Icons.person_add_alt,
                              size: 14, color: AppColors.soft),
                        ),
                ),
                const Spacer(),
                if (due != null) ...[
                  const Icon(Icons.calendar_today_outlined,
                      size: 13, color: AppColors.muted),
                  const SizedBox(width: 5),
                  Text(
                    due,
                    style: const TextStyle(color: AppColors.muted, fontSize: 8),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
