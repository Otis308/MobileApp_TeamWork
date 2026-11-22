import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/workflow_widgets.dart';
import '../../team/presentation/team_provider.dart';
import '../data/models/task_model.dart';
import 'task_provider.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  const TaskDetailScreen({required this.taskId, super.key});
  final String taskId;

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _priority = 'medium';
  String? _assigneeId;
  DateTime? _dueDate; // chỉ phần ngày (năm/tháng/ngày)
  TimeOfDay? _dueTime; // null = cả ngày
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _fillFrom(TaskModel task) {
    _titleCtrl.text = task.title;
    _descCtrl.text = task.description;
    _priority = task.priority;
    _assigneeId = task.assignee?.id;
    final due = task.dueDate;
    if (due == null) {
      _dueDate = null;
      _dueTime = null;
    } else if (task.dueHasTime) {
      final l = due.toLocal();
      _dueDate = DateTime(l.year, l.month, l.day);
      _dueTime = TimeOfDay(hour: l.hour, minute: l.minute);
    } else {
      final u = due.toUtc();
      _dueDate = DateTime(u.year, u.month, u.day);
      _dueTime = null;
    }
    _loaded = true;
  }

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  // Chuỗi gửi lên server: có giờ → thời điểm UTC đầy đủ, không giờ → chỉ ngày.
  static String? _duePayload(DateTime? date, TimeOfDay? time) {
    if (date == null) return null;
    if (time == null) return _isoDate(date);
    return DateTime(date.year, date.month, date.day, time.hour, time.minute)
        .toUtc()
        .toIso8601String();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? const TimeOfDay(hour: 17, minute: 0),
      helpText: 'Chọn giờ hạn nộp',
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dueTime = picked);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _save(TaskModel task) async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      _snack('Tiêu đề không được để trống', error: true);
      return;
    }
    setState(() => _saving = true);
    final original = _TaskDue.of(task);
    final newDue = _duePayload(_dueDate, _dueTime);
    final dueChanged = newDue != original;

    final error = await ref.read(taskBoardProvider.notifier).updateTask(
          task.id,
          title: title,
          description: _descCtrl.text,
          priority: _priority,
          assigneeId: _assigneeId != task.assignee?.id ? _assigneeId : null,
          clearAssignee: _assigneeId == null && task.assignee != null,
          dueDate: dueChanged ? newDue : null,
          dueHasTime: _dueTime != null,
          clearDueDate: dueChanged && newDue == null,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (error == null) {
      _snack('Đã lưu');
      Navigator.of(context).pop();
    } else {
      _snack('Lỗi: $error', error: true);
    }
  }

  Future<void> _changeStatus(TaskModel task, String status) async {
    if (status == task.status) return;
    final end = ref.read(taskBoardProvider).column(status).length;
    final error =
        await ref.read(taskBoardProvider.notifier).moveTask(task.id, status, end);
    if (error != null) _snack('Lỗi: $error', error: true);
  }

  Future<void> _delete(TaskModel task) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa công việc'),
        content: Text('Xóa "${task.title}" khỏi bảng?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final error = await ref.read(taskBoardProvider.notifier).deleteTask(task.id);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
    } else {
      _snack('Lỗi: $error', error: true);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: error ? Colors.red : Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final task = ref.watch(taskBoardProvider.select((s) => s.findById(widget.taskId)));
    final members = ref.watch(teamProvider).members;

    if (task == null) {
      // Task đã bị xóa (ví dụ bởi người khác) hoặc bảng chưa tải xong.
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Công việc không còn tồn tại')),
      );
    }
    if (!_loaded) _fillFrom(task);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết công việc'),
        actions: [
          IconButton(
            tooltip: 'Xóa',
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _delete(task),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Tên công việc *',
                prefixIcon: Icon(Icons.task_alt_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Mô tả',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
            const SizedBox(height: 20),
            const _Label('TRẠNG THÁI'),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'todo', label: Text('Cần làm')),
                ButtonSegment(value: 'doing', label: Text('Đang làm')),
                ButtonSegment(value: 'done', label: Text('Xong')),
              ],
              selected: {task.status},
              onSelectionChanged: (v) => _changeStatus(task, v.first),
            ),
            const SizedBox(height: 20),
            const _Label('ĐỘ ƯU TIÊN'),
            Wrap(
              spacing: 8,
              children: [
                for (final (value, label) in const [
                  ('high', 'Cao'),
                  ('medium', 'Trung bình'),
                  ('low', 'Thấp'),
                ])
                  ChoiceChip(
                    label: Text(label),
                    selected: _priority == value,
                    onSelected: (_) => setState(() => _priority = value),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const _Label('HẠN HOÀN THÀNH'),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today_outlined, size: 16),
                  label: Text(_dueDate == null ? 'Chọn ngày' : _isoDate(_dueDate!)),
                ),
                if (_dueDate != null)
                  IconButton(
                    tooltip: 'Bỏ hạn',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => setState(() {
                      _dueDate = null;
                      _dueTime = null;
                    }),
                  ),
              ],
            ),
            if (_dueDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule_rounded, size: 16),
                    label: Text(_dueTime == null
                        ? 'Thêm giờ nộp'
                        : '${_two(_dueTime!.hour)}:${_two(_dueTime!.minute)}'),
                  ),
                  if (_dueTime != null)
                    IconButton(
                      tooltip: 'Bỏ giờ (cả ngày)',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => setState(() => _dueTime = null),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _dueTime == null
                    ? 'Hạn nộp: cả ngày ${_two(_dueDate!.day)}/${_two(_dueDate!.month)}/${_dueDate!.year}'
                    : 'Hạn nộp: ${_two(_dueTime!.hour)}:${_two(_dueTime!.minute)} ngày '
                        '${_two(_dueDate!.day)}/${_two(_dueDate!.month)}/${_dueDate!.year}',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
            const SizedBox(height: 20),
            const _Label('NGƯỜI PHỤ TRÁCH'),
            if (members.isEmpty)
              const Text('Dự án chưa có thành viên',
                  style: TextStyle(color: AppColors.muted, fontSize: 12))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in members)
                    _AssigneeChip(
                      name: m.name,
                      selected: _assigneeId == m.id,
                      onTap: () => setState(() {
                        final id = m.id;
                        _assigneeId = _assigneeId == id ? null : id;
                      }),
                    ),
                ],
              ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _saving ? null : () => _save(task),
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check_rounded),
              label: const Text('Lưu thay đổi'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: AppColors.muted,
            letterSpacing: 1.2,
          ),
        ),
      );
}

class _AssigneeChip extends StatelessWidget {
  const _AssigneeChip({
    required this.name,
    required this.selected,
    required this.onTap,
  });
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : AppColors.background,
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
                fontSize: 11,
                color: selected ? Colors.white : AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Chuỗi hạn của task theo cùng định dạng với payload gửi server, để biết người dùng có đổi hạn không.
class _TaskDue {
  static String? of(TaskModel task) {
    final due = task.dueDate;
    if (due == null) return null;
    if (!task.dueHasTime) {
      final u = due.toUtc();
      return '${u.year.toString().padLeft(4, '0')}-${u.month.toString().padLeft(2, '0')}-${u.day.toString().padLeft(2, '0')}';
    }
    return due.toUtc().toIso8601String();
  }
}
