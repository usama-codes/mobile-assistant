// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'document_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DocumentItem {

 int get id; String get title; String get folder; List<String> get tags; String get originalSource; String get documentType; String get filePath; DateTime get createdAt;
/// Create a copy of DocumentItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocumentItemCopyWith<DocumentItem> get copyWith => _$DocumentItemCopyWithImpl<DocumentItem>(this as DocumentItem, _$identity);

  /// Serializes this DocumentItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DocumentItem&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.folder, folder) || other.folder == folder)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.originalSource, originalSource) || other.originalSource == originalSource)&&(identical(other.documentType, documentType) || other.documentType == documentType)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,folder,const DeepCollectionEquality().hash(tags),originalSource,documentType,filePath,createdAt);

@override
String toString() {
  return 'DocumentItem(id: $id, title: $title, folder: $folder, tags: $tags, originalSource: $originalSource, documentType: $documentType, filePath: $filePath, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $DocumentItemCopyWith<$Res>  {
  factory $DocumentItemCopyWith(DocumentItem value, $Res Function(DocumentItem) _then) = _$DocumentItemCopyWithImpl;
@useResult
$Res call({
 int id, String title, String folder, List<String> tags, String originalSource, String documentType, String filePath, DateTime createdAt
});




}
/// @nodoc
class _$DocumentItemCopyWithImpl<$Res>
    implements $DocumentItemCopyWith<$Res> {
  _$DocumentItemCopyWithImpl(this._self, this._then);

  final DocumentItem _self;
  final $Res Function(DocumentItem) _then;

/// Create a copy of DocumentItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? folder = null,Object? tags = null,Object? originalSource = null,Object? documentType = null,Object? filePath = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,folder: null == folder ? _self.folder : folder // ignore: cast_nullable_to_non_nullable
as String,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,originalSource: null == originalSource ? _self.originalSource : originalSource // ignore: cast_nullable_to_non_nullable
as String,documentType: null == documentType ? _self.documentType : documentType // ignore: cast_nullable_to_non_nullable
as String,filePath: null == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [DocumentItem].
extension DocumentItemPatterns on DocumentItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DocumentItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DocumentItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DocumentItem value)  $default,){
final _that = this;
switch (_that) {
case _DocumentItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DocumentItem value)?  $default,){
final _that = this;
switch (_that) {
case _DocumentItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String title,  String folder,  List<String> tags,  String originalSource,  String documentType,  String filePath,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DocumentItem() when $default != null:
return $default(_that.id,_that.title,_that.folder,_that.tags,_that.originalSource,_that.documentType,_that.filePath,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String title,  String folder,  List<String> tags,  String originalSource,  String documentType,  String filePath,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _DocumentItem():
return $default(_that.id,_that.title,_that.folder,_that.tags,_that.originalSource,_that.documentType,_that.filePath,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String title,  String folder,  List<String> tags,  String originalSource,  String documentType,  String filePath,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _DocumentItem() when $default != null:
return $default(_that.id,_that.title,_that.folder,_that.tags,_that.originalSource,_that.documentType,_that.filePath,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DocumentItem implements DocumentItem {
  const _DocumentItem({required this.id, required this.title, required this.folder, required  List<String> tags, required this.originalSource, required this.documentType, required this.filePath, required this.createdAt}): _tags = tags;
  factory _DocumentItem.fromJson(Map<String, dynamic> json) => _$DocumentItemFromJson(json);

@override final  int id;
@override final  String title;
@override final  String folder;
 final  List<String> _tags;
@override List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

@override final  String originalSource;
@override final  String documentType;
@override final  String filePath;
@override final  DateTime createdAt;

/// Create a copy of DocumentItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DocumentItemCopyWith<_DocumentItem> get copyWith => __$DocumentItemCopyWithImpl<_DocumentItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DocumentItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DocumentItem&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.folder, folder) || other.folder == folder)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.originalSource, originalSource) || other.originalSource == originalSource)&&(identical(other.documentType, documentType) || other.documentType == documentType)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,folder,const DeepCollectionEquality().hash(_tags),originalSource,documentType,filePath,createdAt);

@override
String toString() {
  return 'DocumentItem(id: $id, title: $title, folder: $folder, tags: $tags, originalSource: $originalSource, documentType: $documentType, filePath: $filePath, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$DocumentItemCopyWith<$Res> implements $DocumentItemCopyWith<$Res> {
  factory _$DocumentItemCopyWith(_DocumentItem value, $Res Function(_DocumentItem) _then) = __$DocumentItemCopyWithImpl;
@override @useResult
$Res call({
 int id, String title, String folder, List<String> tags, String originalSource, String documentType, String filePath, DateTime createdAt
});




}
/// @nodoc
class __$DocumentItemCopyWithImpl<$Res>
    implements _$DocumentItemCopyWith<$Res> {
  __$DocumentItemCopyWithImpl(this._self, this._then);

  final _DocumentItem _self;
  final $Res Function(_DocumentItem) _then;

/// Create a copy of DocumentItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? folder = null,Object? tags = null,Object? originalSource = null,Object? documentType = null,Object? filePath = null,Object? createdAt = null,}) {
  return _then(_DocumentItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,folder: null == folder ? _self.folder : folder // ignore: cast_nullable_to_non_nullable
as String,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,originalSource: null == originalSource ? _self.originalSource : originalSource // ignore: cast_nullable_to_non_nullable
as String,documentType: null == documentType ? _self.documentType : documentType // ignore: cast_nullable_to_non_nullable
as String,filePath: null == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
