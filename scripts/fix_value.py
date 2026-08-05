import re

with open('lib/features/tasks/presentation/tasks_screen.dart', 'r') as f:
    code = f.read()

code = code.replace("tasksAsync.valueOrNull ?? []", "tasksAsync.value ?? []")

with open('lib/features/tasks/presentation/tasks_screen.dart', 'w') as f:
    f.write(code)

print('Fixed valueOrNull!')
