// ignore_for_file: unused_local_variable, deprecated_member_use

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

final logger = Logger(
  printer: PrettyPrinter(
    printTime: false, // Should each log print contain a timestamp
  ),
);

class AnalyticsService {
  factory AnalyticsService() {
    return _instance;
  }

  AnalyticsService._internal();
  static final AnalyticsService _instance = AnalyticsService._internal();

  // final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {
    try {
      final safeParams = parameters?.map(
        (key, value) => MapEntry(key, value as Object),
      );
      // await _analytics.logEvent(name: name, parameters: safeParams);
      logger.i('Analytics Event: $name | Params: $parameters');
    } catch (e, stackTrace) {
      logger.e(
        'Failed to log analytics event',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> logScreenView(String screenName) async {
    try {
      // await _analytics.logEvent(
      //   name: 'screen_view',
      //   parameters: {
      //     'firebase_screen': screenName,
      //     'firebase_screen_class': screenName,
      //   },
      // );
      logger.i('Screen View: $screenName');
    } catch (e, stackTrace) {
      logger.e('Failed to log screen view', error: e, stackTrace: stackTrace);
    }
  }

  void recordError(
    dynamic exception,
    StackTrace? stack, {
    dynamic reason,
    bool fatal = false,
  }) {
    logger.e('Recorded Error: $reason', error: exception, stackTrace: stack);
    if (!kIsWeb) {
      // FirebaseCrashlytics.instance.recordError(exception, stack, reason: reason, fatal: fatal);
    }
  }

  void recordFlutterFatalError(FlutterErrorDetails flutterErrorDetails) {
    logger.f(
      'Fatal Flutter Error',
      error: flutterErrorDetails.exception,
      stackTrace: flutterErrorDetails.stack,
    );
    if (!kIsWeb) {
      // FirebaseCrashlytics.instance.recordFlutterFatalError(flutterErrorDetails);
    }
  }

  void recordFlutterError(FlutterErrorDetails flutterErrorDetails) {
    logger.e(
      'Flutter Error',
      error: flutterErrorDetails.exception,
      stackTrace: flutterErrorDetails.stack,
    );
    if (!kIsWeb) {
      // FirebaseCrashlytics.instance.recordFlutterError(flutterErrorDetails);
    }
  }
}
