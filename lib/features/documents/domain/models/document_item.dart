import 'package:freezed_annotation/freezed_annotation.dart';

part 'document_item.freezed.dart';
part 'document_item.g.dart';

@freezed
abstract class DocumentItem with _$DocumentItem {
  const factory DocumentItem({
    required int id,
    required String title,
    required String folder,
    required List<String> tags,
    required String originalSource,
    required String documentType,
    required String filePath,
    required DateTime createdAt,
  }) = _DocumentItem;

  factory DocumentItem.fromJson(Map<String, dynamic> json) =>
      _$DocumentItemFromJson(json);
}
