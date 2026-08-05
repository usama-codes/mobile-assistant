import re

with open('lib/features/settings/presentation/settings_screen.dart', 'r') as f:
    code = f.read()

code = re.sub(r'  SettingsVM viewModelBuilder\(BuildContext context\) => SettingsVM\(\);\n', '', code)
code = re.sub(r'  void onViewModelReady\(SettingsVM viewModel\) \{\n.*?\}\n', '', code, flags=re.DOTALL)

with open('lib/features/settings/presentation/settings_screen.dart', 'w') as f:
    f.write(code)

print('Cleaned up SettingsVM!')
