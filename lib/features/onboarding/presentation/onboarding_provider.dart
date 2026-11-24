import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile_assistant/core/services/inference_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onboarding_provider.g.dart';

class OnboardingState {
  const OnboardingState({
    this.isDownloading = false,
    this.progress = 0,
    this.error,
    this.isComplete = false,
  });

  final bool isDownloading;
  final int progress;
  final String? error;
  final bool isComplete;

  OnboardingState copyWith({
    bool? isDownloading,
    int? progress,
    String? error,
    bool? isComplete,
    bool clearError = false,
  }) {
    return OnboardingState(
      isDownloading: isDownloading ?? this.isDownloading,
      progress: progress ?? this.progress,
      error: clearError ? null : (error ?? this.error),
      isComplete: isComplete ?? this.isComplete,
    );
  }
}

@riverpod
class OnboardingNotifier extends _$OnboardingNotifier {
  @override
  OnboardingState build() {
    return const OnboardingState();
  }

  Future<void> startDownload() async {
    state = state.copyWith(isDownloading: true, progress: 0, clearError: true);
    try {
      await InferenceService.instance.downloadAndInstallLocalModel(
        onProgress: (percent) => state = state.copyWith(progress: percent),
      );
      await markOnboardingDone();
      state = state.copyWith(isDownloading: false, isComplete: true);
    } catch (e) {
      state = state.copyWith(
        isDownloading: false,
        error:
            'Download failed. Please check your connection and try again.\n\nDetails: $e',
      );
    }
  }

  Future<void> skipForNow() async {
    await markOnboardingDone();
    state = state.copyWith(isComplete: true);
  }
}

const _onboardingDoneKey = 'model_onboarding_done';
const _storage = FlutterSecureStorage();

/// Whether the user has finished or skipped the model setup screen, so it
/// isn't shown again on every launch.
Future<bool> isOnboardingDone() async {
  try {
    return await _storage.read(key: _onboardingDoneKey) == 'true';
  } catch (_) {
    return false;
  }
}

Future<void> markOnboardingDone() async {
  try {
    await _storage.write(key: _onboardingDoneKey, value: 'true');
  } catch (_) {}
}
