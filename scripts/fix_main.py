import re

with open('lib/main.dart', 'r') as f:
    code = f.read()

code = code.replace("import 'package:mobile_assistant/features/settings/settings_vu.dart';", "import 'package:mobile_assistant/features/settings/presentation/settings_screen.dart';")
code = code.replace("SettingsVU()", "SettingsScreen()")

with open('lib/main.dart', 'w') as f:
    f.write(code)

print('Fixed main.dart!')
