import 'package:mobile_assistant/core/agent/agent_tool.dart';
import 'package:mobile_assistant/core/agent/tools/task_tool.dart';
import 'package:mobile_assistant/core/agent/tools/memory_tool.dart';
import 'package:mobile_assistant/core/agent/tools/document_tool.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ActionDispatcher {
  static final Map<String, AgentTool> _tools = {
    'task_tool': TaskTool(),
    'memory_tool': MemoryTool(),
    'document_tool': DocumentTool(),
  };

  static String _getToolNameForFunction(String functionName) {
    if (functionName.contains('task')) return 'task_tool';
    if (functionName.contains('workload')) return 'task_tool';
    if (functionName.contains('fact')) return 'memory_tool';
    if (functionName.contains('memory')) return 'memory_tool';
    if (functionName.contains('document')) return 'document_tool';
    if (functionName == 'process_nlp') return 'document_tool';
    return 'unknown';
  }

  static Future<Map<String, Object?>> dispatchFunctionCall(FunctionCall call) async {
    if (call.name == 'reply' || call.name == 'ask_user') {
      return {'result': 'Handled by UI'};
    }
    
    final toolName = _getToolNameForFunction(call.name);
    final tool = _tools[toolName];
    if (tool == null) {
      return {'error': 'Tool not found for function'};
    }

    try {
      final result = await tool.execute(call.name, call.args);
      return {'result': result};
    } catch (e) {
      String msg = e.toString();
      if (msg.startsWith('Exception: ')) {
        msg = msg.substring('Exception: '.length);
      }
      return {'error': msg};
    }
  }
}
