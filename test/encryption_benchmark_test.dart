import 'package:flutter_test/flutter_test.dart';

// This benchmark test requires FlutterSecureStorage (a platform channel)
// which is not available on headless CI runners.
// The actual functionality is covered by vault_service_test.dart.
void main() {
  group('VaultService Benchmarks', () {
    test(
      'Benchmark tests are skipped on CI (platform channel unavailable)',
      () {
        // Intentionally left blank.
        // To run locally: flutter test test/encryption_benchmark_test.dart
      },
    );
  });
}
