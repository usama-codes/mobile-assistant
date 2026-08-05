import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_assistant/core/services/vault_service.dart';

void main() {
  setUpAll(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('VaultService Tests', () {
    test('Initialization works and generates a key', () async {
      await VaultService.instance.initialize();
      // Should not throw.
    });

    test('Encrypt and decrypt a string', () async {
      const plaintext = 'Secret message 123!';
      final encrypted = await VaultService.instance.encrypt(plaintext);
      
      expect(encrypted, isNot(plaintext));
      expect(VaultService.instance.isEncrypted(encrypted), isTrue);
      
      final decrypted = await VaultService.instance.decrypt(encrypted);
      expect(decrypted, plaintext);
    });

    test('isEncrypted detects marker correctly', () {
      expect(VaultService.instance.isEncrypted(r'$VAULT$something'), isTrue);
      expect(VaultService.instance.isEncrypted('plain text'), isFalse);
    });

    test('Decrypting plaintext returns plaintext', () async {
      const plaintext = 'Just normal text';
      final decrypted = await VaultService.instance.decrypt(plaintext);
      expect(decrypted, plaintext);
    });

    test('Different encryptions of the same text produce different ciphertexts (nonce works)', () async {
      const plaintext = 'Same text';
      final encrypted1 = await VaultService.instance.encrypt(plaintext);
      final encrypted2 = await VaultService.instance.encrypt(plaintext);
      
      expect(encrypted1, isNot(encrypted2));
      
      final decrypted1 = await VaultService.instance.decrypt(encrypted1);
      final decrypted2 = await VaultService.instance.decrypt(encrypted2);
      
      expect(decrypted1, plaintext);
      expect(decrypted2, plaintext);
    });
    
    test('Tampering with ciphertext throws error', () async {
      const plaintext = 'Will be tampered';
      final encrypted = await VaultService.instance.encrypt(plaintext);
      
      // Tamper with the end of the base64 string
      final tampered = '${encrypted.substring(0, encrypted.length - 2)}AA';
      
      expect(
        () async => VaultService.instance.decrypt(tampered),
        throwsA(isA<Exception>()),
      );
    });
  });
}
