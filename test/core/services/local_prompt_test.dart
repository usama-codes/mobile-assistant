import 'package:flutter_test/flutter_test.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:mobile_assistant/core/services/inference_service.dart';

void main() {
  group('InferenceService.buildLocalMessages', () {
    test('puts the system instruction in the first user turn', () {
      final messages = InferenceService.buildLocalMessages(
        chatHistory: [Content.text('hello'), Content.model([TextPart('hi!')])],
        prompt: Content.text('what time is it?'),
        systemInstruction: 'Be brief.',
        charBudget: 1000,
      );

      expect(messages, hasLength(3));
      expect(messages.first.isUser, isTrue);
      expect(messages.first.text, startsWith('System instruction: Be brief.'));
      expect(messages.first.text, endsWith('hello'));
      expect(messages.last.text, 'what time is it?');
    });

    test('drops the oldest turns to fit the budget', () {
      final history = [
        for (var i = 0; i < 20; i++) ...[
          Content.text('question $i ${'x' * 50}'),
          Content.model([TextPart('answer $i ${'y' * 50}')]),
        ],
      ];

      final messages = InferenceService.buildLocalMessages(
        chatHistory: history,
        prompt: Content.text('latest'),
        systemInstruction: 'sys',
        charBudget: 400,
      );

      final total = messages.fold<int>(0, (sum, m) => sum + m.text.length);
      expect(total, lessThan(450));
      expect(messages.first.isUser, isTrue);
      expect(messages.last.text, 'latest');
      expect(messages.any((m) => m.text.contains('question 0 ')), isFalse);
    });

    test('works with no history and clips a huge prompt', () {
      final messages = InferenceService.buildLocalMessages(
        chatHistory: const [],
        prompt: Content.text('z' * 5000),
        systemInstruction: 'sys',
        charBudget: 1000,
      );

      expect(messages, hasLength(1));
      expect(messages.single.text.length, lessThan(1100));
    });
  });
}
