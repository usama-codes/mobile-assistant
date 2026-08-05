import re

with open('lib/features/documents/data/repositories/document_repository_impl.dart', 'r') as f:
    code = f.read()

code = code.replace("import 'package:mobile_assistant/core/db/database.dart';", "import 'package:mobile_assistant/core/db/database.dart';\nimport 'package:drift/drift.dart' as drift;")

with open('lib/features/documents/data/repositories/document_repository_impl.dart', 'w') as f:
    f.write(code)

print('Fixed doc repo!')
