import re

with open('lib/core/db/database.dart', 'r') as f:
    code = f.read()

code = code.replace("import 'package:flutter_riverpod/flutter_riverpod.dart';\nfinal appDatabaseProvider = Provider<AppDatabase>((ref) => AppDatabase.instance);\n", "final appDatabaseProvider = Provider<AppDatabase>((ref) => AppDatabase.instance);\n")

if "import 'package:flutter_riverpod/flutter_riverpod.dart';" not in code:
    code = "import 'package:flutter_riverpod/flutter_riverpod.dart';\n" + code

with open('lib/core/db/database.dart', 'w') as f:
    f.write(code)

print('Fixed import location!')
