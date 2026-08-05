// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DocumentItem _$DocumentItemFromJson(Map<String, dynamic> json) =>
    _DocumentItem(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      folder: json['folder'] as String,
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      originalSource: json['originalSource'] as String,
      documentType: json['documentType'] as String,
      filePath: json['filePath'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$DocumentItemToJson(_DocumentItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'folder': instance.folder,
      'tags': instance.tags,
      'originalSource': instance.originalSource,
      'documentType': instance.documentType,
      'filePath': instance.filePath,
      'createdAt': instance.createdAt.toIso8601String(),
    };
