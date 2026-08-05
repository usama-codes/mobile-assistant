abstract class LockRepository {
  Future<bool> isAppLockEnabled();
  Future<bool> canAuthenticate();
  Future<bool> authenticate(String localizedReason);
}
