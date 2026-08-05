import 'package:freezed_annotation/freezed_annotation.dart';

part 'memory_fact.freezed.dart';
part 'memory_fact.g.dart';

@freezed
abstract class MemoryFact with _$MemoryFact {
  const factory MemoryFact({
    required int id,
    required String fact,
    required double importance,
    required DateTime createdAt,
  }) = _MemoryFact;

  const MemoryFact._();

  factory MemoryFact.fromJson(Map<String, dynamic> json) => _$MemoryFactFromJson(json);
}
