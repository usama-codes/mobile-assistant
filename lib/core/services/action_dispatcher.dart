import 'package:mobile_assistant/shared/models/agent_action.dart';
import 'package:mobile_assistant/core/agent/agent_tool.dart';
import 'package:mobile_assistant/core/agent/tools/task_tool.dart';
import 'package:mobile_assistant/core/agent/tools/memory_tool.dart';
import 'package:mobile_assistant/core/agent/tools/document_tool.dart';

class ActionDispatcher {
  static final Map<String, AgentTool> _tools = {
    'task_tool': TaskTool(),
    'memory_tool': MemoryTool(),
    'document_tool': DocumentTool(),
  };

  static Future<List<String>> dispatchAll(List<AgentAction> actions) async {
    List<String> results = [];
    
    for (var action in actions) {
      if (action.tool == 'core' && action.action == 'other') {
        if (action.reply != null && action.reply!.isNotEmpty) {
          results.add(action.reply!);
        }
        continue;
      }
      
      final tool = _tools[action.tool];
      if (tool == null) {
        results.add("Error: Tool '${action.tool}' not found.");
        continue;
      }

      try {
        final result = await tool.execute(action.action, action.parameters);
        results.add(result);
      } catch (e) {
        String msg = e.toString();
        if (msg.startsWith('Exception: ')) {
          msg = msg.substring('Exception: '.length);
        }
        results.add("Error: $msg");
      }
    }

    if (results.isEmpty) {
      results.add("Done.");
    }

    return results;
  }
}
