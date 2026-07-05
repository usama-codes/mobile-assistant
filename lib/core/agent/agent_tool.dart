abstract class AgentTool {
  String get name;
  String get description;
  
  /// Execute the tool with the given action and parameters and return a natural language string result.
  Future<String> execute(String action, Map<String, dynamic> parameters);
}
