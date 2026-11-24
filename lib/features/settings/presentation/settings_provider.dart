import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile_assistant/core/db/database.dart' show getDatabasesPath;
import 'package:mobile_assistant/core/providers/database_provider.dart';
import 'package:mobile_assistant/core/services/inference_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_provider.g.dart';

class SettingsState {
  const SettingsState({
    this.isAppLockEnabled = false,
    this.themeMode = ThemeMode.dark,
    this.inferenceStrategy = 'hybrid',
    this.isBusy = false,
    this.isDownloadingModel = false,
    this.isLocalModelLoaded = false,
    this.downloadProgress = 0,
    this.modelError,
  });
  final bool isAppLockEnabled;
  final ThemeMode themeMode;
  final String inferenceStrategy;
  final bool isBusy;
  final bool isDownloadingModel;
  final bool isLocalModelLoaded;
  final int downloadProgress;
  final String? modelError;

  SettingsState copyWith({
    bool? isAppLockEnabled,
    ThemeMode? themeMode,
    String? inferenceStrategy,
    bool? isBusy,
    bool? isDownloadingModel,
    bool? isLocalModelLoaded,
    int? downloadProgress,
    String? modelError,
    bool clearModelError = false,
  }) {
    return SettingsState(
      isAppLockEnabled: isAppLockEnabled ?? this.isAppLockEnabled,
      themeMode: themeMode ?? this.themeMode,
      inferenceStrategy: inferenceStrategy ?? this.inferenceStrategy,
      isBusy: isBusy ?? this.isBusy,
      isDownloadingModel: isDownloadingModel ?? this.isDownloadingModel,
      isLocalModelLoaded: isLocalModelLoaded ?? this.isLocalModelLoaded,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      modelError: clearModelError ? null : (modelError ?? this.modelError),
    );
  }
}

@riverpod
class SettingsNotifier extends _$SettingsNotifier {
  final _storage = const FlutterSecureStorage();

  @override
  Future<SettingsState> build() async {
    final isAppLockEnabled =
        await _storage.read(key: 'app_lock_enabled') == 'true';
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
      isAppLockEnabled: isAppLockEnabled,
      themeMode: mode,
      inferenceStrategy: strategyStr,
      isLocalModelLoaded: svc.isLocalModelLoaded,
    );
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
        downloadProgress: 0,
        clearModelError: true,
      ),
    );
    try {
      await InferenceService.instance.downloadAndInstallLocalModel(
        onProgress: (percent) {
          state = AsyncData(state.value!.copyWith(downloadProgress: percent));
        },
      );
      state = AsyncData(
        state.value!.copyWith(
          isDownloadingModel: false,
          isLocalModelLoaded: true,
        ),
      );
    } catch (e) {
      state = AsyncData(
        state.value!.copyWith(
          isDownloadingModel: false,
          modelError: 'Model download failed: $e',
        ),
      );
    }
  }

  Future<void> deleteGemmaModel() async {
    try {
      await InferenceService.instance.deleteLocalModel();
      state = AsyncData(
        state.value!.copyWith(isLocalModelLoaded: false, clearModelError: true),
      );
    } catch (e) {
      state = AsyncData(
        state.value!.copyWith(modelError: 'Could not delete the model: $e'),
      );
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
