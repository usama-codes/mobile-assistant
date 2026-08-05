import re

with open('lib/features/settings/presentation/settings_screen.dart', 'r') as f:
    code = f.read()

code = code.replace("stateAsync.valueOrNull ??", "stateAsync.value ??")

with open('lib/features/settings/presentation/settings_screen.dart', 'w') as f:
    f.write(code)

print('Fixed settings value!')
