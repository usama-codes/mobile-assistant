import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:mobile_assistant/core/agent/tool_registry.dart';
import 'package:mobile_assistant/core/agent/tools/calendar_tool.dart';
import 'package:mobile_assistant/core/agent/tools/document_tool.dart';
import 'package:mobile_assistant/core/agent/tools/expense_tool.dart';
import 'package:mobile_assistant/core/agent/tools/memory_tool.dart';
import 'package:mobile_assistant/core/agent/tools/task_tool.dart';
import 'package:mobile_assistant/core/db/expense_repository.dart';
import 'package:mobile_assistant/features/memory/presentation/providers/memory_providers.dart';
import 'package:mobile_assistant/features/tasks/data/task_repository.dart';

class AgentService {
  AgentService(this.registry);
  final ToolRegistry registry;

  Tool getTools() {
    return Tool(
      functionDeclarations: [
        FunctionDeclaration(
          'create_execution_plan',
          'State a multi-step execution plan before executing complex requests',
          Schema(
            SchemaType.object,
            properties: {
              'steps': Schema(
                SchemaType.array,
                items: Schema(SchemaType.string),
              ),
            },
            requiredProperties: ['steps'],
          ),
        ),
        FunctionDeclaration(
          'ask_user',
          'Ask the user a clarifying question to resolve ambiguity',
          Schema(
            SchemaType.object,
            properties: {'question': Schema(SchemaType.string)},
            requiredProperties: ['question'],
          ),
        ),
        // Aggregate from registry
        ...registry.allTools.expand((tool) => tool.declarations),
      ],
    );
  }

  Future<Map<String, Object?>> dispatchFunctionCall(FunctionCall call) async {
    if (call.name == 'reply' ||
        call.name == 'ask_user' ||
        call.name == 'create_execution_plan') {
      return {'result': 'Handled by UI'};
    }

    // Find the tool that can handle this function
    for (final tool in registry.allTools) {
      if (tool.canHandle(call.name)) {
        try {
          final result = await tool.execute(call.name, call.args);
          return {'result': result};
        } catch (e) {
          var msg = e.toString();
          if (msg.startsWith('Exception: ')) {
            msg = msg.substring('Exception: '.length);
          }
          return {'error': msg};
        }
      }
    }

    return {'error': 'Tool not found for function ${call.name}'};
  }
}

final toolRegistryProvider = Provider<ToolRegistry>((ref) {
  // Inject proper repositories so tools use the correct data layer:
  // - TaskTool now uses Drift (reactive streams → UI auto-updates)
  // - MemoryTool now uses ObjectBox (fixes memories being lost to dropped table)
  final taskRepo = ref.watch(taskRepositoryProvider);
  final memoryRepo = ref.watch(memoryRepositoryProvider);
  final expenseRepo = ExpenseRepository();
  final registry = ToolRegistry();
  registry.registerTools([
    TaskTool(taskRepo),
    MemoryTool(memoryRepo),
    DocumentTool(),
    CalendarTool(),
    ExpenseTool(expenseRepo),
  ]);
  return registry;
});

final agentServiceProvider = Provider<AgentService>(
  (ref) => AgentService(ref.watch(toolRegistryProvider)),
);
