// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TaskAssignee {

@JsonKey(name: '_id') String get id; String get fullName; String get email; String get avatarUrl;
/// Create a copy of TaskAssignee
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskAssigneeCopyWith<TaskAssignee> get copyWith => _$TaskAssigneeCopyWithImpl<TaskAssignee>(this as TaskAssignee, _$identity);

  /// Serializes this TaskAssignee to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TaskAssignee;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskAssignee&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.fullName, _this.fullName) || other.fullName == _this.fullName)&&(identical(other.email, _this.email) || other.email == _this.email)&&(identical(other.avatarUrl, _this.avatarUrl) || other.avatarUrl == _this.avatarUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TaskAssignee;
  return Object.hash(runtimeType,_this.id,_this.fullName,_this.email,_this.avatarUrl);
}

@override
String toString() {
  final _this = this as TaskAssignee;
  return 'TaskAssignee(id: ${_this.id}, fullName: ${_this.fullName}, email: ${_this.email}, avatarUrl: ${_this.avatarUrl})';
}


}

/// @nodoc
abstract mixin class $TaskAssigneeCopyWith<$Res>  {
  factory $TaskAssigneeCopyWith(TaskAssignee value, $Res Function(TaskAssignee) _then) = _$TaskAssigneeCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: '_id') String id, String fullName, String email, String avatarUrl
});




}
/// @nodoc
class _$TaskAssigneeCopyWithImpl<$Res>
    implements $TaskAssigneeCopyWith<$Res> {
  _$TaskAssigneeCopyWithImpl(this._self, this._then);

  final TaskAssignee _self;
  final $Res Function(TaskAssignee) _then;

/// Create a copy of TaskAssignee
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fullName = null,Object? email = null,Object? avatarUrl = null,}) {
  return _then(TaskAssignee(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: null == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TaskAssignee].
extension TaskAssigneePatterns on TaskAssignee {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TaskAssignee value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TaskAssignee() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TaskAssignee value)  $default,){
final _that = this;
switch (_that) {
case _TaskAssignee():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TaskAssignee value)?  $default,){
final _that = this;
switch (_that) {
case _TaskAssignee() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: '_id')  String id,  String fullName,  String email,  String avatarUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TaskAssignee() when $default != null:
return $default(_that.id,_that.fullName,_that.email,_that.avatarUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: '_id')  String id,  String fullName,  String email,  String avatarUrl)  $default,) {final _that = this;
switch (_that) {
case _TaskAssignee():
return $default(_that.id,_that.fullName,_that.email,_that.avatarUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: '_id')  String id,  String fullName,  String email,  String avatarUrl)?  $default,) {final _that = this;
switch (_that) {
case _TaskAssignee() when $default != null:
return $default(_that.id,_that.fullName,_that.email,_that.avatarUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TaskAssignee implements TaskAssignee {
  const _TaskAssignee({@JsonKey(name: '_id') required this.id, this.fullName = '', this.email = '', this.avatarUrl = ''});
  factory _TaskAssignee.fromJson(Map<String, dynamic> json) => _$TaskAssigneeFromJson(json);

@override@JsonKey(name: '_id') final  String id;
@override@JsonKey() final  String fullName;
@override@JsonKey() final  String email;
@override@JsonKey() final  String avatarUrl;

/// Create a copy of TaskAssignee
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskAssigneeCopyWith<_TaskAssignee> get copyWith => __$TaskAssigneeCopyWithImpl<_TaskAssignee>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TaskAssigneeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskAssignee&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.email, email) || other.email == email)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,fullName,email,avatarUrl);
}

@override
String toString() {
    return 'TaskAssignee(id: $id, fullName: $fullName, email: $email, avatarUrl: $avatarUrl)';
}


}

/// @nodoc
abstract mixin class _$TaskAssigneeCopyWith<$Res> implements $TaskAssigneeCopyWith<$Res> {
  factory _$TaskAssigneeCopyWith(_TaskAssignee value, $Res Function(_TaskAssignee) _then) = __$TaskAssigneeCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: '_id') String id, String fullName, String email, String avatarUrl
});




}
/// @nodoc
class __$TaskAssigneeCopyWithImpl<$Res>
    implements _$TaskAssigneeCopyWith<$Res> {
  __$TaskAssigneeCopyWithImpl(this._self, this._then);

  final _TaskAssignee _self;
  final $Res Function(_TaskAssignee) _then;

/// Create a copy of TaskAssignee
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fullName = null,Object? email = null,Object? avatarUrl = null,}) {
  return _then(_TaskAssignee(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: null == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$TaskModel {

@JsonKey(name: '_id') String get id; String get title; String get description; String get status; String get priority;@JsonKey(name: 'assigneeId', readValue: _readAssignee) TaskAssignee? get assignee; DateTime? get dueDate; bool get dueHasTime; int get order; bool get isOverdue;
/// Create a copy of TaskModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskModelCopyWith<TaskModel> get copyWith => _$TaskModelCopyWithImpl<TaskModel>(this as TaskModel, _$identity);

  /// Serializes this TaskModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TaskModel;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskModel&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.priority, _this.priority) || other.priority == _this.priority)&&(identical(other.assignee, _this.assignee) || other.assignee == _this.assignee)&&(identical(other.dueDate, _this.dueDate) || other.dueDate == _this.dueDate)&&(identical(other.dueHasTime, _this.dueHasTime) || other.dueHasTime == _this.dueHasTime)&&(identical(other.order, _this.order) || other.order == _this.order)&&(identical(other.isOverdue, _this.isOverdue) || other.isOverdue == _this.isOverdue));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TaskModel;
  return Object.hash(runtimeType,_this.id,_this.title,_this.description,_this.status,_this.priority,_this.assignee,_this.dueDate,_this.dueHasTime,_this.order,_this.isOverdue);
}

@override
String toString() {
  final _this = this as TaskModel;
  return 'TaskModel(id: ${_this.id}, title: ${_this.title}, description: ${_this.description}, status: ${_this.status}, priority: ${_this.priority}, assignee: ${_this.assignee}, dueDate: ${_this.dueDate}, dueHasTime: ${_this.dueHasTime}, order: ${_this.order}, isOverdue: ${_this.isOverdue})';
}


}

/// @nodoc
abstract mixin class $TaskModelCopyWith<$Res>  {
  factory $TaskModelCopyWith(TaskModel value, $Res Function(TaskModel) _then) = _$TaskModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: '_id') String id, String title, String description, String status, String priority,@JsonKey(name: 'assigneeId', readValue: _readAssignee) TaskAssignee? assignee, DateTime? dueDate, bool dueHasTime, int order, bool isOverdue
});


$TaskAssigneeCopyWith<$Res>? get assignee;

}
/// @nodoc
class _$TaskModelCopyWithImpl<$Res>
    implements $TaskModelCopyWith<$Res> {
  _$TaskModelCopyWithImpl(this._self, this._then);

  final TaskModel _self;
  final $Res Function(TaskModel) _then;

/// Create a copy of TaskModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? description = null,Object? status = null,Object? priority = null,Object? assignee = freezed,Object? dueDate = freezed,Object? dueHasTime = null,Object? order = null,Object? isOverdue = null,}) {
  return _then(TaskModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as String,assignee: freezed == assignee ? _self.assignee : assignee // ignore: cast_nullable_to_non_nullable
as TaskAssignee?,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,dueHasTime: null == dueHasTime ? _self.dueHasTime : dueHasTime // ignore: cast_nullable_to_non_nullable
as bool,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,isOverdue: null == isOverdue ? _self.isOverdue : isOverdue // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of TaskModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TaskAssigneeCopyWith<$Res>? get assignee {
    if (_self.assignee == null) {
    return null;
  }

  return $TaskAssigneeCopyWith<$Res>(_self.assignee!, (value) {
    return _then(_self.copyWith(assignee: value));
  });
}
}


/// Adds pattern-matching-related methods to [TaskModel].
extension TaskModelPatterns on TaskModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TaskModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TaskModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TaskModel value)  $default,){
final _that = this;
switch (_that) {
case _TaskModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TaskModel value)?  $default,){
final _that = this;
switch (_that) {
case _TaskModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: '_id')  String id,  String title,  String description,  String status,  String priority, @JsonKey(name: 'assigneeId', readValue: _readAssignee)  TaskAssignee? assignee,  DateTime? dueDate,  bool dueHasTime,  int order,  bool isOverdue)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TaskModel() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.status,_that.priority,_that.assignee,_that.dueDate,_that.dueHasTime,_that.order,_that.isOverdue);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: '_id')  String id,  String title,  String description,  String status,  String priority, @JsonKey(name: 'assigneeId', readValue: _readAssignee)  TaskAssignee? assignee,  DateTime? dueDate,  bool dueHasTime,  int order,  bool isOverdue)  $default,) {final _that = this;
switch (_that) {
case _TaskModel():
return $default(_that.id,_that.title,_that.description,_that.status,_that.priority,_that.assignee,_that.dueDate,_that.dueHasTime,_that.order,_that.isOverdue);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: '_id')  String id,  String title,  String description,  String status,  String priority, @JsonKey(name: 'assigneeId', readValue: _readAssignee)  TaskAssignee? assignee,  DateTime? dueDate,  bool dueHasTime,  int order,  bool isOverdue)?  $default,) {final _that = this;
switch (_that) {
case _TaskModel() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.status,_that.priority,_that.assignee,_that.dueDate,_that.dueHasTime,_that.order,_that.isOverdue);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TaskModel extends TaskModel {
  const _TaskModel({@JsonKey(name: '_id') required this.id, required this.title, this.description = '', this.status = 'todo', this.priority = 'medium', @JsonKey(name: 'assigneeId', readValue: _readAssignee) this.assignee, this.dueDate, this.dueHasTime = false, this.order = 0, this.isOverdue = false}): super._();
  factory _TaskModel.fromJson(Map<String, dynamic> json) => _$TaskModelFromJson(json);

@override@JsonKey(name: '_id') final  String id;
@override final  String title;
@override@JsonKey() final  String description;
@override@JsonKey() final  String status;
@override@JsonKey() final  String priority;
@override@JsonKey(name: 'assigneeId', readValue: _readAssignee) final  TaskAssignee? assignee;
@override final  DateTime? dueDate;
@override@JsonKey() final  bool dueHasTime;
@override@JsonKey() final  int order;
@override@JsonKey() final  bool isOverdue;

/// Create a copy of TaskModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskModelCopyWith<_TaskModel> get copyWith => __$TaskModelCopyWithImpl<_TaskModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TaskModelToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskModel&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.status, status) || other.status == status)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.assignee, assignee) || other.assignee == assignee)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.dueHasTime, dueHasTime) || other.dueHasTime == dueHasTime)&&(identical(other.order, order) || other.order == order)&&(identical(other.isOverdue, isOverdue) || other.isOverdue == isOverdue));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,title,description,status,priority,assignee,dueDate,dueHasTime,order,isOverdue);
}

@override
String toString() {
    return 'TaskModel(id: $id, title: $title, description: $description, status: $status, priority: $priority, assignee: $assignee, dueDate: $dueDate, dueHasTime: $dueHasTime, order: $order, isOverdue: $isOverdue)';
}


}

/// @nodoc
abstract mixin class _$TaskModelCopyWith<$Res> implements $TaskModelCopyWith<$Res> {
  factory _$TaskModelCopyWith(_TaskModel value, $Res Function(_TaskModel) _then) = __$TaskModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: '_id') String id, String title, String description, String status, String priority,@JsonKey(name: 'assigneeId', readValue: _readAssignee) TaskAssignee? assignee, DateTime? dueDate, bool dueHasTime, int order, bool isOverdue
});


@override $TaskAssigneeCopyWith<$Res>? get assignee;

}
/// @nodoc
class __$TaskModelCopyWithImpl<$Res>
    implements _$TaskModelCopyWith<$Res> {
  __$TaskModelCopyWithImpl(this._self, this._then);

  final _TaskModel _self;
  final $Res Function(_TaskModel) _then;

/// Create a copy of TaskModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? description = null,Object? status = null,Object? priority = null,Object? assignee = freezed,Object? dueDate = freezed,Object? dueHasTime = null,Object? order = null,Object? isOverdue = null,}) {
  return _then(_TaskModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as String,assignee: freezed == assignee ? _self.assignee : assignee // ignore: cast_nullable_to_non_nullable
as TaskAssignee?,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,dueHasTime: null == dueHasTime ? _self.dueHasTime : dueHasTime // ignore: cast_nullable_to_non_nullable
as bool,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,isOverdue: null == isOverdue ? _self.isOverdue : isOverdue // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of TaskModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TaskAssigneeCopyWith<$Res>? get assignee {
    if (_self.assignee == null) {
    return null;
  }

  return $TaskAssigneeCopyWith<$Res>(_self.assignee!, (value) {
    return _then(_self.copyWith(assignee: value));
  });
}
}

// dart format on
