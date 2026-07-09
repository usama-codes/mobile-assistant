class AgentStep {
  final String description;
  bool isCompleted;
  String? result;
  
  AgentStep(this.description, {this.isCompleted = false, this.result});
}
