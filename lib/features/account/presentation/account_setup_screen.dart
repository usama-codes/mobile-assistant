import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mobile_assistant/core/services/inference_service.dart';
import 'package:mobile_assistant/core/services/profile_service.dart';
import 'package:mobile_assistant/features/lock/presentation/screens/lock_screen.dart';
import 'package:mobile_assistant/features/onboarding/presentation/onboarding_screen.dart';
import 'package:mobile_assistant/features/settings/presentation/settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_assistant/main.dart';
import 'package:mobile_assistant/shared/models/user_profile.dart';

class AccountSetupScreen extends ConsumerStatefulWidget {
  const AccountSetupScreen({super.key});

  @override
  ConsumerState<AccountSetupScreen> createState() => _AccountSetupScreenState();
}

class _AccountSetupScreenState extends ConsumerState<AccountSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _apiKeyController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _apiKeyController.text = dotenv.env['GEMINI_API_KEY'] ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final profile = UserProfile(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
    );

    await ProfileService.instance.saveProfile(profile);
    
    // Set the API key in current session/dotenv map so it works right away
    dotenv.env['GEMINI_API_KEY'] = profile.apiKey;

    final settings = await ref.read(settingsProvider.future);
    final onboardingComplete = await ProfileService.instance.isOnboardingComplete();
    
    if (!mounted) return;

    if (InferenceService.instance.isLocalModelLoaded || onboardingComplete) {
      if (settings.isAppLockEnabled) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LockScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Icon(Icons.person_outline, size: 80, color: theme.colorScheme.primary),
                const SizedBox(height: 24),
                Text(
                  'Welcome to Mobile Assistant',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Let\'s set up your profile and API key so you can start chatting.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.person),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.email),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter your email' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _apiKeyController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Gemini API Key',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.vpn_key),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter your Gemini API Key' : null,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your API key is stored securely on your device.',
                  style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  onPressed: _isLoading ? null : _saveAndContinue,
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text(
                        'Save & Continue',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
