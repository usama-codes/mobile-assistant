import re

with open('lib/features/memory/presentation/screens/memory_screen.dart', 'r') as f:
    code = f.read()

code = code.replace("memory['fact']", "memory.fact")
code = code.replace("memory['id']", "memory.id")
code = code.replace("vm.addMemory", "notifier.addMemory")
code = code.replace("withOpacity", "withValues(alpha: ")
code = code.replace("0.1)", "0.1))")
code = code.replace("subtitle: Text('Importance: '", "subtitle: Text('Importance: \'")

with open('lib/features/memory/presentation/screens/memory_screen.dart', 'w') as f:
    f.write(code)

print('Fixed memory screen!')
