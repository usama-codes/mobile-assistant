import re

with open('lib/core/agent/agent_service.dart', 'r') as f:
    code = f.read()

code = "import 'package:flutter_riverpod/flutter_riverpod.dart';\n" + code
code += "\nfinal toolRegistryProvider = Provider<ToolRegistry>((ref) {\n  final registry = ToolRegistry();\n  registry.registerTools([TaskTool(), MemoryTool(), DocumentTool()]);\n  return registry;\n});\n"
code += "\nfinal agentServiceProvider = Provider<AgentService>((ref) => AgentService(ref.watch(toolRegistryProvider)));\n"

code = code.replace("import 'package:mobile_assistant/core/agent/tool_registry.dart';", "import 'package:mobile_assistant/core/agent/tool_registry.dart';\nimport 'package:mobile_assistant/core/agent/tools/task_tool.dart';\nimport 'package:mobile_assistant/core/agent/tools/memory_tool.dart';\nimport 'package:mobile_assistant/core/agent/tools/document_tool.dart';")

with open('lib/core/agent/agent_service.dart', 'w') as f:
    f.write(code)

print('Updated agent service with providers!')
