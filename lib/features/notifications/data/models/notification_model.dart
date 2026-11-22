import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_model.freezed.dart';
part 'notification_model.g.dart';

// REST trả `_id`, còn payload Socket.IO trả `id`.
Object? _readId(Map json, String key) => (json['_id'] ?? json['id'])?.toString();

@freezed
abstract class NotificationModel with _$NotificationModel {
  const factory NotificationModel({
    @JsonKey(readValue: _readId) required String id,
    @Default('system') String type,
    @Default('') String title,
    @Default('') String body,
    String? refId,
    String? refType,
    @Default(false) bool isRead,
    DateTime? createdAt,
  }) = _NotificationModel;

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);
}
