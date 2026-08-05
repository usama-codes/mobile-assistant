import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MigrationService {
  static const _storage = FlutterSecureStorage();
  static const _migrationKey = 'crypto_migration_complete';

  static Future<void> runMigrations() async {
    // Legacy migration was removed as it required old crypto packages.
    await _storage.write(key: _migrationKey, value: 'true');
  }
}
