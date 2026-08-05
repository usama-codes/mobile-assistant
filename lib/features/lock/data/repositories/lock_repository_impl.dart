import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mobile_assistant/features/lock/domain/repositories/lock_repository.dart';

class LockRepositoryImpl implements LockRepository {
  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  Future<bool> isAppLockEnabled() async {
    final value = await _storage.read(key: 'app_lock_enabled');
    return value == 'true';
  }

  @override
  Future<bool> canAuthenticate() async {
    final canCheckBiometrics = await _auth.canCheckBiometrics;
    return canCheckBiometrics || await _auth.isDeviceSupported();
  }

  @override
  Future<bool> authenticate(String localizedReason) async {
    try {
      return await _auth.authenticate(localizedReason: localizedReason);
    } catch (e) {
      return false; // Fallback on error
    }
  }
}
