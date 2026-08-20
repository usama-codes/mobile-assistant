// ignore_for_file: avoid_dynamic_calls

import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Describes what's wrong (if anything) with the calendar integration.
enum CalendarIssue {
  /// Everything is fine: permission granted and calendars exist.
  ready,

  /// The user hasn't granted CALENDAR permission yet.
  noPermission,

  /// Permission granted but no calendars found — no Google/account on device.
  noAccounts,

  /// Could not determine (plugin error).
  unknown,
}

/// Diagnoses calendar integration status (permission + account presence)
/// so the Settings screen and CalendarTool can show actionable guidance.
class CalendarStatusService {
  CalendarStatusService._();
  static final CalendarStatusService instance = CalendarStatusService._();

  static const _channel = MethodChannel('com.mobile_assistant/platform');
  final _plugin = DeviceCalendarPlugin();

  /// Checks current status. Returns [CalendarIssue] plus a human-readable
  /// description and whether an action button should be shown.
  Future<CalendarStatusResult> checkStatus() async {
    // 1. Permission check
    final hasPerm = await _plugin.hasPermissions();
    if (hasPerm.data != true) {
      return const CalendarStatusResult(
        issue: CalendarIssue.noPermission,
        description: 'Calendar permission not granted.',
        actionLabel: 'Grant permission',
        actionMode: CalendarAction.requestPermission,
      );
    }

    // 2. Account check: can we list calendars?
    try {
      final calsResult = await _plugin.retrieveCalendars();
      final calendars = calsResult.data ?? [];
      if (calendars.isEmpty) {
        return const CalendarStatusResult(
          issue: CalendarIssue.noAccounts,
          description:
              'No calendar accounts found. Add a Google account to use calendar features.',
          actionLabel: 'Add Google account',
          actionMode: CalendarAction.openAccountSettings,
        );
      }
      // Count distinct accounts (by name) — retrieveCalendars() returns
      // individual calendars, not accounts; a single Google account can
      // expose multiple calendars (Primary, Holidays, Birthdays, etc.).
      final accountNames = <String>{};
      for (final cal in calendars) {
        final name = cal.accountName?.trim();
        if (name != null && name is String && name.isNotEmpty) {
          accountNames.add(name);
        }
      }
      final accountCount = accountNames.isEmpty ? 1 : accountNames.length;

      return CalendarStatusResult(
        issue: CalendarIssue.ready,
        description:
            '$accountCount account${accountCount == 1 ? '' : 's'}, '
            '${calendars.length} calendar${calendars.length == 1 ? '' : 's'} found.',
        calendarCount: calendars.length,
      );
    } catch (e) {
      debugPrint('[CalendarStatusService] retrieveCalendars error: $e');
      return const CalendarStatusResult(
        issue: CalendarIssue.unknown,
        description: 'Could not read calendar accounts.',
      );
    }
  }

  /// Requests calendar permission via the plugin.
  Future<bool> requestPermission() async {
    final result = await _plugin.requestPermissions();
    return result.data == true;
  }

  /// Opens the Android "Add account" screen for the given type (Google by default).
  Future<void> openAccountSettings({String accountType = 'com.google'}) async {
    try {
      await _channel.invokeMethod('openAddAccount', {
        'accountType': accountType,
      });
    } catch (e) {
      debugPrint('[CalendarStatusService] openAccountSettings failed: $e');
    }
  }
}

enum CalendarAction { none, requestPermission, openAccountSettings }

class CalendarStatusResult {
  const CalendarStatusResult({
    required this.issue,
    required this.description,
    this.actionLabel,
    this.actionMode = CalendarAction.none,
    this.calendarCount = 0,
  });

  final CalendarIssue issue;
  final String description;
  final String? actionLabel;
  final CalendarAction actionMode;
  final int calendarCount;

  bool get isReady => issue == CalendarIssue.ready;
  bool get needsAction => actionMode != CalendarAction.none;
}
