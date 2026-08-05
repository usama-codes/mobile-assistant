class AgentStep {
  AgentStep(this.description, {this.isCompleted = false, this.result});
  final String description;
  bool isCompleted;
  String? result;
}
