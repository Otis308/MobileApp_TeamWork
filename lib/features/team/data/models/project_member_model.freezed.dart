// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project_member_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProjectMemberModel {

 String get id; String get name; String get email; String get phone; String get avatarUrl; String get role;
/// Create a copy of ProjectMemberModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectMemberModelCopyWith<ProjectMemberModel> get copyWith => _$ProjectMemberModelCopyWithImpl<ProjectMemberModel>(this as ProjectMemberModel, _$identity);

  /// Serializes this ProjectMemberModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ProjectMemberModel;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectMemberModel&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.email, _this.email) || other.email == _this.email)&&(identical(other.phone, _this.phone) || other.phone == _this.phone)&&(identical(other.avatarUrl, _this.avatarUrl) || other.avatarUrl == _this.avatarUrl)&&(identical(other.role, _this.role) || other.role == _this.role));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ProjectMemberModel;
  return Object.hash(runtimeType,_this.id,_this.name,_this.email,_this.phone,_this.avatarUrl,_this.role);
}

@override
String toString() {
  final _this = this as ProjectMemberModel;
  return 'ProjectMemberModel(id: ${_this.id}, name: ${_this.name}, email: ${_this.email}, phone: ${_this.phone}, avatarUrl: ${_this.avatarUrl}, role: ${_this.role})';
}


}

/// @nodoc
abstract mixin class $ProjectMemberModelCopyWith<$Res>  {
  factory $ProjectMemberModelCopyWith(ProjectMemberModel value, $Res Function(ProjectMemberModel) _then) = _$ProjectMemberModelCopyWithImpl;
@useResult
$Res call({
 String id, String name, String email, String phone, String avatarUrl, String role
});




}
/// @nodoc
class _$ProjectMemberModelCopyWithImpl<$Res>
    implements $ProjectMemberModelCopyWith<$Res> {
  _$ProjectMemberModelCopyWithImpl(this._self, this._then);

  final ProjectMemberModel _self;
  final $Res Function(ProjectMemberModel) _then;

/// Create a copy of ProjectMemberModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? email = null,Object? phone = null,Object? avatarUrl = null,Object? role = null,}) {
  return _then(ProjectMemberModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: null == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectMemberModel].
extension ProjectMemberModelPatterns on ProjectMemberModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectMemberModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectMemberModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectMemberModel value)  $default,){
final _that = this;
switch (_that) {
case _ProjectMemberModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectMemberModel value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectMemberModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String email,  String phone,  String avatarUrl,  String role)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectMemberModel() when $default != null:
return $default(_that.id,_that.name,_that.email,_that.phone,_that.avatarUrl,_that.role);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String email,  String phone,  String avatarUrl,  String role)  $default,) {final _that = this;
switch (_that) {
case _ProjectMemberModel():
return $default(_that.id,_that.name,_that.email,_that.phone,_that.avatarUrl,_that.role);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String email,  String phone,  String avatarUrl,  String role)?  $default,) {final _that = this;
switch (_that) {
case _ProjectMemberModel() when $default != null:
return $default(_that.id,_that.name,_that.email,_that.phone,_that.avatarUrl,_that.role);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProjectMemberModel implements ProjectMemberModel {
  const _ProjectMemberModel({required this.id, this.name = '', this.email = '', this.phone = '', this.avatarUrl = '', this.role = 'Member'});
  factory _ProjectMemberModel.fromJson(Map<String, dynamic> json) => _$ProjectMemberModelFromJson(json);

@override final  String id;
@override@JsonKey() final  String name;
@override@JsonKey() final  String email;
@override@JsonKey() final  String phone;
@override@JsonKey() final  String avatarUrl;
@override@JsonKey() final  String role;

/// Create a copy of ProjectMemberModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectMemberModelCopyWith<_ProjectMemberModel> get copyWith => __$ProjectMemberModelCopyWithImpl<_ProjectMemberModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProjectMemberModelToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectMemberModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.email, email) || other.email == email)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.role, role) || other.role == role));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,email,phone,avatarUrl,role);
}

@override
String toString() {
    return 'ProjectMemberModel(id: $id, name: $name, email: $email, phone: $phone, avatarUrl: $avatarUrl, role: $role)';
}


}

/// @nodoc
abstract mixin class _$ProjectMemberModelCopyWith<$Res> implements $ProjectMemberModelCopyWith<$Res> {
  factory _$ProjectMemberModelCopyWith(_ProjectMemberModel value, $Res Function(_ProjectMemberModel) _then) = __$ProjectMemberModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String email, String phone, String avatarUrl, String role
});




}
/// @nodoc
class __$ProjectMemberModelCopyWithImpl<$Res>
    implements _$ProjectMemberModelCopyWith<$Res> {
  __$ProjectMemberModelCopyWithImpl(this._self, this._then);

  final _ProjectMemberModel _self;
  final $Res Function(_ProjectMemberModel) _then;

/// Create a copy of ProjectMemberModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? email = null,Object? phone = null,Object? avatarUrl = null,Object? role = null,}) {
  return _then(_ProjectMemberModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: null == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
