import re

with open('lib/features/chat/presentation/chat_provider.dart', 'r') as f:
    code = f.read()

# Add AgentService import
code = code.replace("import 'package:mobile_assistant/core/services/action_dispatcher.dart';", "import 'package:mobile_assistant/core/agent/agent_service.dart';")

# Remove _getAgentTools
get_agent_tools_pattern = r'  Tool _getAgentTools\(\) \{.*?\}\n'
code = re.sub(get_agent_tools_pattern, '', code, flags=re.DOTALL)

# In ChatNotifier, replace the call to _getAgentTools
code = code.replace("final tool = _getAgentTools();", "final tool = ref.read(agentServiceProvider).getTools();")

# Replace ActionDispatcher
code = code.replace("await ActionDispatcher.dispatchFunctionCall(call);", "await ref.read(agentServiceProvider).dispatchFunctionCall(call);")

with open('lib/features/chat/presentation/chat_provider.dart', 'w') as f:
    f.write(code)

print('Updated chat provider!')
