import re

with open('lib/features/chat/presentation/chat_screen.dart', 'r') as f:
    code = f.read()

code = code.replace("import 'package:mobile_assistant/features/memory/memory_vu.dart';", "import 'package:mobile_assistant/features/memory/presentation/screens/memory_screen.dart';")
code = code.replace("builder: (_) => const MemoryVU() as Widget", "builder: (_) => const MemoryScreen()")
code = code.replace("builder: (_) => const MemoryVU()", "builder: (_) => const MemoryScreen()")

with open('lib/features/chat/presentation/chat_screen.dart', 'w') as f:
    f.write(code)

print('Fixed chat_screen nav!')
