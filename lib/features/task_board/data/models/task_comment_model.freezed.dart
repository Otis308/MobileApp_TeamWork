// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_comment_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TaskCommentAuthor {

@JsonKey(name: '_id') String get id; String get fullName; String get avatarUrl;
/// Create a copy of TaskCommentAuthor
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskCommentAuthorCopyWith<TaskCommentAuthor> get copyWith => _$TaskCommentAuthorCopyWithImpl<TaskCommentAuthor>(this as TaskCommentAuthor, _$identity);

  /// Serializes this TaskCommentAuthor to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TaskCommentAuthor;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskCommentAuthor&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.fullName, _this.fullName) || other.fullName == _this.fullName)&&(identical(other.avatarUrl, _this.avatarUrl) || other.avatarUrl == _this.avatarUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TaskCommentAuthor;
  return Object.hash(runtimeType,_this.id,_this.fullName,_this.avatarUrl);
}

@override
String toString() {
  final _this = this as TaskCommentAuthor;
  return 'TaskCommentAuthor(id: ${_this.id}, fullName: ${_this.fullName}, avatarUrl: ${_this.avatarUrl})';
}


}

/// @nodoc
abstract mixin class $TaskCommentAuthorCopyWith<$Res>  {
  factory $TaskCommentAuthorCopyWith(TaskCommentAuthor value, $Res Function(TaskCommentAuthor) _then) = _$TaskCommentAuthorCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: '_id') String id, String fullName, String avatarUrl
});




}
/// @nodoc
class _$TaskCommentAuthorCopyWithImpl<$Res>
    implements $TaskCommentAuthorCopyWith<$Res> {
  _$TaskCommentAuthorCopyWithImpl(this._self, this._then);

  final TaskCommentAuthor _self;
  final $Res Function(TaskCommentAuthor) _then;

/// Create a copy of TaskCommentAuthor
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fullName = null,Object? avatarUrl = null,}) {
  return _then(TaskCommentAuthor(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: null == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TaskCommentAuthor].
extension TaskCommentAuthorPatterns on TaskCommentAuthor {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TaskCommentAuthor value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TaskCommentAuthor() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TaskCommentAuthor value)  $default,){
final _that = this;
switch (_that) {
case _TaskCommentAuthor():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TaskCommentAuthor value)?  $default,){
final _that = this;
switch (_that) {
case _TaskCommentAuthor() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: '_id')  String id,  String fullName,  String avatarUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TaskCommentAuthor() when $default != null:
return $default(_that.id,_that.fullName,_that.avatarUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: '_id')  String id,  String fullName,  String avatarUrl)  $default,) {final _that = this;
switch (_that) {
case _TaskCommentAuthor():
return $default(_that.id,_that.fullName,_that.avatarUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: '_id')  String id,  String fullName,  String avatarUrl)?  $default,) {final _that = this;
switch (_that) {
case _TaskCommentAuthor() when $default != null:
return $default(_that.id,_that.fullName,_that.avatarUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TaskCommentAuthor implements TaskCommentAuthor {
  const _TaskCommentAuthor({@JsonKey(name: '_id') required this.id, this.fullName = '', this.avatarUrl = ''});
  factory _TaskCommentAuthor.fromJson(Map<String, dynamic> json) => _$TaskCommentAuthorFromJson(json);

@override@JsonKey(name: '_id') final  String id;
@override@JsonKey() final  String fullName;
@override@JsonKey() final  String avatarUrl;

/// Create a copy of TaskCommentAuthor
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskCommentAuthorCopyWith<_TaskCommentAuthor> get copyWith => __$TaskCommentAuthorCopyWithImpl<_TaskCommentAuthor>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TaskCommentAuthorToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskCommentAuthor&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,fullName,avatarUrl);
}

@override
String toString() {
    return 'TaskCommentAuthor(id: $id, fullName: $fullName, avatarUrl: $avatarUrl)';
}


}

/// @nodoc
abstract mixin class _$TaskCommentAuthorCopyWith<$Res> implements $TaskCommentAuthorCopyWith<$Res> {
  factory _$TaskCommentAuthorCopyWith(_TaskCommentAuthor value, $Res Function(_TaskCommentAuthor) _then) = __$TaskCommentAuthorCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: '_id') String id, String fullName, String avatarUrl
});




}
/// @nodoc
class __$TaskCommentAuthorCopyWithImpl<$Res>
    implements _$TaskCommentAuthorCopyWith<$Res> {
  __$TaskCommentAuthorCopyWithImpl(this._self, this._then);

  final _TaskCommentAuthor _self;
  final $Res Function(_TaskCommentAuthor) _then;

/// Create a copy of TaskCommentAuthor
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fullName = null,Object? avatarUrl = null,}) {
  return _then(_TaskCommentAuthor(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: null == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$TaskCommentModel {

@JsonKey(name: '_id') String get id; String get content; DateTime get createdAt;@JsonKey(name: 'userId', readValue: _readAuthor) TaskCommentAuthor? get author;
/// Create a copy of TaskCommentModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskCommentModelCopyWith<TaskCommentModel> get copyWith => _$TaskCommentModelCopyWithImpl<TaskCommentModel>(this as TaskCommentModel, _$identity);

  /// Serializes this TaskCommentModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TaskCommentModel;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskCommentModel&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.content, _this.content) || other.content == _this.content)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.author, _this.author) || other.author == _this.author));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TaskCommentModel;
  return Object.hash(runtimeType,_this.id,_this.content,_this.createdAt,_this.author);
}

@override
String toString() {
  final _this = this as TaskCommentModel;
  return 'TaskCommentModel(id: ${_this.id}, content: ${_this.content}, createdAt: ${_this.createdAt}, author: ${_this.author})';
}


}

/// @nodoc
abstract mixin class $TaskCommentModelCopyWith<$Res>  {
  factory $TaskCommentModelCopyWith(TaskCommentModel value, $Res Function(TaskCommentModel) _then) = _$TaskCommentModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: '_id') String id, String content, DateTime createdAt,@JsonKey(name: 'userId', readValue: _readAuthor) TaskCommentAuthor? author
});


$TaskCommentAuthorCopyWith<$Res>? get author;

}
/// @nodoc
class _$TaskCommentModelCopyWithImpl<$Res>
    implements $TaskCommentModelCopyWith<$Res> {
  _$TaskCommentModelCopyWithImpl(this._self, this._then);

  final TaskCommentModel _self;
  final $Res Function(TaskCommentModel) _then;

/// Create a copy of TaskCommentModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? content = null,Object? createdAt = null,Object? author = freezed,}) {
  return _then(TaskCommentModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as TaskCommentAuthor?,
  ));
}
/// Create a copy of TaskCommentModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TaskCommentAuthorCopyWith<$Res>? get author {
    if (_self.author == null) {
    return null;
  }

  return $TaskCommentAuthorCopyWith<$Res>(_self.author!, (value) {
    return _then(_self.copyWith(author: value));
  });
}
}


/// Adds pattern-matching-related methods to [TaskCommentModel].
extension TaskCommentModelPatterns on TaskCommentModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TaskCommentModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TaskCommentModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TaskCommentModel value)  $default,){
final _that = this;
switch (_that) {
case _TaskCommentModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TaskCommentModel value)?  $default,){
final _that = this;
switch (_that) {
case _TaskCommentModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: '_id')  String id,  String content,  DateTime createdAt, @JsonKey(name: 'userId', readValue: _readAuthor)  TaskCommentAuthor? author)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TaskCommentModel() when $default != null:
return $default(_that.id,_that.content,_that.createdAt,_that.author);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: '_id')  String id,  String content,  DateTime createdAt, @JsonKey(name: 'userId', readValue: _readAuthor)  TaskCommentAuthor? author)  $default,) {final _that = this;
switch (_that) {
case _TaskCommentModel():
return $default(_that.id,_that.content,_that.createdAt,_that.author);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: '_id')  String id,  String content,  DateTime createdAt, @JsonKey(name: 'userId', readValue: _readAuthor)  TaskCommentAuthor? author)?  $default,) {final _that = this;
switch (_that) {
case _TaskCommentModel() when $default != null:
return $default(_that.id,_that.content,_that.createdAt,_that.author);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TaskCommentModel implements TaskCommentModel {
  const _TaskCommentModel({@JsonKey(name: '_id') required this.id, required this.content, required this.createdAt, @JsonKey(name: 'userId', readValue: _readAuthor) this.author});
  factory _TaskCommentModel.fromJson(Map<String, dynamic> json) => _$TaskCommentModelFromJson(json);

@override@JsonKey(name: '_id') final  String id;
@override final  String content;
@override final  DateTime createdAt;
@override@JsonKey(name: 'userId', readValue: _readAuthor) final  TaskCommentAuthor? author;

/// Create a copy of TaskCommentModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskCommentModelCopyWith<_TaskCommentModel> get copyWith => __$TaskCommentModelCopyWithImpl<_TaskCommentModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TaskCommentModelToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskCommentModel&&(identical(other.id, id) || other.id == id)&&(identical(other.content, content) || other.content == content)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.author, author) || other.author == author));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,content,createdAt,author);
}

@override
String toString() {
    return 'TaskCommentModel(id: $id, content: $content, createdAt: $createdAt, author: $author)';
}


}

/// @nodoc
abstract mixin class _$TaskCommentModelCopyWith<$Res> implements $TaskCommentModelCopyWith<$Res> {
  factory _$TaskCommentModelCopyWith(_TaskCommentModel value, $Res Function(_TaskCommentModel) _then) = __$TaskCommentModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: '_id') String id, String content, DateTime createdAt,@JsonKey(name: 'userId', readValue: _readAuthor) TaskCommentAuthor? author
});


@override $TaskCommentAuthorCopyWith<$Res>? get author;

}
/// @nodoc
class __$TaskCommentModelCopyWithImpl<$Res>
    implements _$TaskCommentModelCopyWith<$Res> {
  __$TaskCommentModelCopyWithImpl(this._self, this._then);

  final _TaskCommentModel _self;
  final $Res Function(_TaskCommentModel) _then;

/// Create a copy of TaskCommentModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? content = null,Object? createdAt = null,Object? author = freezed,}) {
  return _then(_TaskCommentModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as TaskCommentAuthor?,
  ));
}

/// Create a copy of TaskCommentModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TaskCommentAuthorCopyWith<$Res>? get author {
    if (_self.author == null) {
    return null;
  }

  return $TaskCommentAuthorCopyWith<$Res>(_self.author!, (value) {
    return _then(_self.copyWith(author: value));
  });
}
}

// dart format on
