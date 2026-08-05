import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_assistant/core/services/inference_service.dart';
import 'package:mobile_assistant/core/theme/app_theme.dart';
import 'package:mobile_assistant/features/settings/presentation/settings_provider.dart';
import 'package:mobile_assistant/l10n/app_localizations.dart';
import 'package:mobile_assistant/main.dart';
import 'package:share_plus/share_plus.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(settingsProvider);
    final state = stateAsync.value ?? const SettingsState();
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.cardColor,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: theme.dividerColor, height: 1),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.settings, style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold, fontSize: 24)),
            Text(
              AppLocalizations.of(context)!.preferences,
              style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 13, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        toolbarHeight: 70,
      ),
      body: state.isBusy 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(theme, AppLocalizations.of(context)!.preferences.toUpperCase()),
            Container(
              child: ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  _buildThemeSelector(context, ref, theme, state),
                ],
              ),
            ),

            _buildSectionHeader(theme, AppLocalizations.of(context)!.inferenceModel.toUpperCase()),
            Container(
              child: ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  _buildSettingCard(
                    theme: theme,
                    icon: Icons.memory,
                    title: 'Inference Strategy',
                    subtitle: 'Choose between Cloud, Local, or Hybrid',
                    trailing: DropdownButton<String>(
                      value: state.inferenceStrategy,
                      underline: const SizedBox(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          ref.read(settingsProvider.notifier).setInferenceStrategy(newValue);
                        }
                      },
                      items: const [
                        DropdownMenuItem(value: 'cloud', child: Text('Cloud Only')),
                        DropdownMenuItem(value: 'local', child: Text('Local Only')),
                        DropdownMenuItem(value: 'hybrid', child: Text('Hybrid')),
                      ],
                    ),
                  ),
                  if (state.inferenceStrategy == 'local' && !InferenceService.instance.isLocalModelLoaded)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Local Gemma model not found. Place a compatible .bin or .task model file in the app storage, or switch to Hybrid/Cloud mode.',
                                style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Local Model Status & Instructions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: state.modelDownloadComplete
                  ? _buildSettingCard(
                      theme: theme,
                      icon: Icons.check_circle,
                      title: 'Download Complete',
                      subtitle: 'Please restart the app to load the new model into memory.',
                      trailing: Icon(Icons.refresh, color: theme.colorScheme.primary),
                    )
                  : _buildSettingCard(
                      theme: theme,
                      icon: Icons.memory,
                      title: 'Local Model Status',
                      subtitle: state.isDownloadingModel 
                          ? 'Downloading Gemma model (1.35 GB) - ${state.downloadProgress}%'
                          : InferenceService.instance.isLocalModelLoaded
                              ? 'Gemma model loaded and ready for offline use.'
                              : 'Gemma model missing. Tap to download.',
                      trailing: state.isDownloadingModel
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                value: state.downloadProgress > 0 ? state.downloadProgress / 100 : null,
                              ),
                            )
                          : InferenceService.instance.isLocalModelLoaded
                              ? IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Delete Model'),
                                        content: const Text('Are you sure you want to delete the local Gemma model (1.35 GB)?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(ctx);
                                              ref.read(settingsProvider.notifier).deleteGemmaModel();
                                            },
                                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                )
                              : const Icon(Icons.download, color: AppTheme.accent),
                      onTap: () {
                        if (!InferenceService.instance.isLocalModelLoaded && !state.isDownloadingModel) {
                          ref.read(settingsProvider.notifier).downloadGemmaModel();
                        }
                      },
                    ),
            ),

            _buildSectionHeader(theme, AppLocalizations.of(context)!.privacySecurity.toUpperCase()),
            Container(
              child: ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  _buildSettingCard(
                    theme: theme,
                    icon: Icons.fingerprint, 
                    title: AppLocalizations.of(context)!.appLock, 
                    subtitle: 'Require authentication on startup', 
                    trailing: Switch(
                      value: state.isAppLockEnabled,
                      onChanged: (v) => ref.read(settingsProvider.notifier).toggleAppLock(v),
                    )
                  ),
                  const SizedBox(height: 12),
                  _buildSettingCard(
                    theme: theme,
                    icon: Icons.download_outlined, 
                    title: 'Export Data', 
                    subtitle: 'Save a backup of your DB and documents', 
                    trailing: const Icon(Icons.share, size: 20),
                    onTap: () async {
                      try {
                        final path = await ref.read(settingsProvider.notifier).exportData();
                        // ignore: deprecated_member_use
                        await Share.shareXFiles([XFile(path)], text: 'Mobile Assistant Backup');
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('')));
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildSettingCard(
                    theme: theme,
                    icon: Icons.delete_forever, 
                    title: 'Delete All Data', 
                    subtitle: 'Wipe all local tasks, memories, documents', 
                    trailing: const Icon(Icons.warning, color: Colors.red, size: 20),
                    onTap: () => _showDeleteConfirm(context, ref),
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

  void _showDeleteConfirm(BuildContext context, WidgetRef ref) {
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
              ref.read(settingsProvider.notifier).deleteAllData().then((_) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All data deleted.')));
              }).catchError((e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('')));
              });
            }, 
            child: const Text('Delete', style: TextStyle(color: Colors.red))
          ),
        ],
      )
    );
  }

  Widget _buildThemeSelector(BuildContext context, WidgetRef ref, ThemeData theme, SettingsState state) {
    return Card(
      color: theme.cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: theme.dividerColor)),
      child: ListTile(
        leading: Icon(Icons.brightness_6, color: theme.colorScheme.primary),
        title: Text('Theme', style: TextStyle(fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color)),
        trailing: DropdownButton<ThemeMode>(
          value: state.themeMode,
          underline: const SizedBox(),
          items: const [
            DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
            DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
            DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
          ],
          onChanged: (mode) {
            if (mode != null) {
              ref.read(settingsProvider.notifier).setThemeMode(mode);
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
          decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: theme.colorScheme.primary, size: 22),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: theme.textTheme.bodyLarge?.color)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle, style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 13)),
        ),
        trailing: trailing,
      ),
    );
  }

}
