import 'package:flutter/material.dart';
import 'package:mobile_assistant/features/documents/documents_vm.dart';
import 'package:stacked/stacked.dart';

class DocumentsVU extends StackedView<DocumentsVM> {
  const DocumentsVU({super.key});

  @override
  Widget builder(BuildContext context, DocumentsVM vm, Widget? child) {
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
            Text('Knowledge Base', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold, fontSize: 24)),
            Text(
              'Your extracted documents and notes',
              style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 13, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        toolbarHeight: 70,
      ),
      body: vm.isBusy
          ? const Center(child: CircularProgressIndicator())
          : vm.documents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open, size: 64, color: theme.dividerColor),
                      const SizedBox(height: 16),
                      Text("No documents yet", style: TextStyle(color: theme.textTheme.bodySmall?.color)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: vm.documents.length,
                  itemBuilder: (context, index) {
                    final doc = vm.documents[index];
                    return Card(
                      color: theme.cardColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.dividerColor)),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                          child: Icon(Icons.description, color: theme.colorScheme.primary),
                        ),
                        title: Text(doc['title'].toString(), style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
                        subtitle: Text('Folder: ${doc['folder']} • Type: ${doc['document_type']}', style: TextStyle(color: theme.textTheme.bodySmall?.color)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => vm.deleteDocument(doc['id'] as int),
                        ),
                        onTap: () {
                          // View dialog showing file content
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              backgroundColor: theme.cardColor,
                              title: Text(doc['title'].toString()),
                              content: SizedBox(
                                width: double.maxFinite,
                                child: FutureBuilder<String>(
                                  future: vm.getDocumentContent(doc['file_path'].toString()),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const SizedBox(
                                        height: 100,
                                        child: Center(child: CircularProgressIndicator()),
                                      );
                                    }
                                    if (snapshot.hasError) {
                                      return Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red));
                                    }
                                    final content = snapshot.data ?? 'No content';
                                    return SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            content,
                                            style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 15, height: 1.4),
                                          ),
                                          const SizedBox(height: 20),
                                          Divider(color: theme.dividerColor),
                                          const SizedBox(height: 8),
                                          Text(
                                            'File Path: ${doc['file_path']}',
                                            style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }

  @override
  DocumentsVM viewModelBuilder(BuildContext context) => DocumentsVM();

  @override
  void onViewModelReady(DocumentsVM viewModel) {
    viewModel.getDocuments();
  }
}
