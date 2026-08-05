import re

with open('lib/features/tasks/presentation/tasks_screen.dart', 'r') as f:
    code = f.read()

code = code.replace("tasksNotifierProvider", "tasksProvider")

with open('lib/features/tasks/presentation/tasks_screen.dart', 'w') as f:
    f.write(code)

print('Fixed!')
