import re

with open('lib/features/tasks/task_vu.dart', 'r') as f:
    code = f.read()

# 1. Imports
code = code.replace("import 'package:stacked/stacked.dart';", "import 'package:flutter_riverpod/flutter_riverpod.dart';")
code = code.replace("import 'package:mobile_assistant/features/tasks/task_vm.dart';", "import 'package:mobile_assistant/features/tasks/presentation/tasks_provider.dart';")

# 2. Class definition
code = code.replace("class TaskVU extends StackedView<TaskVM>", "class TasksScreen extends ConsumerWidget")
code = code.replace("const TaskVU({super.key});", "const TasksScreen({super.key});")

# 3. Method signatures
code = code.replace("TaskVM vm", "WidgetRef ref")

# 4. vm actions
code = code.replace("vm.deleteTask(", "ref.read(tasksNotifierProvider.notifier).deleteTask(")
code = code.replace("vm.createTask(", "ref.read(tasksNotifierProvider.notifier).createTask(")
code = code.replace("vm.updateTask(", "ref.read(tasksNotifierProvider.notifier).updateTask(")
code = code.replace("vm.toggleTask(", "ref.read(tasksNotifierProvider.notifier).toggleTask(")

# 5. vm.tasks
code = code.replace("vm.tasks", "tasks")

# 6. Builder -> build
code = code.replace("Widget builder(BuildContext context, WidgetRef ref, Widget? child) {", 
'''@override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksNotifierProvider);
    final tasks = tasksAsync.valueOrNull ?? [];''')

# 7. Remove viewModelBuilder and onViewModelReady
code = re.sub(r'  WidgetRef viewModelBuilder\(BuildContext context\) \{.*?\}', '', code, flags=re.DOTALL)
code = re.sub(r'  void onViewModelReady\(WidgetRef viewModel\) \{.*?\}', '', code, flags=re.DOTALL)

with open('lib/features/tasks/presentation/tasks_screen.dart', 'w') as f:
    f.write(code)

print('Refactored!')
