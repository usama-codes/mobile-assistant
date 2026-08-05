// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memory_fact.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MemoryFact _$MemoryFactFromJson(Map<String, dynamic> json) => _MemoryFact(
  id: (json['id'] as num).toInt(),
  fact: json['fact'] as String,
  importance: (json['importance'] as num).toDouble(),
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$MemoryFactToJson(_MemoryFact instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fact': instance.fact,
      'importance': instance.importance,
      'createdAt': instance.createdAt.toIso8601String(),
    };
