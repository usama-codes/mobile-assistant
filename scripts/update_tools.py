import re

def update_tool(filename, classname, functions, conditions):
    with open(filename, 'r') as f:
        code = f.read()
    
    decl_str = "  @override\n  List<FunctionDeclaration> get declarations => [\n"
    for func in functions:
        decl_str += f"    {func},\n"
    decl_str += "  ];\n\n"
    
    can_handle_str = "  @override\n  bool canHandle(String functionName) {\n    return " + " || ".join(conditions) + ";\n  }\n\n"
    
    # Add imports
    if "import 'package:google_generative_ai/google_generative_ai.dart';" not in code:
        code = code.replace("import 'package:mobile_assistant/core/agent/agent_tool.dart';", "import 'package:mobile_assistant/core/agent/agent_tool.dart';\nimport 'package:google_generative_ai/google_generative_ai.dart';")
        
    code = code.replace(f"class {classname} implements AgentTool {{", f"class {classname} implements AgentTool {{\n{decl_str}{can_handle_str}")
    
    with open(filename, 'w') as f:
        f.write(code)

# TaskTool
update_tool('lib/core/agent/tools/task_tool.dart', 'TaskTool', [
    """FunctionDeclaration(
          'create_task',
          'Create a new task',
          Schema(SchemaType.object, properties: {
            'title': Schema(SchemaType.string),
            'description': Schema(SchemaType.string),
            'dueDate': Schema(SchemaType.string, description: 'ISO8601 string'),
            'priority': Schema(SchemaType.string, description: 'low, medium, high'),
          }, requiredProperties: ['title']),
        )""",
    """FunctionDeclaration(
          'edit_task',
          'Edit an existing task',
          Schema(SchemaType.object, properties: {
            'id': Schema(SchemaType.integer),
            'title': Schema(SchemaType.string),
            'dueDate': Schema(SchemaType.string),
          }, requiredProperties: ['id']),
        )""",
    """FunctionDeclaration(
          'delete_task',
          'Delete a task',
          Schema(SchemaType.object, properties: {'id': Schema(SchemaType.integer)}, requiredProperties: ['id']),
        )"""
], ["functionName == 'create_task'", "functionName == 'edit_task'", "functionName == 'delete_task'"])

# MemoryTool
update_tool('lib/core/agent/tools/memory_tool.dart', 'MemoryTool', [
    """FunctionDeclaration(
          'remember_fact',
          'Save a fact to long-term memory',
          Schema(SchemaType.object, properties: {
            'fact': Schema(SchemaType.string),
            'importance': Schema(SchemaType.number),
            'is_sensitive': Schema(SchemaType.boolean),
          }, requiredProperties: ['fact']),
        )"""
], ["functionName == 'remember_fact'"])

# DocumentTool
update_tool('lib/core/agent/tools/document_tool.dart', 'DocumentTool', [
    """FunctionDeclaration(
          'create_document',
          'Save a document',
          Schema(SchemaType.object, properties: {
            'title': Schema(SchemaType.string),
            'content': Schema(SchemaType.string),
            'folder': Schema(SchemaType.string),
            'is_sensitive': Schema(SchemaType.boolean),
          }, requiredProperties: ['title', 'content']),
        )""",
    """FunctionDeclaration(
          'process_nlp',
          'Process document with NLP',
          Schema(SchemaType.object, properties: {
            'id': Schema(SchemaType.integer),
            'operation': Schema(SchemaType.string, description: 'summarize, translate, extract_entities, extract_keywords, generate_flashcards, generate_study_guide, extract_tasks'),
          }, requiredProperties: ['id', 'operation']),
        )"""
], ["functionName == 'create_document'", "functionName == 'process_nlp'"])

print('Updated tools!')
