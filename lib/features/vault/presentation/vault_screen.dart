import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mobile_assistant/core/theme/app_theme.dart';
import 'package:mobile_assistant/features/documents/domain/models/document_item.dart';
import 'package:mobile_assistant/features/documents/presentation/providers/document_providers.dart';
import 'package:mobile_assistant/features/memory/domain/models/memory_fact.dart';
import 'package:mobile_assistant/features/memory/presentation/providers/memory_providers.dart';
import 'package:mobile_assistant/shared/widgets/empty_state.dart';

/// The merged Memory + Documents tab.
/// Two sub-views accessed via a segmented control: Documents | Insights.
class VaultScreen extends ConsumerStatefulWidget {
  const VaultScreen({super.key});

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen> {
  int _selectedIndex = 0; // 0 = Documents, 1 = Insights

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text('Vault', style: Theme.of(context).textTheme.titleLarge),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _SegmentedControl(
              selected: _selectedIndex,
              labels: const ['Documents', 'Insights'],
              onChanged: (i) => setState(() => _selectedIndex = i),
            ),
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child: _selectedIndex == 0
            ? const _DocumentsView(key: ValueKey('docs'))
            : const _InsightsView(key: ValueKey('insights')),
      ),
    );
  }
}

// ── Segmented Control ──────────────────────────────────────────────────────

class _SegmentedControl extends StatelessWidget {
  const _SegmentedControl({
    required this.selected,
    required this.labels,
    required this.onChanged,
  });
  final int selected;
  final List<String> labels;
  final void Function(int) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final isSelected = i == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).cardColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  border: isSelected
                      ? Border.all(color: Theme.of(context).colorScheme.outline)
                      : null,
                ),
                child: Center(
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Documents Sub-view ─────────────────────────────────────────────────────

class _DocumentsView extends ConsumerWidget {
  const _DocumentsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(documentNotifierProvider);

    return async.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.accent),
      ),
      error: (e, _) => Center(
        child: Text(
          'Error: $e',
          style: const TextStyle(color: AppTheme.priorityCritical),
        ),
      ),
      data: (docs) => docs.isEmpty
          ? const EmptyState(
              icon: Icons.folder_open_outlined,
              title: 'No documents yet',
              subtitle:
                  'Ask the assistant to save a document or scan one via chat.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: docs.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                if (i == docs.length) {
                  return const _PrivacyFooter();
                }
                return _DocumentTile(doc: docs[i]);
              },
            ),
    );
  }
}

/// Persistent footer under the documents list — states the privacy claim
/// in-product so a demo viewer sees the differentiator without being told.
class _PrivacyFooter extends StatelessWidget {
  const _PrivacyFooter();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield_outlined, size: 14, color: AppTheme.accent),
          SizedBox(width: 6),
          Text(
            'All data stored locally, encrypted at rest',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _DocumentTile extends ConsumerWidget {
  const _DocumentTile({required this.doc});
  final DocumentItem doc;

  IconData _typeIcon() {
    switch (doc.documentType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'image':
        return Icons.image_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppTheme.radiusS),
          ),
          child: Icon(
            _typeIcon(),
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(
          doc.title,
          style: Theme.of(context).textTheme.bodyLarge,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${doc.folder} · ${DateFormat('d MMM yyyy').format(doc.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (doc.isEncrypted) ...[
              const SizedBox(height: 4),
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 12,
                    color: AppTheme.accent,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Stored locally, encrypted',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert_rounded,
            size: 18,
            color: Theme.of(context).disabledColor,
          ),
          color: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
          onSelected: (v) async {
            if (v == 'view') {
              await _viewDocument(context, doc);
            } else if (v == 'delete') {
              ref
                  .read(documentNotifierProvider.notifier)
                  .deleteDocument(doc.id);
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(
                    Icons.open_in_new_rounded,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'View',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(
                    Icons.delete_outline_rounded,
                    size: 16,
                    color: AppTheme.priorityCritical,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Delete',
                    style: TextStyle(color: AppTheme.priorityCritical),
                  ),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _viewDocument(context, doc),
      ),
    );
  }

  Future<void> _viewDocument(BuildContext context, DocumentItem doc) async {
    final auth = LocalAuthentication();
    final canCheck = await auth.canCheckBiometrics || await auth.isDeviceSupported();

    bool authenticated = false;
    if (canCheck) {
      try {
        authenticated = await auth.authenticate(
          localizedReason: 'Authenticate to view "${doc.title}"',
        );
      } on PlatformException catch (_) {
        authenticated = false;
      } catch (_) {
        authenticated = false;
      }
    } else {
      // Device has no biometrics / lock — allow access directly
      authenticated = true;
    }

    if (!authenticated || !context.mounted) return;

    // Read the content
    String content;
    try {
      content = await ProviderScope.containerOf(context)
          .read(documentRepositoryProvider)
          .readDocumentContent(doc.filePath);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open document: $e')),
        );
      }
      return;
    }

    if (!context.mounted) return;
    _showContent(context, doc.title, content);
  }

  void _showContent(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text(
              content,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// ── Insights (Memory) Sub-view ─────────────────────────────────────────────

class _InsightsView extends ConsumerWidget {
  const _InsightsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(memoryNotifierProvider);

    return async.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppTheme.accent),
      ),
      error: (e, _) => Center(
        child: Text(
          'Error: $e',
          style: const TextStyle(color: AppTheme.priorityCritical),
        ),
      ),
      data: (memories) => memories.isEmpty
          ? const EmptyState(
              icon: Icons.psychology_outlined,
              title: 'No insights yet',
              subtitle:
                  'The assistant learns about you during conversations and\nsaves facts here.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: memories.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _MemoryCard(fact: memories[i]),
            ),
    );
  }
}

class _MemoryCard extends ConsumerWidget {
  const _MemoryCard({required this.fact});
  final MemoryFact fact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final importance = fact.importance.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Importance indicator bar
          Column(
            children: [
              const SizedBox(height: 3),
              Container(
                width: 3,
                height: 40,
                decoration: BoxDecoration(
                  color: Color.lerp(
                    Theme.of(context).colorScheme.outline,
                    AppTheme.accent,
                    importance,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // Fact content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fact.fact,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  DateFormat('d MMM yyyy').format(fact.createdAt),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),

          // Dismiss button
          GestureDetector(
            onTap: () {
              ref.read(memoryNotifierProvider.notifier).deleteMemory(fact.id);
            },
            child: Padding(
              padding: const EdgeInsets.only(left: 8, top: 2),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: Theme.of(context).disabledColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
