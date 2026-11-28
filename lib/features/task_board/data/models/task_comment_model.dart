import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_comment_model.freezed.dart';
part 'task_comment_model.g.dart';

// userId là object khi server populate (_id, fullName, avatarUrl).
Object? _readAuthor(Map json, String key) {
  final v = json[key];
  return v is Map ? Map<String, dynamic>.from(v) : null;
}

@freezed
abstract class TaskCommentAuthor with _$TaskCommentAuthor {
  const factory TaskCommentAuthor({
    @JsonKey(name: '_id') required String id,
    @Default('') String fullName,
    @Default('') String avatarUrl,
  }) = _TaskCommentAuthor;

  factory TaskCommentAuthor.fromJson(Map<String, dynamic> json) =>
      _$TaskCommentAuthorFromJson(json);
}

@freezed
abstract class TaskCommentModel with _$TaskCommentModel {
  const factory TaskCommentModel({
    @JsonKey(name: '_id') required String id,
    required String content,
    required DateTime createdAt,
    @JsonKey(name: 'userId', readValue: _readAuthor) TaskCommentAuthor? author,
  }) = _TaskCommentModel;

  factory TaskCommentModel.fromJson(Map<String, dynamic> json) =>
      _$TaskCommentModelFromJson(json);
}
