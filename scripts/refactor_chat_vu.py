import re

with open('lib/features/chat/chat_vu.dart', 'r') as f:
    code = f.read()

# Replace imports
code = code.replace("import 'package:mobile_assistant/features/chat/chat_vm.dart';", "import 'package:mobile_assistant/features/chat/presentation/chat_provider.dart';\nimport 'package:flutter_riverpod/flutter_riverpod.dart';")
code = code.replace("import 'package:stacked/stacked.dart';", "")

# Replace class definition
code = code.replace("class ChatVU extends StackedView<ChatVM>", "class ChatScreen extends ConsumerStatefulWidget")
code = code.replace("const ChatVU({super.key, this.initialSession});", "const ChatScreen({super.key, this.initialSession});\n\n  @override\n  ConsumerState<ChatScreen> createState() => _ChatScreenState();\n}\n\nclass _ChatScreenState extends ConsumerState<ChatScreen> {")
code = code.replace("Widget builder(BuildContext context, ChatVM vm, Widget? child) {", "Widget build(BuildContext context) {\n    final state = ref.watch(chatNotifierProvider);\n    final notifier = ref.read(chatNotifierProvider.notifier);\n")

code = re.sub(r'  @override\n  ChatVM viewModelBuilder\(BuildContext context\) => ChatVM\(\);\n\n  @override\n  void onViewModelReady\(ChatVM viewModel\) \{\n    viewModel\.loadSessions\(\);\n  \}\n', '', code)

# Replace vm calls with state or notifier
code = code.replace("vm.sessions", "state.sessions")
code = code.replace("vm.currentSession", "state.currentSession")
code = code.replace("vm.hasError", "(state.modelError != null)")
code = code.replace("vm.modelError", "state.modelError")
code = code.replace("vm.messages", "state.messages")
code = code.replace("vm.isGenerating", "state.isGenerating")
code = code.replace("vm.currentPlan", "state.currentPlan")
code = code.replace("vm.selectedImagePath", "state.selectedImagePath")
code = code.replace("vm.pendingAttachmentPath", "state.pendingAttachmentPath")
code = code.replace("vm.isProcessingImage", "state.isProcessingImage")

code = code.replace("vm.", "notifier.")

code = code.replace("Widget _buildShortcut(BuildContext context, ChatVM vm, String text)", "Widget _buildShortcut(BuildContext context, ChatNotifier notifier, String text)")
code = code.replace("_buildShortcut(context, vm", "_buildShortcut(context, notifier")

# messageController needs to be in the state class
code = code.replace("class _ChatScreenState extends ConsumerState<ChatScreen> {", "class _ChatScreenState extends ConsumerState<ChatScreen> {\n  final TextEditingController _messageController = TextEditingController();\n\n  @override\n  void dispose() {\n    _messageController.dispose();\n    super.dispose();\n  }\n")
code = code.replace("notifier.messageController", "_messageController")

with open('lib/features/chat/presentation/chat_screen.dart', 'w') as f:
    f.write(code)

print('Refactored chat screen!')
