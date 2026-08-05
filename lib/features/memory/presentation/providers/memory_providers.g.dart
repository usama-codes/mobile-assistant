// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memory_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(memoryRepository)
final memoryRepositoryProvider = MemoryRepositoryProvider._();

final class MemoryRepositoryProvider
    extends
        $FunctionalProvider<
          MemoryRepository,
          MemoryRepository,
          MemoryRepository
        >
    with $Provider<MemoryRepository> {
  MemoryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'memoryRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$memoryRepositoryHash();

  @$internal
  @override
  $ProviderElement<MemoryRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MemoryRepository create(Ref ref) {
    return memoryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MemoryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MemoryRepository>(value),
    );
  }
}

String _$memoryRepositoryHash() => r'2de0cfb7dc2236cae3ac13c72d06faa5d118c897';

@ProviderFor(MemoryNotifier)
final memoryProvider = MemoryNotifierProvider._();

final class MemoryNotifierProvider
    extends $AsyncNotifierProvider<MemoryNotifier, List<dom.MemoryFact>> {
  MemoryNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'memoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$memoryNotifierHash();

  @$internal
  @override
  MemoryNotifier create() => MemoryNotifier();
}

String _$memoryNotifierHash() => r'404aad31c33809dbdd83221efdf67cc7878fa599';

abstract class _$MemoryNotifier extends $AsyncNotifier<List<dom.MemoryFact>> {
  FutureOr<List<dom.MemoryFact>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<dom.MemoryFact>>, List<dom.MemoryFact>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<dom.MemoryFact>>,
                List<dom.MemoryFact>
              >,
              AsyncValue<List<dom.MemoryFact>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
