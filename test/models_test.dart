import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_assistant/shared/models/chat_session.dart';
import 'package:mobile_assistant/shared/models/task_item.dart';

void main() {
  group('Models Test', () {
    test('TaskItem fromJson / toJson', () {
      final json = {
        'id': 1,
        'title': 'Test',
        'description': 'Desc',
        'dueDate': '2023-01-01T00:00:00.000',
        'completed': 0,
        'priority': 'high',
      };
      
      final task = TaskItem.fromMap(json);
      expect(task.id, 1);
      expect(task.title, 'Test');
      expect(task.completed, false);
      
      final out = task.toMap();
      expect(out['priority'], 'high');
    });
    
    test('ChatSession fromMap', () {
      final json = {
        'id': 1,
        'title': 'Session 1',
        'createdAt': '2023-01-01T00:00:00.000',
        'updatedAt': '2023-01-01T00:00:00.000',
        'systemPrompt': 'Be helpful',
      };
      
      final session = ChatSession.fromMap(json);
      expect(session.title, 'Session 1');
    });
  });
}
