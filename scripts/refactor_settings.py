import re

with open('lib/features/settings/settings_vu.dart', 'r') as f:
    code = f.read()

# 1. Imports
code = code.replace("import 'package:stacked/stacked.dart';", "import 'package:flutter_riverpod/flutter_riverpod.dart';")
code = code.replace("import 'package:mobile_assistant/features/settings/settings_vm.dart';", "import 'package:mobile_assistant/features/settings/presentation/settings_provider.dart';\nimport 'package:share_plus/share_plus.dart';")

# 2. Class definition
code = code.replace("class SettingsVU extends StackedView<SettingsVM>", "class SettingsScreen extends ConsumerWidget")
code = code.replace("const SettingsVU({super.key});", "const SettingsScreen({super.key});")

# 3. Method signatures
code = code.replace("SettingsVM vm", "WidgetRef ref")

# 4. Builder -> build
code = code.replace("Widget builder(BuildContext context, WidgetRef ref, Widget? child) {", 
'''@override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(settingsNotifierProvider);
    final state = stateAsync.valueOrNull ?? const SettingsState();''')

# 5. vm values
code = code.replace("vm.isBusy", "state.isBusy")
code = code.replace("vm.isAppLockEnabled", "state.isAppLockEnabled")
code = code.replace("vm.themeMode", "state.themeMode")

# 6. vm actions
code = code.replace("vm.toggleAppLock(", "ref.read(settingsNotifierProvider.notifier).toggleAppLock(")
code = code.replace("vm.setThemeMode(", "ref.read(settingsNotifierProvider.notifier).setThemeMode(")

# 7. Remove viewModelBuilder and onViewModelReady
code = re.sub(r'  @override\n  WidgetRef viewModelBuilder\(BuildContext context\) \{\n    return SettingsVM\(\);\n  \}\n', '', code)
code = re.sub(r'  @override\n  void onViewModelReady\(WidgetRef viewModel\) \{\n    viewModel.init\(\);\n  \}\n', '', code)
code = re.sub(r'  WidgetRef viewModelBuilder\(BuildContext context\) \{.*?\}', '', code, flags=re.DOTALL)
code = re.sub(r'  void onViewModelReady\(WidgetRef viewModel\) \{.*?\}', '', code, flags=re.DOTALL)

with open('lib/features/settings/presentation/settings_screen.dart', 'w') as f:
    f.write(code)

print('Refactored settings!')
