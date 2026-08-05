import 'package:mobile_assistant/core/agent/agent_tool.dart';

class ToolRegistry {
  final Map<String, AgentTool> _tools = {};

  void registerTool(AgentTool tool) {
    _tools[tool.name] = tool;
  }

  void registerTools(List<AgentTool> tools) {
    for (final tool in tools) {
      registerTool(tool);
    }
  }

  AgentTool? getTool(String name) {
    return _tools[name];
  }

  List<AgentTool> get allTools => _tools.values.toList();
}
