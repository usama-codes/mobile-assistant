import re

with open('lib/features/memory/memory_vu.dart', 'r') as f:
    code = f.read()

# Replace imports
code = code.replace("import 'package:mobile_assistant/features/memory/memory_vm.dart';", "import 'package:mobile_assistant/features/memory/presentation/providers/memory_providers.dart';\nimport 'package:flutter_riverpod/flutter_riverpod.dart';\nimport 'package:mobile_assistant/features/memory/domain/models/memory_fact.dart';")
code = code.replace("import 'package:stacked/stacked.dart';", "")
code = code.replace("import 'package:intl/intl.dart';", "import 'package:intl/intl.dart';\nimport 'package:flutter_riverpod/flutter_riverpod.dart';")

# Class definition
code = code.replace("class MemoryVU extends StackedView<MemoryVM>", "class MemoryScreen extends ConsumerStatefulWidget")
code = code.replace("const MemoryVU({super.key});", "const MemoryScreen({super.key});\n\n  @override\n  ConsumerState<MemoryScreen> createState() => _MemoryScreenState();\n}\n\nclass _MemoryScreenState extends ConsumerState<MemoryScreen> {")

# Builder method
code = code.replace("Widget builder(BuildContext context, MemoryVM vm, Widget? child) {", "Widget build(BuildContext context) {\n    final memoryAsync = ref.watch(memoryNotifierProvider);\n    final notifier = ref.read(memoryNotifierProvider.notifier);\n")

# Viewmodel hooks
code = re.sub(r'  @override\n  MemoryVM viewModelBuilder\(BuildContext context\) => MemoryVM\(\);\n\n  @override\n  void onViewModelReady\(MemoryVM viewModel\) \{\n    viewModel\.loadMemories\(\);\n  \}\n', '', code)

# State references
code = code.replace("vm.isBusy", "memoryAsync.isLoading")
code = code.replace("vm.memories", "(memoryAsync.value ?? [])")
code = code.replace("vm.deleteMemory", "notifier.deleteMemory")

# Add missing state fields for dialog inputs (the UI previously didn't have inputs for facts?)
# Let's check how facts were added.
# Oh, memory_vu just had a list, not adding facts. Wait, it had a "+" button?
# Let's verify by replacing specific calls.

with open('lib/features/memory/presentation/screens/memory_screen.dart', 'w') as f:
    f.write(code)

print('Refactored memory screen!')
