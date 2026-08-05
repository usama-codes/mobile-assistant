import 'package:google_generative_ai/google_generative_ai.dart';

abstract class AgentTool {
  String get name;
  String get description;
  List<FunctionDeclaration> get declarations;
  
  bool canHandle(String functionName);
  
  /// Execute the tool with the given action and parameters and return a natural language string result.
  Future<String> execute(String action, Map<String, dynamic> parameters);
}
