import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_assistant/features/memory/presentation/providers/memory_providers.dart';

class MemoryScreen extends ConsumerStatefulWidget {
  const MemoryScreen({super.key});

  @override
  ConsumerState<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends ConsumerState<MemoryScreen> {
  @override
  Widget build(BuildContext context) {
    final memoryAsync = ref.watch(memoryProvider);
    final notifier = ref.read(memoryProvider.notifier);

    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.cardColor,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.primary),
        title: Text(
          'Memories',
          style: TextStyle(
            color: theme.textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: memoryAsync.isLoading
          ? const Center(child: CircularProgressIndicator())
          : (memoryAsync.value ?? []).isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.memory, size: 64, color: theme.dividerColor),
                  const SizedBox(height: 16),
                  Text(
                    'No memories yet',
                    style: TextStyle(color: theme.textTheme.bodySmall?.color),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: (memoryAsync.value ?? []).length,
              itemBuilder: (context, index) {
                final memory = (memoryAsync.value ?? [])[index];
                return Card(
                  color: theme.cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.dividerColor),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primary.withValues(
                        alpha: 0.1,
                      ),
                      child: Icon(
                        Icons.psychology,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    title: Text(
                      memory.fact,
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                    ),
                    subtitle: Text(
                      'Importance: ',
                      style: TextStyle(color: theme.textTheme.bodySmall?.color),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => notifier.deleteMemory(memory.id),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.colorScheme.primary,
        onPressed: () {
          final textController = TextEditingController();
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: theme.cardColor,
              title: Text(
                'Add Memory',
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              ),
              content: TextField(
                controller: textController,
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  hintText: 'Enter a fact to remember',
                  hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (textController.text.trim().isNotEmpty) {
                      notifier.addMemory(textController.text.trim());
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
