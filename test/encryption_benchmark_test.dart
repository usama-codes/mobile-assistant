import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_assistant/core/services/vault_service.dart';

void main() {
  group('VaultService Benchmarks', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      await VaultService.instance
          .initialize(); // Assuming mock storage or local
    });

    test('Encryption/Decryption speed test (1000 iterations)', () async {
      const data =
          'Highly sensitive memory data with vectors and personal notes';
      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < 1000; i++) {
        final encrypted = await VaultService.instance.encrypt(data);
        final decrypted = await VaultService.instance.decrypt(encrypted);
        expect(decrypted, data);
      }

      stopwatch.stop();
      print(
        '1000 encrypt/decrypt cycles took ${stopwatch.elapsedMilliseconds} ms',
      );

      // We expect it to complete in under 2 seconds (2000 ms) on a modern device
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));
    });
  });
}
