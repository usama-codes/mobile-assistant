// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(documentRepository)
final documentRepositoryProvider = DocumentRepositoryProvider._();

final class DocumentRepositoryProvider
    extends
        $FunctionalProvider<
          DocumentRepository,
          DocumentRepository,
          DocumentRepository
        >
    with $Provider<DocumentRepository> {
  DocumentRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'documentRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$documentRepositoryHash();

  @$internal
  @override
  $ProviderElement<DocumentRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DocumentRepository create(Ref ref) {
    return documentRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DocumentRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DocumentRepository>(value),
    );
  }
}

String _$documentRepositoryHash() =>
    r'21a416198388aeaefb611727bdd08a4d5154551e';

@ProviderFor(DocumentNotifier)
final documentProvider = DocumentNotifierProvider._();

final class DocumentNotifierProvider
    extends $AsyncNotifierProvider<DocumentNotifier, List<DocumentItem>> {
  DocumentNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'documentProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$documentNotifierHash();

  @$internal
  @override
  DocumentNotifier create() => DocumentNotifier();
}

String _$documentNotifierHash() => r'069a17234949450e6d5285a7ac2588447bdcddda';

abstract class _$DocumentNotifier extends $AsyncNotifier<List<DocumentItem>> {
  FutureOr<List<DocumentItem>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<DocumentItem>>, List<DocumentItem>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<DocumentItem>>, List<DocumentItem>>,
              AsyncValue<List<DocumentItem>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
