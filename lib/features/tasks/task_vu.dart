import 'package:flutter/material.dart';
import 'package:mobile_assistant/features/tasks/task_vm.dart';
import 'package:mobile_assistant/shared/models/task_item.dart';
import 'package:mobile_assistant/shared/models/priority.dart';
import 'package:stacked/stacked.dart';

class TaskVU extends StackedView<TaskVM> {
  const TaskVU({super.key});

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.low:
        return Colors.green.shade200; // Light green (darker than shade50)
      case Priority.medium:
        return Colors.yellow; // Yellow
      case Priority.high:
        return Colors.red.shade200; // Light red
      case Priority.critical:
        return Colors.red; // Bright red
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(date.year, date.month, date.day);

    if (taskDate == today) return "Today";
    if (taskDate == today.add(const Duration(days: 1))) return "Tomorrow";
    if (taskDate == today.subtract(const Duration(days: 1))) return "Yesterday";

    return "${date.day}/${date.month}/${date.year}";
  }

  String _getTimeRemaining(DateTime deadline) {
    final now = DateTime.now();
    final diff = deadline.difference(now);
    
    if (diff.isNegative) {
      return "Overdue";
    }
    
    if (diff.inDays > 0) {
      return "${diff.inDays}d";
    } else if (diff.inHours > 0) {
      return "${diff.inHours}h";
    } else if (diff.inMinutes > 0) {
      return "${diff.inMinutes}m";
    } else {
      return "Now";
    }
  }

  void _showTaskDetails(BuildContext context, TaskVM vm, TaskItem task) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Chip(
                    backgroundColor: _getPriorityColor(task.priority).withOpacity(0.2),
                    label: Text(
                      task.priority.name.toUpperCase(),
                      style: TextStyle(
                        color: _getPriorityColor(task.priority),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.pop(context); // Close details sheet
                          _showEditTaskSheet(context, vm, task);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          if (task.id != null) {
                            vm.deleteTask(task.id!);
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text("Description", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              Text(task.description.isEmpty ? "No description" : task.description, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    "Due: ${_formatDate(task.dueDate)} at ${task.dueDate.hour.toString().padLeft(2, '0')}:${task.dueDate.minute.toString().padLeft(2, '0')}", 
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showAddTaskSheet(BuildContext context, TaskVM vm) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    Priority selectedPriority = Priority.medium;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create New Task',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Task Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.task_alt),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.description_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (pickedDate != null) {
                              final pickedTime = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(selectedDate),
                              );
                              if (pickedTime != null) {
                                setModalState(() {
                                  selectedDate = DateTime(
                                    pickedDate.year,
                                    pickedDate.month,
                                    pickedDate.day,
                                    pickedTime.hour,
                                    pickedTime.minute,
                                  );
                                });
                              }
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Due Date',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    "${selectedDate.day}/${selectedDate.month}/${selectedDate.year} ${selectedDate.hour.toString().padLeft(2, '0')}:${selectedDate.minute.toString().padLeft(2, '0')}",
                                    style: const TextStyle(fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.calendar_today, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<Priority>(
                          initialValue: selectedPriority,
                          decoration: InputDecoration(
                            labelText: 'Priority',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: Priority.values.map((Priority priority) {
                            return DropdownMenuItem<Priority>(
                              value: priority,
                              child: Text(priority.name.toUpperCase()),
                            );
                          }).toList(),
                          onChanged: (Priority? newValue) {
                            if (newValue != null) {
                              setModalState(() {
                                selectedPriority = newValue;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        if (titleController.text.isNotEmpty) {
                          vm.createTask(
                            title: titleController.text,
                            description: descController.text,
                            dueDate: selectedDate,
                            completed: false,
                            priority: selectedPriority,
                          );
                          Navigator.pop(context);
                        }
                      },
                      child: const Text(
                        'Save Task',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditTaskSheet(BuildContext context, TaskVM vm, TaskItem task) {
    final titleController = TextEditingController(text: task.title);
    final descController = TextEditingController(text: task.description);
    DateTime selectedDate = task.dueDate;
    Priority selectedPriority = task.priority;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edit Task',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Task Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.task_alt),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.description_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 365)),
                              lastDate: DateTime(2100),
                            );
                            if (pickedDate != null) {
                              final pickedTime = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(selectedDate),
                              );
                              if (pickedTime != null) {
                                setModalState(() {
                                  selectedDate = DateTime(
                                    pickedDate.year,
                                    pickedDate.month,
                                    pickedDate.day,
                                    pickedTime.hour,
                                    pickedTime.minute,
                                  );
                                });
                              }
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Due Date',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    "${selectedDate.day}/${selectedDate.month}/${selectedDate.year} ${selectedDate.hour.toString().padLeft(2, '0')}:${selectedDate.minute.toString().padLeft(2, '0')}",
                                    style: const TextStyle(fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.calendar_today, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<Priority>(
                          initialValue: selectedPriority,
                          decoration: InputDecoration(
                            labelText: 'Priority',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: Priority.values.map((Priority priority) {
                            return DropdownMenuItem<Priority>(
                              value: priority,
                              child: Text(priority.name.toUpperCase()),
                            );
                          }).toList(),
                          onChanged: (Priority? newValue) {
                            if (newValue != null) {
                              setModalState(() {
                                selectedPriority = newValue;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        if (titleController.text.isNotEmpty) {
                          vm.updateTask(
                            task.id!,
                            titleController.text,
                            descController.text,
                            selectedDate,
                            task.completed,
                            selectedPriority,
                          );
                          Navigator.pop(context);
                        }
                      },
                      child: const Text(
                        'Update Task',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget builder(BuildContext context, TaskVM viewModel, Widget? child) {
    return ViewModelBuilder<TaskVM>.reactive(
      viewModelBuilder: () => TaskVM(),
      onViewModelReady: (vm) => vm.loadTasks(),
      builder: (context, vm, child) {
        return Scaffold(
          appBar: AppBar(title: const Text('Tasks')),
          body: vm.tasks.isEmpty
              ? const Center(
                  child: Text(
                    "No tasks yet. Add one below!",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: vm.tasks.length,
                  itemBuilder: (context, index) {
                    final task = vm.tasks[index];
                    return GestureDetector(
                      onTap: () => _showTaskDetails(context, vm, task),
                      child: Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: _getPriorityColor(task.priority),
                                  width: 6,
                                ),
                              ),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: Checkbox(
                                        value: task.completed,
                                        onChanged: (_) => vm.toggleTask(task),
                                        activeColor: Colors.deepPurple,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        task.title,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          decoration: task.completed ? TextDecoration.lineThrough : null,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: _getPriorityColor(task.priority),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          task.priority.name.toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (task.description.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 36),
                                    child: Text(
                                      task.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: Colors.grey.shade600),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                Padding(
                                  padding: const EdgeInsets.only(left: 36),
                                  child: Row(
                                    children: [
                                      Icon(Icons.calendar_month, size: 16, color: Colors.blue.shade300),
                                      const SizedBox(width: 6),
                                      Text(
                                        _formatDate(task.dueDate),
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(width: 16),
                                      const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Text(_getTimeRemaining(task.dueDate), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
          floatingActionButton: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)], // Beautiful purple gradient
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4A00E0).withOpacity(0.4),
                  spreadRadius: 2,
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: () => _showAddTaskSheet(context, vm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.add, color: Colors.white, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'New Task',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  TaskVM viewModelBuilder(BuildContext context) {
    return TaskVM();
  }
}
