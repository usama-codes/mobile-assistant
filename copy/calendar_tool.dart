import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:mobile_assistant/core/agent/agent_tool.dart';
import 'package:mobile_assistant/core/services/calendar_status_service.dart';
import 'package:timezone/timezone.dart' as tz;

class CalendarTool implements AgentTool {
  static final _plugin = DeviceCalendarPlugin();
  static bool _permissionsGranted = false;

  @override
  String get name => 'calendar_tool';

  @override
  String get description =>
      'Create and read events in the device native calendar.';

  @override
  List<FunctionDeclaration> get declarations => [
    FunctionDeclaration(
      'create_calendar_event',
      'Create an event in the native device calendar',
      Schema(SchemaType.object, properties: {
        'title':       Schema(SchemaType.string),
        'startDate':   Schema(SchemaType.string, description: 'ISO 8601 datetime'),
        'endDate':     Schema(SchemaType.string, description: 'ISO 8601 datetime'),
        'description': Schema(SchemaType.string),
        'location':    Schema(SchemaType.string),
      }, requiredProperties: ['title', 'startDate', 'endDate']),
    ),
    FunctionDeclaration(
      'get_upcoming_events',
      'List upcoming calendar events in the next N days',
      Schema(SchemaType.object, properties: {
        'daysAhead': Schema(SchemaType.integer,
            description: 'How many days ahead to look, default 7'),
      }),
    ),
  ];

  @override
  bool canHandle(String functionName) =>
      {'create_calendar_event', 'get_upcoming_events'}.contains(functionName);

  Future<bool> _ensurePermissions() async {
    if (_permissionsGranted) return true;
    try {
      final hasResult = await _plugin.hasPermissions();
      debugPrint('[CalendarTool] hasPermissions: ${hasResult.data}');
      if (hasResult.data != true) {
        final reqResult = await _plugin.requestPermissions();
        debugPrint('[CalendarTool] requestPermissions: ${reqResult.data}, errors: ${reqResult.errors}');
        if (reqResult.data != true) return false;
      }
      _permissionsGranted = true;
      return true;
    } catch (e) {
      debugPrint('[CalendarTool] Permission error: $e');
      return false;
    }
  }

  @override
  Future<String> execute(String action, Map<String, dynamic> params) async {
    final permitted = await _ensurePermissions();
    if (!permitted) {
      return 'Calendar permission is required. Grant it in: Settings → Apps → Mobile Assistant → Permissions → Calendar.';
    }

    // Pre-flight: verify a calendar account actually exists on the device.
    if (action == 'create_calendar_event') {
      final status = await CalendarStatusService.instance.checkStatus();
      if (status.issue == CalendarIssue.noAccounts) {
        return 'No calendar accounts found on this device. '
            'Add a Google account first (Settings tab → Calendar Integration → Add account), '
            'then try again.';
      }
    }

    switch (action) {
      case 'create_calendar_event':
        try {
          final calsResult = await _plugin.retrieveCalendars();
          debugPrint('[CalendarTool] retrieveCalendars isSuccess: ${calsResult.isSuccess}, errors: ${calsResult.errors}');

          final allCals = calsResult.data ?? [];
          debugPrint('[CalendarTool] Total calendars: ${allCals.length}');
          for (final c in allCals) {
            debugPrint('[CalendarTool]   - "${c.name}" id=${c.id} isReadOnly=${c.isReadOnly}');
          }

          // Prefer writable calendars; fall back to all if none found
          var writableCals = allCals.where((c) => c.isReadOnly == false).toList();
          if (writableCals.isEmpty) writableCals = allCals;
          if (writableCals.isEmpty) {
            return 'No calendars found on device. Please open your Calendar app and ensure at least one calendar is configured.';
          }

          // Prioritize Google Calendar accounts
          Calendar? selectedCal;
          try {
            selectedCal = writableCals.firstWhere((c) {
              final type = c.accountType?.toLowerCase() ?? '';
              final name = c.accountName?.toLowerCase() ?? '';
              return type.contains('com.google') || name.contains('@gmail.com');
            });
          } catch (_) {
            selectedCal = null;
          }
          selectedCal ??= writableCals.first;

          final calId = selectedCal!.id!;
          debugPrint('[CalendarTool] Using calendar id=$calId');

          final start = DateTime.parse(params['startDate'] as String);
          final end   = DateTime.parse(params['endDate']   as String);

          final event = Event(calId)
            ..title       = params['title'] as String
            ..start       = tz.TZDateTime.from(start, tz.local)
            ..end         = tz.TZDateTime.from(end,   tz.local)
            ..description = params['description'] as String? ?? ''
            ..location    = params['location']    as String? ?? '';

          final result = await _plugin.createOrUpdateEvent(event);
          debugPrint('[CalendarTool] createOrUpdateEvent isSuccess=${result?.isSuccess} data=${result?.data} errors=${result?.errors}');

          if (result?.isSuccess == true && result!.data != null) {
            return "✅ '${params['title']}' added to your calendar for ${start.toLocal()}.";
          }

          final errMsgs = result?.errors.map((e) => e.errorMessage).join(', ') ?? 'Unknown error';
          return 'Event creation failed: $errMsgs';
        } catch (e, st) {
          debugPrint('[CalendarTool] create error: $e\n$st');
          return 'Error creating event: $e';
        }

      case 'get_upcoming_events':
        try {
          final days = (params['daysAhead'] as int?) ?? 7;
          final now  = DateTime.now();
          final end  = now.add(Duration(days: days));

          final calsResult = await _plugin.retrieveCalendars();
          final calendars  = calsResult.data ?? [];
          if (calendars.isEmpty) return 'No calendars found.';

          final buffer = StringBuffer();
          for (final cal in calendars) {
            final eventsResult = await _plugin.retrieveEvents(
              cal.id,
              RetrieveEventsParams(startDate: now, endDate: end),
            );
            for (final e in eventsResult.data ?? []) {
              buffer.writeln('- ${e.title} | ${e.start?.toLocal()} → ${e.end?.toLocal()}');
            }
          }
          return buffer.isEmpty
              ? 'No events in the next $days days.'
              : buffer.toString();
        } catch (e) {
          debugPrint('[CalendarTool] fetch error: $e');
          return 'Error fetching events: $e';
        }

      default:
        return 'Unknown action: $action';
    }
  }
}
