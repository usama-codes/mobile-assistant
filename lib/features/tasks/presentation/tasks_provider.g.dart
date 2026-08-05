// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tasks_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TasksNotifier)
final tasksProvider = TasksNotifierProvider._();

final class TasksNotifierProvider
    extends $StreamNotifierProvider<TasksNotifier, List<TaskItem>> {
  TasksNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tasksProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tasksNotifierHash();

  @$internal
  @override
  TasksNotifier create() => TasksNotifier();
}

String _$tasksNotifierHash() => r'eca9c76b0a797d7113c1548479c0350e9b5ccc3f';

abstract class _$TasksNotifier extends $StreamNotifier<List<TaskItem>> {
  Stream<List<TaskItem>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<TaskItem>>, List<TaskItem>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<TaskItem>>, List<TaskItem>>,
              AsyncValue<List<TaskItem>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
