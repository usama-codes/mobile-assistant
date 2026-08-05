import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_assistant/features/onboarding/presentation/onboarding_provider.dart';
import 'package:mobile_assistant/features/lock/presentation/screens/lock_screen.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final theme = Theme.of(context);

    // Watch for completion to route forward
    ref.listen<OnboardingState>(onboardingProvider, (previous, current) {
      if (current.isComplete) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LockScreen()),
        );
      }
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Icon(Icons.memory, size: 80, color: theme.colorScheme.primary),
              const SizedBox(height: 32),
              Text(
                'AI Model Setup',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'To use the assistant fully offline, we need to download the Gemma AI model (1.35 GB).\n\nThis might take a few minutes depending on your connection.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: theme.textTheme.bodyMedium?.color?.withValues(
                    alpha: 0.8,
                  ),
                ),
              ),
              const Spacer(),
              if (state.error != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          state.error!,
                          style: TextStyle(
                            color: theme.textTheme.bodySmall?.color,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              if (state.isDownloading) ...[
                Text(
                  'Downloading... ${state.progress}%',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: state.progress > 0 ? state.progress / 100 : null,
                    minHeight: 8,
                    backgroundColor: theme.colorScheme.primary.withValues(
                      alpha: 0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
                onPressed: state.isDownloading
                    ? null
                    : () {
                        ref.read(onboardingProvider.notifier).startDownload();
                      },
                child: Text(
                  state.error != null ? 'Retry Download' : 'Start Download',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: state.isDownloading
                    ? null
                    : () {
                        ref.read(onboardingProvider.notifier).skipForNow();
                      },
                child: Text(
                  'Skip for now (Cloud Mode Only)',
                  style: TextStyle(color: theme.disabledColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
