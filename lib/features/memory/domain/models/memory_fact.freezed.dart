// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'memory_fact.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MemoryFact {

 int get id; String get fact; double get importance; DateTime get createdAt;
/// Create a copy of MemoryFact
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemoryFactCopyWith<MemoryFact> get copyWith => _$MemoryFactCopyWithImpl<MemoryFact>(this as MemoryFact, _$identity);

  /// Serializes this MemoryFact to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MemoryFact&&(identical(other.id, id) || other.id == id)&&(identical(other.fact, fact) || other.fact == fact)&&(identical(other.importance, importance) || other.importance == importance)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fact,importance,createdAt);

@override
String toString() {
  return 'MemoryFact(id: $id, fact: $fact, importance: $importance, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $MemoryFactCopyWith<$Res>  {
  factory $MemoryFactCopyWith(MemoryFact value, $Res Function(MemoryFact) _then) = _$MemoryFactCopyWithImpl;
@useResult
$Res call({
 int id, String fact, double importance, DateTime createdAt
});




}
/// @nodoc
class _$MemoryFactCopyWithImpl<$Res>
    implements $MemoryFactCopyWith<$Res> {
  _$MemoryFactCopyWithImpl(this._self, this._then);

  final MemoryFact _self;
  final $Res Function(MemoryFact) _then;

/// Create a copy of MemoryFact
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fact = null,Object? importance = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,fact: null == fact ? _self.fact : fact // ignore: cast_nullable_to_non_nullable
as String,importance: null == importance ? _self.importance : importance // ignore: cast_nullable_to_non_nullable
as double,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [MemoryFact].
extension MemoryFactPatterns on MemoryFact {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MemoryFact value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MemoryFact() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MemoryFact value)  $default,){
final _that = this;
switch (_that) {
case _MemoryFact():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MemoryFact value)?  $default,){
final _that = this;
switch (_that) {
case _MemoryFact() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String fact,  double importance,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MemoryFact() when $default != null:
return $default(_that.id,_that.fact,_that.importance,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String fact,  double importance,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _MemoryFact():
return $default(_that.id,_that.fact,_that.importance,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String fact,  double importance,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _MemoryFact() when $default != null:
return $default(_that.id,_that.fact,_that.importance,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MemoryFact extends MemoryFact {
  const _MemoryFact({required this.id, required this.fact, required this.importance, required this.createdAt}): super._();
  factory _MemoryFact.fromJson(Map<String, dynamic> json) => _$MemoryFactFromJson(json);

@override final  int id;
@override final  String fact;
@override final  double importance;
@override final  DateTime createdAt;

/// Create a copy of MemoryFact
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MemoryFactCopyWith<_MemoryFact> get copyWith => __$MemoryFactCopyWithImpl<_MemoryFact>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MemoryFactToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MemoryFact&&(identical(other.id, id) || other.id == id)&&(identical(other.fact, fact) || other.fact == fact)&&(identical(other.importance, importance) || other.importance == importance)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fact,importance,createdAt);

@override
String toString() {
  return 'MemoryFact(id: $id, fact: $fact, importance: $importance, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$MemoryFactCopyWith<$Res> implements $MemoryFactCopyWith<$Res> {
  factory _$MemoryFactCopyWith(_MemoryFact value, $Res Function(_MemoryFact) _then) = __$MemoryFactCopyWithImpl;
@override @useResult
$Res call({
 int id, String fact, double importance, DateTime createdAt
});




}
/// @nodoc
class __$MemoryFactCopyWithImpl<$Res>
    implements _$MemoryFactCopyWith<$Res> {
  __$MemoryFactCopyWithImpl(this._self, this._then);

  final _MemoryFact _self;
  final $Res Function(_MemoryFact) _then;

/// Create a copy of MemoryFact
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fact = null,Object? importance = null,Object? createdAt = null,}) {
  return _then(_MemoryFact(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,fact: null == fact ? _self.fact : fact // ignore: cast_nullable_to_non_nullable
as String,importance: null == importance ? _self.importance : importance // ignore: cast_nullable_to_non_nullable
as double,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
