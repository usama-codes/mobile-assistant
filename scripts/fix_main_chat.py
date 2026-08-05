import re

with open('lib/main.dart', 'r') as f:
    code = f.read()

code = code.replace("import 'package:mobile_assistant/features/chat/chat_vu.dart';", "import 'package:mobile_assistant/features/chat/presentation/chat_screen.dart';")
code = code.replace("const ChatVU()", "const ChatScreen()")

with open('lib/main.dart', 'w') as f:
    f.write(code)

print('Fixed main.dart for ChatScreen!')
