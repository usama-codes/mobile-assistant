import re

with open('lib/features/settings/presentation/settings_screen.dart', 'r') as f:
    code = f.read()

# Fix vm.exportData(context) -> ref.read(settingsNotifierProvider.notifier).exportData().then(...)
code = code.replace("onTap: () => vm.exportData(context)", 
'''onTap: () async {
                      try {
                        final path = await ref.read(settingsNotifierProvider.notifier).exportData();
                        // ignore: deprecated_member_use
                        await Share.shareXFiles([XFile(path)], text: 'Mobile Assistant Backup');
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('\')));
                      }
                    }''')

code = code.replace("onTap: () => _showDeleteConfirm(context, vm),", "onTap: () => _showDeleteConfirm(context, ref),")

code = code.replace("vm.deleteAllData(context);", 
'''ref.read(settingsNotifierProvider.notifier).deleteAllData().then((_) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All data deleted.')));
              }).catchError((e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('\')));
              });''')

code = code.replace("Widget _buildThemeSelector(BuildContext context, WidgetRef ref, ThemeData theme)", "Widget _buildThemeSelector(BuildContext context, WidgetRef ref, ThemeData theme, SettingsState state)")
code = code.replace("_buildThemeSelector(context, ref, theme)", "_buildThemeSelector(context, ref, theme, state)")

with open('lib/features/settings/presentation/settings_screen.dart', 'w') as f:
    f.write(code)

print('Fixed settings!')
