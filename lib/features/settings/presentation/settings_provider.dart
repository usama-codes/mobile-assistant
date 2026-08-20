import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile_assistant/core/db/database.dart' show getDatabasesPath;
import 'package:mobile_assistant/core/providers/database_provider.dart';
import 'package:mobile_assistant/core/services/inference_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:mobile_assistant/core/services/profile_service.dart';
import 'package:mobile_assistant/shared/models/user_profile.dart';

part 'settings_provider.g.dart';

class SettingsState {
  const SettingsState({
    this.userProfile,
    this.isAppLockEnabled = false,
    this.isTtsEnabled = true,
    this.themeMode = ThemeMode.dark,
    this.inferenceStrategy = 'hybrid',
    this.isBusy = false,
    this.isDownloadingModel = false,
    this.modelDownloadComplete = false,
    this.isLocalModelLoaded = false,
    this.downloadProgress = 0,
  });
  final bool isAppLockEnabled;
  final bool isTtsEnabled;
  final ThemeMode themeMode;
  final String inferenceStrategy;
  final bool isBusy;
  final bool isDownloadingModel;
  final bool modelDownloadComplete;
  final bool isLocalModelLoaded;
  final int downloadProgress;
  final UserProfile? userProfile;

  SettingsState copyWith({
    UserProfile? userProfile,
    bool? isAppLockEnabled,
    bool? isTtsEnabled,
    ThemeMode? themeMode,
    String? inferenceStrategy,
    bool? isBusy,
    bool? isDownloadingModel,
    bool? modelDownloadComplete,
    bool? isLocalModelLoaded,
    int? downloadProgress,
  }) {
    return SettingsState(
      userProfile: userProfile ?? this.userProfile,
      isAppLockEnabled: isAppLockEnabled ?? this.isAppLockEnabled,
      isTtsEnabled: isTtsEnabled ?? this.isTtsEnabled,
      themeMode: themeMode ?? this.themeMode,
      inferenceStrategy: inferenceStrategy ?? this.inferenceStrategy,
      isBusy: isBusy ?? this.isBusy,
      isDownloadingModel: isDownloadingModel ?? this.isDownloadingModel,
      modelDownloadComplete:
          modelDownloadComplete ?? this.modelDownloadComplete,
      isLocalModelLoaded: isLocalModelLoaded ?? this.isLocalModelLoaded,
      downloadProgress: downloadProgress ?? this.downloadProgress,
    );
  }
}

@riverpod
class SettingsNotifier extends _$SettingsNotifier {
  final _storage = const FlutterSecureStorage();

  @override
  Future<SettingsState> build() async {
    final profile = await ProfileService.instance.getProfile();
    final isAppLockEnabled =
        await _storage.read(key: 'app_lock_enabled') == 'true';
    final isTtsEnabled =
        (await _storage.read(key: 'tts_enabled') ?? 'true') == 'true';
    final themeStr = await _storage.read(key: 'theme_mode');

    var mode = ThemeMode.dark;
    if (themeStr == 'light') {
      mode = ThemeMode.light;
    } else if (themeStr == 'system') {
      mode = ThemeMode.system;
    }

    final strategyStr =
        await _storage.read(key: 'inference_strategy') ?? 'hybrid';

    final svc = InferenceService.instance;
    if (strategyStr == 'cloud') {
      svc.strategy = InferenceStrategy.cloudOnly;
    } else if (strategyStr == 'local') {
      svc.strategy = InferenceStrategy.localOnly;
    } else {
      svc.strategy = InferenceStrategy.hybrid;
    }

    return SettingsState(
      userProfile: profile,
      isAppLockEnabled: isAppLockEnabled,
      isTtsEnabled: isTtsEnabled,
      themeMode: mode,
      inferenceStrategy: strategyStr,
    );
  }

  Future<void> updateProfile(UserProfile profile) async {
    await ProfileService.instance.saveProfile(profile);
    state = AsyncData(state.value!.copyWith(userProfile: profile));
  }

  Future<void> setInferenceStrategy(String strategy) async {
    state = AsyncData(state.value!.copyWith(inferenceStrategy: strategy));
    await _storage.write(key: 'inference_strategy', value: strategy);

    // Update the singleton InferenceService
    final svc = InferenceService.instance;
    if (strategy == 'cloud') {
      svc.strategy = InferenceStrategy.cloudOnly;
    } else if (strategy == 'local') {
      svc.strategy = InferenceStrategy.localOnly;
    } else {
      svc.strategy = InferenceStrategy.hybrid;
    }
  }

  Future<void> toggleAppLock(bool value) async {
    state = AsyncData(state.value!.copyWith(isAppLockEnabled: value));
    await _storage.write(key: 'app_lock_enabled', value: value.toString());
  }

  Future<void> toggleTts(bool value) async {
    state = AsyncData(state.value!.copyWith(isTtsEnabled: value));
    await _storage.write(key: 'tts_enabled', value: value.toString());
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = AsyncData(state.value!.copyWith(themeMode: mode));
    var val = 'system';
    if (mode == ThemeMode.light) val = 'light';
    if (mode == ThemeMode.dark) val = 'dark';
    await _storage.write(key: 'theme_mode', value: val);
  }

  Future<String> exportData() async {
    state = AsyncData(state.value!.copyWith(isBusy: true));
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dbPath = await getDatabasesPath();

      final dbFile = File(p.join(dbPath, 'app.db'));
      final extDir = await getExternalStorageDirectory();
      final docsDir = Directory('${extDir?.path ?? appDir.path}/documents');

      final encoder = ZipFileEncoder();
      final zipPath = p.join(appDir.path, 'export.zip');
      encoder.create(zipPath);

      if (await dbFile.exists()) {
        encoder.addFile(dbFile);
      }
      if (await docsDir.exists()) {
        encoder.addDirectory(docsDir);
      }
      encoder.close();

      return zipPath;
    } finally {
      state = AsyncData(state.value!.copyWith(isBusy: false));
    }
  }

  Future<void> downloadGemmaModel() async {
    state = AsyncData(
      state.value!.copyWith(
        isDownloadingModel: true,
        modelDownloadComplete: false,
        downloadProgress: 0,
      ),
    );
    try {
      try {
        await FileDownloader().cancelAll();
      } catch (_) {}

      await Permission.notification.request();

      // Check if file already exists in either location
      final appDocs = await getApplicationDocumentsDirectory();
      final legacyFilePath = p.join(appDocs.path, 'gemma-2b-it-cpu-int4.bin');

      final task = DownloadTask(
        url:
            'https://github.com/usama-codes/gemma-model-hosting/releases/download/v1.0.0/gemma-2b-it-cpu-int4.bin',
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
        FileDownloader().configureNotification(
          running: const TaskNotification(
            'Downloading AI Model',
            'Progress: {progress}%',
          ),
          complete: const TaskNotification(
            'Model Downloaded',
            'The AI model is ready.',
          ),
          error: const TaskNotification('Download Failed', 'Please try again.'),
          paused: const TaskNotification(
            'Download Paused',
            'Waiting for connection...',
          ),
          progressBar: true,
        );

        bool downloadSuccess = false;
        await FileDownloader().download(
          task,
          onProgress: (progress) {
            if (progress > 0) {
              state = AsyncData(
                state.value!.copyWith(
                  downloadProgress: (progress * 100).toInt(),
                ),
              );
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

      await FlutterGemma.installModel(
        modelType: ModelType.gemmaIt,
        fileType: ModelFileType.binary,
      ).fromFile(finalFilePath).install();

      InferenceService.instance.isLocalModelLoaded = true;
      state = AsyncData(
        state.value!.copyWith(
          isDownloadingModel: false,
          modelDownloadComplete: true,
          isLocalModelLoaded: true,
        ),
      );
    } catch (e) {
      state = AsyncData(
        state.value!.copyWith(
          isDownloadingModel: false,
          modelDownloadComplete: false,
        ),
      );
    }
  }

  Future<void> deleteGemmaModel() async {
    try {
      await FlutterGemma.uninstallModel('gemma-2b-it-cpu-int4');
      InferenceService.instance.isLocalModelLoaded = false;
      state = AsyncData(state.value!.copyWith(modelDownloadComplete: false));
    } catch (e) {
      // ignore
    }
  }

  Future<void> deleteAllData() async {
    state = AsyncData(state.value!.copyWith(isBusy: true));
    try {
      final db = ref.read(appDatabaseProvider);
      await db.close();

      final dbPath = await getDatabasesPath();
      final path = p.join(dbPath, 'app.db');
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }

      final appDir = await getApplicationDocumentsDirectory();
      final extDir = await getExternalStorageDirectory();
      final docsDir = Directory('${extDir?.path ?? appDir.path}/documents');
      if (await docsDir.exists()) {
        await docsDir.delete(recursive: true);
      }

      ref.invalidate(appDatabaseProvider);
    } finally {
      state = AsyncData(state.value!.copyWith(isBusy: false));
    }
  }
}
