import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_model.freezed.dart';
part 'task_model.g.dart';

// assigneeId là object khi server populate, là chuỗi id (hoặc null) khi không.
Object? _readAssignee(Map json, String key) {
  final v = json[key];
  return v is Map ? Map<String, dynamic>.from(v) : null;
}

// createdBy là object khi server populate ({_id, fullName}) — chỉ cần lấy id
// để so sánh với người dùng hiện tại (quyền sửa/xóa).
Object? _readCreatedById(Map json, String key) {
  final v = json[key];
  if (v is Map) return v['_id']?.toString();
  if (v is String) return v;
  return null;
}

@freezed
abstract class TaskAssignee with _$TaskAssignee {
  const factory TaskAssignee({
    @JsonKey(name: '_id') required String id,
    @Default('') String fullName,
    @Default('') String email,
    @Default('') String avatarUrl,
  }) = _TaskAssignee;

  factory TaskAssignee.fromJson(Map<String, dynamic> json) =>
      _$TaskAssigneeFromJson(json);
}

@freezed
abstract class TaskModel with _$TaskModel {
  const TaskModel._();

  const factory TaskModel({
    @JsonKey(name: '_id') required String id,
    required String title,
    @Default('') String description,
    @Default('todo') String status,
    @Default('medium') String priority,
    @JsonKey(name: 'assigneeId', readValue: _readAssignee) TaskAssignee? assignee,
    @JsonKey(name: 'createdBy', readValue: _readCreatedById) String? createdById,
    DateTime? dueDate,
    @Default(false) bool dueHasTime,
    @Default(0) int order,
    @Default(false) bool isOverdue,
    DateTime? updatedAt,
  }) = _TaskModel;

  factory TaskModel.fromJson(Map<String, dynamic> json) =>
      _$TaskModelFromJson(json);

  static String _two(int n) => n.toString().padLeft(2, '0');

  // Ngày lịch của hạn: task chỉ có ngày lưu ở UTC nửa đêm (đọc theo UTC để không lệch ngày);
  // task có giờ là một thời điểm nên đọc theo giờ địa phương. Trả về 00:00 UTC của ngày đó.
  DateTime? get dueDayKey {
    final d = dueDate;
    if (d == null) return null;
    final x = dueHasTime ? d.toLocal() : d.toUtc();
    return DateTime.utc(x.year, x.month, x.day);
  }

  // Giờ hạn theo giờ địa phương 'HH:mm' (null nếu task chỉ có ngày).
  String? get dueTimeLabel {
    if (dueDate == null || !dueHasTime) return null;
    final l = dueDate!.toLocal();
    return '${_two(l.hour)}:${_two(l.minute)}';
  }

  // 'dd/MM/yyyy' hoặc 'dd/MM/yyyy HH:mm' để hiển thị.
  String? get dueDateLabel {
    final day = dueDayKey;
    if (day == null) return null;
    final date = '${_two(day.day)}/${_two(day.month)}/${day.year}';
    final time = dueTimeLabel;
    return time == null ? date : '$date $time';
  }
}
