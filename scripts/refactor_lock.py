import re

with open('lib/features/lock/lock_screen_vu.dart', 'r') as f:
    code = f.read()

# Replace imports
code = code.replace("import 'package:mobile_assistant/features/lock/lock_screen_vm.dart';", "import 'package:mobile_assistant/features/lock/presentation/providers/lock_providers.dart';\nimport 'package:flutter_riverpod/flutter_riverpod.dart';\nimport 'package:mobile_assistant/main.dart';")
code = code.replace("import 'package:stacked/stacked.dart';", "")

# Class definition
code = code.replace("class LockScreenVU extends StackedView<LockScreenVM>", "class LockScreen extends ConsumerStatefulWidget")
code = code.replace("const LockScreenVU({super.key});", "const LockScreen({super.key});\n\n  @override\n  ConsumerState<LockScreen> createState() => _LockScreenState();\n}\n\nclass _LockScreenState extends ConsumerState<LockScreen> {")

# Builder method
code = code.replace("Widget builder(BuildContext context, LockScreenVM vm, Widget? child) {", "Widget build(BuildContext context) {\n    final authState = ref.watch(lockNotifierProvider);\n\n    ref.listen(lockNotifierProvider, (previous, next) {\n      if (next.value == true) {\n        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));\n      }\n    });\n")

# Viewmodel hooks
code = re.sub(r'  @override\n  LockScreenVM viewModelBuilder\(BuildContext context\) => LockScreenVM\(\);\n\n  @override\n  void onViewModelReady\(LockScreenVM viewModel\) \{\n    if \(\!viewModel\.hasFired\) \{\n      viewModel\.hasFired = true;\n      Future\.microtask\(\(\) => viewModel\.checkAuth\(null\)\);\n    \}\n  \}\n', '', code)

# State references
code = code.replace("!vm.isChecking", "(authState.value == true)")

with open('lib/features/lock/presentation/screens/lock_screen.dart', 'w') as f:
    f.write(code)

print('Refactored lock screen!')
