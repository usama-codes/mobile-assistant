import 'package:mobile_assistant/features/lock/data/repositories/lock_repository_impl.dart';
import 'package:mobile_assistant/features/lock/domain/repositories/lock_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'lock_providers.g.dart';

@riverpod
LockRepository lockRepository(Ref ref) {
  return LockRepositoryImpl();
}

@riverpod
class LockNotifier extends _$LockNotifier {
  @override
  FutureOr<bool> build() async {
    return checkAuth();
  }

  Future<bool> checkAuth() async {
    final repo = ref.read(lockRepositoryProvider);
    final isLockEnabled = await repo.isAppLockEnabled();

    if (!isLockEnabled) {
      return true;
    }

    final canAuthenticate = await repo.canAuthenticate();
    if (!canAuthenticate) {
      return true;
    }

    final didAuthenticate = await repo.authenticate('Please authenticate to access Mobile Assistant');
    return didAuthenticate;
  }
}
