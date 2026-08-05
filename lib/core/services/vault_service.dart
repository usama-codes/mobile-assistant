import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class VaultService {
  VaultService._();
  static final VaultService instance = VaultService._();

  static const _storage = FlutterSecureStorage();
  static const _keyName = 'encryption_key';
  static const _marker = r'$VAULT$';

  SecretKey? _secretKey;
  final _cipher = AesGcm.with256bits();

  /// Initialize the service by loading or generating the encryption key.
  Future<void> initialize() async {
    if (_secretKey != null) return;

    var keyString = await _storage.read(key: _keyName);
    if (keyString == null) {
      final newKey = await _cipher.newSecretKey();
      final keyBytes = await newKey.extractBytes();
      keyString = base64UrlEncode(keyBytes);
      await _storage.write(key: _keyName, value: keyString);
      _secretKey = newKey;
    } else {
      final keyBytes = base64Url.decode(keyString);
      _secretKey = SecretKey(keyBytes);
    }
  }

  /// Check if the text is encrypted by looking for the marker.
  bool isEncrypted(String text) {
    return text.startsWith(_marker);
  }

  /// Encrypt a plaintext string using AES-GCM.
  Future<String> encrypt(String plaintext) async {
    if (_secretKey == null) {
      await initialize();
    }
    final nonce = _cipher.newNonce();
    final secretBox = await _cipher.encrypt(
      utf8.encode(plaintext),
      secretKey: _secretKey!,
      nonce: nonce,
    );
    final combined = secretBox.concatenation();
    final encoded = base64Encode(combined);
    return '$_marker$encoded';
  }

  /// Decrypt a blob that was encrypted with this service.
  Future<String> decrypt(String blob) async {
    if (!isEncrypted(blob)) {
      return blob;
    }
    if (_secretKey == null) {
      await initialize();
    }
    final encoded = blob.substring(_marker.length);
    final combined = base64Decode(encoded);

    final secretBox = SecretBox.fromConcatenation(
      combined,
      nonceLength: _cipher.nonceLength,
      macLength: _cipher.macAlgorithm.macLength,
    );

    try {
      final clearTextBytes = await _cipher.decrypt(
        secretBox,
        secretKey: _secretKey!,
      );
      return utf8.decode(clearTextBytes);
    } catch (e) {
      throw Exception('Failed to decrypt data: $e');
    }
  }

  /// Returns true if the service has been initialized (ensures key is available).
  Future<bool> get isInitialized async {
    if (_secretKey != null) return true;
    try {
      await initialize();
      return _secretKey != null;
    } catch (_) {
      return false;
    }
  }
}
