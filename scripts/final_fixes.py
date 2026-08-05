import re
import os

# 1. Remove appDatabaseProvider from database.dart
with open('lib/core/db/database.dart', 'r') as f:
    db = f.read()
db = db.replace("final appDatabaseProvider = Provider<AppDatabase>((ref) => AppDatabase.instance);\n", "")
db = db.replace("import 'package:flutter_riverpod/flutter_riverpod.dart';\n", "")
with open('lib/core/db/database.dart', 'w') as f:
    f.write(db)

# 2. Fix imports in memory_providers and document_providers
for pfile in ['lib/features/memory/presentation/providers/memory_providers.dart', 'lib/features/documents/presentation/providers/document_providers.dart']:
    with open(pfile, 'r') as f:
        code = f.read()
    if "import 'package:mobile_assistant/core/providers/database_provider.dart';" not in code:
        code = "import 'package:mobile_assistant/core/providers/database_provider.dart';\n" + code
    with open(pfile, 'w') as f:
        f.write(code)

# 3. Fix chat_provider.dart line 258
with open('lib/features/chat/presentation/chat_provider.dart', 'r') as f:
    chat = f.read()
chat = chat.replace("tools: [_getAgentTools()],", "tools: [ref.read(agentServiceProvider).getTools()],")
with open('lib/features/chat/presentation/chat_provider.dart', 'w') as f:
    f.write(chat)

print('Final fixes applied!')
