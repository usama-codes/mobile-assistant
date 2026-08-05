import re

with open('lib/features/chat/presentation/chat_screen.dart', 'r') as f:
    code = f.read()

code = re.sub(r'\.withOpacity\((.*?)\)', r'.withValues(alpha: \1)', code)

with open('lib/features/chat/presentation/chat_screen.dart', 'w') as f:
    f.write(code)

print('Fixed opacity!')
