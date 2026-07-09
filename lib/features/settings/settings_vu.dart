import 'package:flutter/material.dart';
import 'package:mobile_assistant/features/settings/settings_vm.dart';
import 'package:stacked/stacked.dart';
import 'package:mobile_assistant/main.dart';

class SettingsVU extends StackedView<SettingsVM> {
  const SettingsVU({super.key});

  @override
  Widget builder(BuildContext context, SettingsVM vm, Widget? child) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.cardColor,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: theme.dividerColor, height: 1.0),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settings', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold, fontSize: 24)),
            Text(
              'Manage your preferences',
              style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 13, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        toolbarHeight: 70,
      ),
      body: vm.isBusy 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(theme, 'PREFERENCES'),
            Container(
              child: ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  _buildThemeSelector(context, vm, theme),
                ],
              ),
            ),

            _buildSectionHeader(theme, 'PRIVACY & SECURITY'),
            Container(
              child: ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  _buildSettingCard(
                    theme: theme,
                    icon: Icons.fingerprint, 
                    title: 'App Lock (Biometrics)', 
                    subtitle: 'Require authentication on startup', 
                    trailing: Switch(
                      value: vm.isAppLockEnabled,
                      onChanged: (v) => vm.toggleAppLock(v),
                    )
                  ),
                  const SizedBox(height: 12),
                  _buildSettingCard(
                    theme: theme,
                    icon: Icons.download_outlined, 
                    title: 'Export Data', 
                    subtitle: 'Save a backup of your DB and documents', 
                    trailing: const Icon(Icons.share, size: 20),
                    onTap: () => vm.exportData(context),
                  ),
                  const SizedBox(height: 12),
                  _buildSettingCard(
                    theme: theme,
                    icon: Icons.delete_forever, 
                    title: 'Delete All Data', 
                    subtitle: 'Wipe all local tasks, memories, documents', 
                    trailing: const Icon(Icons.warning, color: Colors.red, size: 20),
                    onTap: () => _showDeleteConfirm(context, vm),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, SettingsVM vm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All Data?'),
        content: const Text('This action is permanent and will delete all tasks, chat history, memories, and documents.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              vm.deleteAllData(context);
            }, 
            child: const Text('Delete', style: TextStyle(color: Colors.red))
          ),
        ],
      )
    );
  }

  Widget _buildThemeSelector(BuildContext context, SettingsVM vm, ThemeData theme) {
    return Card(
      color: theme.cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: theme.dividerColor)),
      child: ListTile(
        leading: Icon(Icons.brightness_6, color: theme.colorScheme.primary),
        title: Text('Theme', style: TextStyle(fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color)),
        trailing: DropdownButton<ThemeMode>(
          value: vm.themeMode,
          underline: const SizedBox(),
          items: const [
            DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
            DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
            DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
          ],
          onChanged: (mode) {
            if (mode != null) {
              vm.setThemeMode(mode);
              MyApp.of(context).changeTheme(mode);
            }
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(title, style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    );
  }

  Widget _buildSettingCard({required ThemeData theme, required IconData icon, required String title, required String subtitle, required Widget trailing, VoidCallback? onTap}) {
    return Card(
      color: theme.cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: theme.dividerColor)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: theme.colorScheme.primary, size: 22),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: theme.textTheme.bodyLarge?.color)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(subtitle, style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 13)),
        ),
        trailing: trailing,
      ),
    );
  }

  @override
  SettingsVM viewModelBuilder(BuildContext context) => SettingsVM();

  @override
  void onViewModelReady(SettingsVM viewModel) {
    viewModel.init();
  }
}
