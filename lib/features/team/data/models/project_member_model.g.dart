// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_member_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProjectMemberModel _$ProjectMemberModelFromJson(Map<String, dynamic> json) =>
    _ProjectMemberModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      role: json['role'] as String? ?? 'Member',
    );

Map<String, dynamic> _$ProjectMemberModelToJson(_ProjectMemberModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'phone': instance.phone,
      'avatarUrl': instance.avatarUrl,
      'role': instance.role,
    };
