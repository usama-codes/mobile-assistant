import re

with open('lib/features/settings/presentation/settings_screen.dart', 'r') as f:
    code = f.read()

code = code.replace("settingsNotifierProvider", "settingsProvider")
code = code.replace("_buildThemeSelector(context, vm, theme)", "_buildThemeSelector(context, ref, theme, state)")
code = code.replace("Widget builder(BuildContext context, WidgetRef ref, Widget? child)", "Widget build(BuildContext context, WidgetRef ref)")

with open('lib/features/settings/presentation/settings_screen.dart', 'w') as f:
    f.write(code)

print('Fixed settings again!')
