import 'package:freezed_annotation/freezed_annotation.dart';

part 'project_member_model.freezed.dart';
part 'project_member_model.g.dart';

@freezed
abstract class ProjectMemberModel with _$ProjectMemberModel {
  const factory ProjectMemberModel({
    required String id,
    @Default('') String name,
    @Default('') String email,
    @Default('') String phone,
    @Default('') String avatarUrl,
    @Default('Member') String role,
  }) = _ProjectMemberModel;

  factory ProjectMemberModel.fromJson(Map<String, dynamic> json) =>
      _$ProjectMemberModelFromJson(json);
}
