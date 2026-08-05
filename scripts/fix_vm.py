import re

with open('lib/features/tasks/presentation/tasks_screen.dart', 'r') as f:
    code = f.read()

code = code.replace("_showEditTaskSheet(context, vm, task)", "_showEditTaskSheet(context, ref, task)")
code = code.replace("_showAddTaskSheet(context, vm)", "_showAddTaskSheet(context, ref)")
code = code.replace("_buildTaskCard(context, vm, task)", "_buildTaskCard(context, ref, task)")
code = code.replace("_showTaskDetails(context, vm, task)", "_showTaskDetails(context, ref, task)")

code = code.replace(" Widget builder(BuildContext context, TaskVM vm, Widget? child)", " Widget build(BuildContext context, WidgetRef ref)")

with open('lib/features/tasks/presentation/tasks_screen.dart', 'w') as f:
    f.write(code)

print('Fixed vm!')
