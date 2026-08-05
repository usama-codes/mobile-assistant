import re

with open('lib/main.dart', 'r') as f:
    code = f.read()

code = code.replace("import 'package:mobile_assistant/features/lock/lock_screen_vu.dart';", "import 'package:mobile_assistant/features/lock/presentation/screens/lock_screen.dart';")
code = code.replace("LockScreenVU()", "LockScreen()")

with open('lib/main.dart', 'w') as f:
    f.write(code)

print('Fixed main lock!')
