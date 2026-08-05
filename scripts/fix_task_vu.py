import os

def revert_task_styling():
    file_path = 'lib/features/tasks/task_vu.dart'
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Revert AnimatedContainer checkbox to standard Icon
    animated_container = '''AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: task.completed ? theme.colorScheme.primary : Colors.transparent,
                  border: Border.all(
                    color: task.completed ? theme.colorScheme.primary : theme.dividerColor,
                    width: 2,
                  ),
                ),
                child: task.completed ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
              )'''
    original_icon = '''Icon(
                task.completed ? Icons.check_circle_outline : Icons.radio_button_unchecked,
                color: task.completed ? theme.colorScheme.primary : theme.dividerColor,
                size: 24,
              )'''
    content = content.replace(animated_container, original_icon)

    # They might also be talking about the ActionChips in chat_vu.dart, but those are new.

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

revert_task_styling()
