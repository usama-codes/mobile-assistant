import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart';
import 'dart:convert';
import 'dart:math';

class CryptoService {
  static const storage = FlutterSecureStorage();
  static const _keyName = 'encryption_key';

  static Future<Key> _getKey() async {
    String? keyString = await storage.read(key: _keyName);
    if (keyString == null) {
      final random = Random.secure();
      final keyBytes = List<int>.generate(32, (i) => random.nextInt(256));
      keyString = base64UrlEncode(keyBytes);
      await storage.write(key: _keyName, value: keyString);
    }
    return Key.fromBase64(keyString);
  }

  static Future<String> encrypt(String plainText) async {
    final key = await _getKey();
    final iv = IV.fromLength(16);
    final encrypter = Encrypter(AES(key));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  static Future<String> decrypt(String encryptedText) async {
    if (!encryptedText.contains(':')) return encryptedText; // Not encrypted
    final parts = encryptedText.split(':');
    final iv = IV.fromBase64(parts[0]);
    final encrypted = Encrypted.fromBase64(parts[1]);
    final key = await _getKey();
    final encrypter = Encrypter(AES(key));
    return encrypter.decrypt(encrypted, iv: iv);
  }
}
