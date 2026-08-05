import re

# 1. Add appDatabaseProvider to database.dart
with open('lib/core/db/database.dart', 'r') as f:
    db_code = f.read()
if 'appDatabaseProvider' not in db_code:
    db_code += "\n\nimport 'package:flutter_riverpod/flutter_riverpod.dart';\nfinal appDatabaseProvider = Provider<AppDatabase>((ref) => AppDatabase.instance);\n"
    with open('lib/core/db/database.dart', 'w') as f:
        f.write(db_code)

# 2. Add drift import to memory_repository_impl.dart
with open('lib/features/memory/data/repositories/memory_repository_impl.dart', 'r') as f:
    mem_code = f.read()
if "import 'package:drift/drift.dart' as drift;" not in mem_code:
    mem_code = mem_code.replace("import 'package:mobile_assistant/core/db/database.dart';", "import 'package:mobile_assistant/core/db/database.dart';\nimport 'package:drift/drift.dart' as drift;")
    with open('lib/features/memory/data/repositories/memory_repository_impl.dart', 'w') as f:
        f.write(mem_code)

print('Fixed compilation!')
