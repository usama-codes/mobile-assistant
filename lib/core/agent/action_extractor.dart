import 'dart:convert';

import 'package:mobile_assistant/core/services/analytics_service.dart';
import 'package:mobile_assistant/core/services/inference_service.dart';
import 'package:mobile_assistant/shared/models/action_proposal.dart';

/// Extracts structured action proposals from user messages + RAG context
/// using the LOCAL Gemma model. This is the first step of the
/// extraction → confirm → calendar-write pipeline.
///
/// Runs ALWAYS locally — never sends data to cloud APIs.
class ActionExtractor {
  ActionExtractor._();

  /// The system instruction for the extraction prompt.
  /// Tells Gemma to return ONLY valid JSON with specific fields.
  static const _systemInstruction = r'''
You are a structured action extractor. Your ONLY job is to analyze the user message
and determine if the user wants to create a calendar event, task, or log an expense.

You MUST respond with a single valid JSON object — nothing else.
No explanation, no markdown, no code fences. Just the raw JSON.

JSON schema:
{
  "action": "create_calendar_event" | "create_task" | "log_expense" | "none",
  "title": "string (required — human-readable action title)",
  "startDate": "ISO 8601 datetime or null",
  "endDate": "ISO 8601 datetime or null",
  "description": "string or null",
  "location": "string or null",
  "sourceDocTitle": "string or null — title of referenced document if any",
  "confidence": 0.0 to 1.0
}

Rules:
- For "create_calendar_event": title and startDate are required. endDate defaults to 1 hour after startDate if not specified.
- For "create_task": title is required. startDate is optional (due date).
- For "log_expense": title should describe the expense. Include amount/description from the user message.
- If the user is NOT requesting a specific action (just chatting, asking a question), set "action": "none" and confidence to 0.0.
- Always use the "current time" provided to calculate relative dates (e.g., "next Monday", "tomorrow at 3pm").
- When a document is referenced in the RAG context, set sourceDocTitle to the relevant document title.
- Confidence: 0.9+ = very clear intent; 0.7-0.89 = likely intent but some ambiguity; 0.5-0.69 = weak signal; <0.5 = probably not an action request.
''';

  /// Extract an action proposal from the user's message.
  ///
  /// [userMessage] — the raw user input.
  /// [documentContext] — RAG-retrieved document excerpts (may be empty).
  /// [memoryContext] — RAG-retrieved memory facts (may be empty).
  ///
  /// Returns an [ActionProposal] if extraction succeeded, or null if:
  /// - Local model is not loaded
  /// - The model output could not be parsed as valid JSON
  /// - The action is "none" (no actionable intent detected)
  /// - Confidence is below the minimum threshold
  static Future<ActionProposal?> extract({
    required String userMessage,
    String documentContext = '',
    String memoryContext = '',
  }) async {
    final svc = InferenceService.instance;

    // Local model must be available for extraction
    if (!svc.isLocalModelLoaded) {
      logger.w('ActionExtractor: local model not loaded, skipping extraction');
      return null;
    }

    final now = DateTime.now();
    final prompt = _buildPrompt(
      userMessage: userMessage,
      documentContext: documentContext,
      memoryContext: memoryContext,
      currentTime: now,
    );

    try {
      final responseText = await svc.generateLocalOnly(
        systemInstruction: _systemInstruction,
        prompt: prompt,
      );

      if (responseText == null || responseText.trim().isEmpty) {
        logger.w('ActionExtractor: empty response from local model');
        return null;
      }

      return _parseResponse(responseText);
    } catch (e) {
      logger.e('ActionExtractor: extraction failed', error: e);
      return null;
    }
  }

  /// Build the extraction prompt combining user input + RAG context.
  static String _buildPrompt({
    required String userMessage,
    required String documentContext,
    required String memoryContext,
    required DateTime currentTime,
  }) {
    final parts = <String>[
      'CURRENT TIME: ${currentTime.toIso8601String()}',
      '',
      'USER MESSAGE:',
      userMessage,
    ];

    if (documentContext.isNotEmpty &&
        documentContext != 'No relevant documents found.') {
      parts.addAll([
        '',
        'RELEVANT DOCUMENT EXCERPTS:',
        documentContext,
      ]);
    }

    if (memoryContext.isNotEmpty &&
        memoryContext != 'No relevant memories found.') {
      parts.addAll(['', 'RELEVANT MEMORIES:', memoryContext]);
    }

    parts.addAll([
      '',
      'Analyze the user message and respond with ONLY the JSON object as specified.',
    ]);

    return parts.join('\n');
  }

  /// Parse the model's JSON response into an ActionProposal.
  static ActionProposal? _parseResponse(String responseText) {
    // Strip potential markdown code fences the model might add despite instructions
    var cleaned = responseText.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned
          .replaceAll(RegExp(r'^```\w*\n?'), '')
          .replaceAll(RegExp(r'\n?```$'), '');
    }

    // Try to find a JSON object in the response
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(cleaned);
    if (jsonMatch == null) {
      logger.w('ActionExtractor: no JSON object found in response');
      return null;
    }

    try {
      final json = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;

      final action = json['action'] as String? ?? 'none';
      if (action == 'none') {
        logger.i('ActionExtractor: no actionable intent detected');
        return null;
      }

      final title = json['title'] as String?;
      if (title == null || title.trim().isEmpty) {
        logger.w('ActionExtractor: missing title in proposal');
        return null;
      }

      final confidence =
          (json['confidence'] as num?)?.toDouble() ?? 0.5;
      if (confidence < 0.5) {
        logger.i('ActionExtractor: confidence too low ($confidence), skipping');
        return null;
      }

      DateTime? parseDate(dynamic value) {
        if (value == null) return null;
        try {
          return DateTime.parse(value as String);
        } catch (_) {
          return null;
        }
      }

      return ActionProposal(
        action: action,
        title: title.trim(),
        startDate: parseDate(json['startDate']),
        endDate: parseDate(json['endDate']),
        description: json['description'] as String?,
        location: json['location'] as String?,
        sourceDocTitle: json['sourceDocTitle'] as String?,
        sourceDocId: json['sourceDocId'] as int?,
        confidence: confidence,
      );
    } catch (e) {
      logger.e('ActionExtractor: failed to parse JSON', error: e);
      return null;
    }
  }
}
