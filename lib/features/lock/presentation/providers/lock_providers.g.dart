// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lock_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(lockRepository)
final lockRepositoryProvider = LockRepositoryProvider._();

final class LockRepositoryProvider
    extends $FunctionalProvider<LockRepository, LockRepository, LockRepository>
    with $Provider<LockRepository> {
  LockRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lockRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lockRepositoryHash();

  @$internal
  @override
  $ProviderElement<LockRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LockRepository create(Ref ref) {
    return lockRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LockRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LockRepository>(value),
    );
  }
}

String _$lockRepositoryHash() => r'6908d2faddf401e12b4ebaee8d5f19b2cee4fc9f';

@ProviderFor(LockNotifier)
final lockProvider = LockNotifierProvider._();

final class LockNotifierProvider
    extends $AsyncNotifierProvider<LockNotifier, bool> {
  LockNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lockProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lockNotifierHash();

  @$internal
  @override
  LockNotifier create() => LockNotifier();
}

String _$lockNotifierHash() => r'196611b8a438cfa4ee6e167757b673c18261dae8';

abstract class _$LockNotifier extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
