import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile_assistant/shared/models/user_profile.dart';

class ProfileService {
  ProfileService._privateConstructor();
  static final ProfileService instance = ProfileService._privateConstructor();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveProfile(UserProfile profile) async {
    await _storage.write(key: 'profile_name', value: profile.name);
    await _storage.write(key: 'profile_email', value: profile.email);
    await _storage.write(key: 'profile_api_key', value: profile.apiKey);
    await _storage.write(key: 'account_created', value: 'true');
  }

  Future<UserProfile?> getProfile() async {
    final name = await _storage.read(key: 'profile_name');
    final email = await _storage.read(key: 'profile_email');
    final apiKey = await _storage.read(key: 'profile_api_key');

    if (name != null && email != null && apiKey != null) {
      return UserProfile(name: name, email: email, apiKey: apiKey);
    }
    return null;
  }

  Future<bool> isAccountCreated() async {
    final value = await _storage.read(key: 'account_created');
    return value == 'true';
  }

  Future<bool> isOnboardingComplete() async {
    final value = await _storage.read(key: 'onboarding_complete');
    return value == 'true';
  }

  Future<void> setOnboardingComplete(bool complete) async {
    await _storage.write(key: 'onboarding_complete', value: complete.toString());
  }
}
