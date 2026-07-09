import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile_assistant/main.dart';

class LockScreenVM extends BaseViewModel {
  final LocalAuthentication auth = LocalAuthentication();
  final storage = const FlutterSecureStorage();
  bool isChecking = true;
  bool hasFired = false;

  Future<void> checkAuth(BuildContext context) async {
    final isLockEnabled = await storage.read(key: 'app_lock_enabled') == 'true';

    if (!isLockEnabled) {
      if (!context.mounted) return;
      _navigateToHome(context);
      return;
    }

    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (!canAuthenticate) {
        if (!context.mounted) return;
        _navigateToHome(context);
        return;
      }

      isChecking = false;
      notifyListeners();

      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to access Mobile Assistant',
        // options: const AuthenticationOptions(stickyAuth: true, biometricOnly: false),
      );

      if (didAuthenticate) {
        if (!context.mounted) return;
        _navigateToHome(context);
      }
    } catch (e) {
      if (!context.mounted) return;
      _navigateToHome(context); // Fallback on error
    }
  }

  void _navigateToHome(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }
}
