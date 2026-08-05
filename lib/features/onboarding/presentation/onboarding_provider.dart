import 'dart:io';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mobile_assistant/core/services/inference_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

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
      // Force clear any stuck/orphaned background downloads that might be holding a lock
      try {
        await FileDownloader().cancelAll();
      } catch (_) {}

      // Prompt for notifications (needed for Android 13+ Foreground Service)
      await Permission.notification.request();

      // Check if file already exists in either location
      final appDocs = await getApplicationDocumentsDirectory();
      final legacyFilePath = p.join(appDocs.path, 'gemma-2b-it-cpu-int4.bin');
      
      final task = DownloadTask(
        url: 'https://github.com/usama-codes/gemma-model-hosting/releases/download/v1.0.0/gemma-2b-it-cpu-int4.bin',
        filename: 'gemma-2b-it-cpu-int4.bin',
        directory: 'models',
        baseDirectory: BaseDirectory.applicationSupport,
        updates: Updates.statusAndProgress,
        retries: 5,
        allowPause: true,
      );

      final newFilePath = await task.filePath();
      String? finalFilePath;

      if (File(legacyFilePath).existsSync()) {
        finalFilePath = legacyFilePath;
      } else if (File(newFilePath).existsSync()) {
        finalFilePath = newFilePath;
      }

      if (finalFilePath == null) {
        // We MUST configure the notification for Android 14+ to allow a foreground service
        FileDownloader().configureNotification(
          running: const TaskNotification('Downloading AI Model', 'Progress: {progress}%'),
          complete: const TaskNotification('Model Downloaded', 'The AI model is ready.'),
          error: const TaskNotification('Download Failed', 'Please try again.'),
          paused: const TaskNotification('Download Paused', 'Waiting for connection...'),
          progressBar: true,
        );
        
        // Start download
        bool downloadSuccess = false;
        await FileDownloader().download(
          task,
          onProgress: (progress) {
            if (progress > 0) {
              state = state.copyWith(progress: (progress * 100).toInt());
            }
          },
          onStatus: (status) {
            if (status == TaskStatus.complete) {
              downloadSuccess = true;
            }
          },
        );

        if (!downloadSuccess) {
          throw Exception('Download did not complete successfully.');
        }
        finalFilePath = newFilePath;
      }

      // Install it into Gemma
      await FlutterGemma.installModel(
        modelType: ModelType.gemmaIt,
        fileType: ModelFileType.binary,
      )
      .fromFile(finalFilePath)
      .install();

      InferenceService.instance.isLocalModelLoaded = true;
      state = state.copyWith(isDownloading: false, isComplete: true);
    } catch (e) {
      state = state.copyWith(
        isDownloading: false,
        error: 'Download failed. Please check your connection and try again.\n\nDetails: $e',
      );
    }
  }

  void skipForNow() {
    state = state.copyWith(isComplete: true);
  }
}
