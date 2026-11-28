// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TaskAssignee _$TaskAssigneeFromJson(Map<String, dynamic> json) =>
    _TaskAssignee(
      id: json['_id'] as String,
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
    );

Map<String, dynamic> _$TaskAssigneeToJson(_TaskAssignee instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'fullName': instance.fullName,
      'email': instance.email,
      'avatarUrl': instance.avatarUrl,
    };

_TaskModel _$TaskModelFromJson(Map<String, dynamic> json) => _TaskModel(
  id: json['_id'] as String,
  title: json['title'] as String,
  description: json['description'] as String? ?? '',
  status: json['status'] as String? ?? 'todo',
  priority: json['priority'] as String? ?? 'medium',
  assignee: _readAssignee(json, 'assigneeId') == null
      ? null
      : TaskAssignee.fromJson(
          _readAssignee(json, 'assigneeId') as Map<String, dynamic>,
        ),
  createdById: _readCreatedById(json, 'createdBy') as String?,
  dueDate: json['dueDate'] == null
      ? null
      : DateTime.parse(json['dueDate'] as String),
  dueHasTime: json['dueHasTime'] as bool? ?? false,
  order: (json['order'] as num?)?.toInt() ?? 0,
  isOverdue: json['isOverdue'] as bool? ?? false,
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$TaskModelToJson(_TaskModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'status': instance.status,
      'priority': instance.priority,
      'assigneeId': instance.assignee,
      'createdBy': instance.createdById,
      'dueDate': instance.dueDate?.toIso8601String(),
      'dueHasTime': instance.dueHasTime,
      'order': instance.order,
      'isOverdue': instance.isOverdue,
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
