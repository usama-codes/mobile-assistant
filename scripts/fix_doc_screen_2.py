import re

with open('lib/features/documents/presentation/screens/document_screen.dart', 'r') as f:
    code = f.read()

code = code.replace("doc['folder']", "doc.folder")
code = code.replace("doc['document_type']", "doc.documentType")
code = code.replace("doc['file_path'].toString()", "doc.filePath")
code = code.replace("doc['file_path']", "doc.filePath")
code = code.replace("doc.id as int", "doc.id")

with open('lib/features/documents/presentation/screens/document_screen.dart', 'w') as f:
    f.write(code)

print('Fixed doc screen 2!')
