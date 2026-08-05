import re

with open('lib/features/documents/documents_vu.dart', 'r') as f:
    code = f.read()

# Replace imports
code = code.replace("import 'package:mobile_assistant/features/documents/documents_vm.dart';", "import 'package:mobile_assistant/features/documents/presentation/providers/document_providers.dart';\nimport 'package:flutter_riverpod/flutter_riverpod.dart';\nimport 'package:mobile_assistant/features/documents/domain/models/document_item.dart';\nimport 'package:mobile_assistant/features/documents/domain/repositories/document_repository.dart';")
code = code.replace("import 'package:stacked/stacked.dart';", "")

# Class definition
code = code.replace("class DocumentsVU extends StackedView<DocumentsVM>", "class DocumentScreen extends ConsumerStatefulWidget")
code = code.replace("const DocumentsVU({super.key});", "const DocumentScreen({super.key});\n\n  @override\n  ConsumerState<DocumentScreen> createState() => _DocumentScreenState();\n}\n\nclass _DocumentScreenState extends ConsumerState<DocumentScreen> {")

# Builder method
code = code.replace("Widget builder(BuildContext context, DocumentsVM vm, Widget? child) {", "Widget build(BuildContext context) {\n    final docAsync = ref.watch(documentNotifierProvider);\n    final notifier = ref.read(documentNotifierProvider.notifier);\n")

# Viewmodel hooks
code = re.sub(r'  @override\n  DocumentsVM viewModelBuilder\(BuildContext context\) => DocumentsVM\(\);\n\n  @override\n  void onViewModelReady\(DocumentsVM viewModel\) \{\n    viewModel\.getDocuments\(\);\n  \}\n', '', code)

# State references
code = code.replace("vm.isBusy", "docAsync.isLoading")
code = code.replace("vm.documents", "(docAsync.value ?? [])")
code = code.replace("vm.deleteDocument", "notifier.deleteDocument")

# For getDocumentContent in onTap
code = code.replace("vm.getDocumentContent", "ref.read(documentRepositoryProvider).readDocumentContent")
code = code.replace("doc['id']", "doc.id")
code = code.replace("doc['title']", "doc.title")
code = code.replace("doc['documentType']", "doc.documentType")
code = code.replace("doc['createdAt']", "doc.createdAt.toIso8601String()")
code = code.replace("doc['filePath']", "doc.filePath")
code = code.replace("doc['tags']", "doc.tags")

code = code.replace("withOpacity", "withValues(alpha: ")
code = code.replace("0.1)", "0.1))")

with open('lib/features/documents/presentation/screens/document_screen.dart', 'w') as f:
    f.write(code)

print('Refactored document screen!')
