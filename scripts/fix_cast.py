import re

with open('lib/features/chat/presentation/chat_screen.dart', 'r') as f:
    code = f.read()

code = code.replace("builder: (_) => const MemoryVU()", "builder: (_) => const MemoryVU() as Widget")

with open('lib/features/chat/presentation/chat_screen.dart', 'w') as f:
    f.write(code)

print('Fixed cast!')
