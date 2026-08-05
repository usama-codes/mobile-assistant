import re

with open('lib/features/chat/presentation/chat_provider.dart', 'r') as f:
    code = f.read()

code = code.replace("tasksNotifierProvider", "tasksProvider")
code = code.replace("chatNotifierProvider", "chatProvider")

with open('lib/features/chat/presentation/chat_provider.dart', 'w') as f:
    f.write(code)

with open('lib/features/chat/presentation/chat_screen.dart', 'r') as f:
    code = f.read()

code = code.replace("chatNotifierProvider", "chatProvider")

with open('lib/features/chat/presentation/chat_screen.dart', 'w') as f:
    f.write(code)

print('Fixed providers!')
