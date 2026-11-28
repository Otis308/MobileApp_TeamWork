import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/workflow_widgets.dart';
import '../../project/presentation/project_provider.dart';
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
  String? _currentUserId;
  // Mốc thời gian của bản task đã nạp vào các ô nhập — dùng để phát hiện khi
  // người khác sửa task này trong lúc màn hình đang mở (xem build()).
  DateTime? _syncedUpdatedAt;

  @override
  void initState() {
    super.initState();
    ref.read(sessionServiceProvider).getUserId().then((id) {
      if (mounted) setState(() => _currentUserId = id);
    });
    Future.microtask(
      () => ref.read(taskCommentsProvider(widget.taskId).notifier).load(),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // Mô hình mở (giống Trello): mọi thành viên dự án đều sửa được task.
  // Riêng XÓA thì chỉ Quản trị viên hoặc chính người tạo task — phản chiếu luật
  // thật ở TasksService (server vẫn là nơi thực thi).
  bool _canDelete(TaskModel task) {
    final uid = _currentUserId;
    if (uid == null) return false;
    final projectId = ref.read(kanbanTargetProvider).projectId;
    final myRole = ref
        .watch(projectProvider)
        .projects
        .where((p) => p.id == projectId)
        .firstOrNull
        ?.role;
    final isCreator = task.createdById != null && task.createdById == uid;
    return isCreator || myRole == 'Admin';
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
    _syncedUpdatedAt = task.updatedAt;
  }

  // Gửi lên server: server cần đúng 'yyyy-MM-dd', không đổi theo locale hiển thị.
  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  // Hiển thị cho người dùng — 'dd/MM/yyyy'.
  static String _vnDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';

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
    // Nạp lại các ô nhập khi mở lần đầu, HOẶC khi server báo task đã đổi
    // (người khác vừa lưu) — để màn hình luôn khớp dữ liệu mới nhất, không
    // cần người dùng tự đóng mở lại. Đánh đổi: nếu đang gõ dở mà có người
    // khác lưu đúng lúc đó, phần đang gõ sẽ bị ghi đè — chấp nhận được vì
    // ưu tiên không bao giờ hiển thị dữ liệu cũ.
    if (!_loaded || _syncedUpdatedAt != task.updatedAt) _fillFrom(task);
    final canDelete = _canDelete(task);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết công việc'),
        actions: [
          IconButton(
            tooltip: 'Xóa',
            icon: Icon(Icons.delete_outline,
                color: canDelete ? Colors.red : AppColors.soft),
            onPressed: canDelete ? () => _delete(task) : null,
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
                  label: Text(_dueDate == null ? 'Chọn ngày' : _vnDate(_dueDate!)),
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
                    ? 'Hạn nộp: cả ngày ${_vnDate(_dueDate!)}'
                    : 'Hạn nộp: ${_two(_dueTime!.hour)}:${_two(_dueTime!.minute)} ngày '
                        '${_vnDate(_dueDate!)}',
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
            const SizedBox(height: 28),
            const _Label('BÌNH LUẬN'),
            _CommentsSection(taskId: task.id, currentUserId: _currentUserId),
          ],
        ),
      ),
    );
  }
}

class _CommentsSection extends ConsumerStatefulWidget {
  const _CommentsSection({required this.taskId, required this.currentUserId});
  final String taskId;
  final String? currentUserId;

  @override
  ConsumerState<_CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends ConsumerState<_CommentsSection> {
  final _ctrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final content = _ctrl.text.trim();
    if (content.isEmpty) return;
    setState(() => _sending = true);
    final error =
        await ref.read(taskCommentsProvider(widget.taskId).notifier).add(content);
    if (!mounted) return;
    setState(() => _sending = false);
    if (error == null) {
      _ctrl.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $error'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _delete(String commentId) async {
    final error = await ref
        .read(taskCommentsProvider(widget.taskId).notifier)
        .remove(commentId);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $error'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(taskCommentsProvider(widget.taskId));
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.isLoading && state.comments.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (state.comments.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Chưa có bình luận nào',
                style: TextStyle(color: AppColors.muted, fontSize: 12)),
          )
        else
          for (final c in state.comments)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MemberAvatar(name: c.author?.fullName ?? '?', size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  c.author?.fullName.isNotEmpty == true
                                      ? c.author!.fullName
                                      : 'Người dùng',
                                  style: const TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                              ),
                              Text(
                                dateFmt.format(c.createdAt.toLocal()),
                                style: const TextStyle(
                                    color: AppColors.soft, fontSize: 9),
                              ),
                              if (widget.currentUserId != null &&
                                  c.author?.id == widget.currentUserId)
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(Icons.close_rounded,
                                      size: 16, color: AppColors.soft),
                                  onPressed: () => _delete(c.id),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(c.content,
                              style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                decoration: const InputDecoration(hintText: 'Viết bình luận…'),
                minLines: 1,
                maxLines: 3,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ],
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
