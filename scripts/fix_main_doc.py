import re

with open('lib/main.dart', 'r') as f:
    code = f.read()

code = code.replace("import 'package:mobile_assistant/features/documents/documents_vu.dart';", "import 'package:mobile_assistant/features/documents/presentation/screens/document_screen.dart';")
code = code.replace("DocumentsVU()", "DocumentScreen()")

with open('lib/main.dart', 'w') as f:
    f.write(code)

print('Fixed main doc!')
