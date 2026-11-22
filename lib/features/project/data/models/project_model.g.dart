// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProjectModel _$ProjectModelFromJson(Map<String, dynamic> json) =>
    _ProjectModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      role: json['role'] as String? ?? 'Member',
      taskTotal: (json['taskTotal'] as num?)?.toInt() ?? 0,
      taskDone: (json['taskDone'] as num?)?.toInt() ?? 0,
      progress: (json['progress'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ProjectModelToJson(_ProjectModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'role': instance.role,
      'taskTotal': instance.taskTotal,
      'taskDone': instance.taskDone,
      'progress': instance.progress,
    };
