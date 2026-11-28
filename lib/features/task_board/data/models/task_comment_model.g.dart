// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_comment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TaskCommentAuthor _$TaskCommentAuthorFromJson(Map<String, dynamic> json) =>
    _TaskCommentAuthor(
      id: json['_id'] as String,
      fullName: json['fullName'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
    );

Map<String, dynamic> _$TaskCommentAuthorToJson(_TaskCommentAuthor instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'fullName': instance.fullName,
      'avatarUrl': instance.avatarUrl,
    };

_TaskCommentModel _$TaskCommentModelFromJson(Map<String, dynamic> json) =>
    _TaskCommentModel(
      id: json['_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      author: _readAuthor(json, 'userId') == null
          ? null
          : TaskCommentAuthor.fromJson(
              _readAuthor(json, 'userId') as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$TaskCommentModelToJson(_TaskCommentModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'content': instance.content,
      'createdAt': instance.createdAt.toIso8601String(),
      'userId': instance.author,
    };
