import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_assistant/core/theme/app_theme.dart';
import 'package:mobile_assistant/features/tasks/presentation/tasks_provider.dart';
import 'package:mobile_assistant/shared/models/priority.dart';
import 'package:mobile_assistant/shared/models/task_item.dart';
import 'package:mobile_assistant/shared/widgets/empty_state.dart';
import 'package:mobile_assistant/shared/widgets/skeleton_loader.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Recurrence options
// ─────────────────────────────────────────────────────────────────────────────

const List<Map<String, String?>> _recurrenceOptions = [
  {'rule': null, 'label': 'None'},
  {'rule': 'FREQ=DAILY', 'label': 'Daily'},
  {'rule': 'FREQ=WEEKLY', 'label': 'Weekly'},
  {'rule': 'FREQ=MONTHLY', 'label': 'Monthly'},
];

// ─────────────────────────────────────────────────────────────────────────────
// TasksScreen
// ─────────────────────────────────────────────────────────────────────────────

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tasksNotifierProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text('Tasks', style: Theme.of(context).textTheme.titleLarge),
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            tooltip: 'Filter',
            onPressed: () {
              /* Phase 2 */
            },
          ),
        ],
      ),
      body: async.when(
        loading: () => ListView.builder(
          itemCount: 5,
          itemBuilder: (_, _) => const TaskRowSkeleton(),
        ),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: const TextStyle(color: AppTheme.priorityCritical),
          ),
        ),
        data: (tasks) => tasks.isEmpty
            ? EmptyState(
                icon: Icons.check_box_outlined,
                title: 'Nothing due',
                subtitle: 'Add your first task below',
                actionLabel: 'Add task',
                onAction: () => _showAddSheet(context, ref),
              )
            : _TaskList(tasks: tasks),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0),
        child: FloatingActionButton(
          backgroundColor: AppTheme.accent,
          foregroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
          ),
          onPressed: () => _showAddSheet(context, ref),
          child: const Icon(Icons.add_rounded),
        ),
      ),
      extendBody: true,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Task list grouped by proximity
// ─────────────────────────────────────────────────────────────────────────────

class _TaskList extends StatelessWidget {
  const _TaskList({required this.tasks});
  final List<TaskItem> tasks;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final weekEnd = todayEnd.add(const Duration(days: 6));

    final today = tasks.where((t) => !t.dueDate.isAfter(todayEnd)).toList();
    final thisWeek = tasks
        .where(
          (t) => t.dueDate.isAfter(todayEnd) && !t.dueDate.isAfter(weekEnd),
        )
        .toList();
    final later = tasks.where((t) => t.dueDate.isAfter(weekEnd)).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 140),
      children: [
        if (today.isNotEmpty) ...[
          _GroupHeader(label: 'Today', count: today.length),
          ...today.map((t) => _TaskRow(task: t)),
        ],
        if (thisWeek.isNotEmpty) ...[
          _GroupHeader(label: 'This Week', count: thisWeek.length),
          ...thisWeek.map((t) => _TaskRow(task: t)),
        ],
        if (later.isNotEmpty) ...[
          _GroupHeader(label: 'Later', count: later.length),
          ...later.map((t) => _TaskRow(task: t)),
        ],
      ],
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label, required this.count});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            ),
            child: Text(
              '$count',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskRow extends ConsumerStatefulWidget {
  const _TaskRow({required this.task});
  final TaskItem task;

  @override
  ConsumerState<_TaskRow> createState() => _TaskRowState();
}

class _TaskRowState extends ConsumerState<_TaskRow> {
  bool _expanded = false;

  bool get _isOverdue => widget.task.dueDate.isBefore(DateTime.now());

  String _dueLabel() {
    final taskDueDate = widget.task.dueDate;
    final now = DateTime.now();

    if (taskDueDate.year == now.year &&
        taskDueDate.month == now.month &&
        taskDueDate.day == now.day) {
      return DateFormat('HH:mm').format(taskDueDate);
    }

    if (taskDueDate.isBefore(now)) return 'Overdue';
    return DateFormat('MMM d').format(taskDueDate);
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final priorityColor = AppTheme.priorityColor(task.priority);
    final cardBg = Theme.of(context).cardColor;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        child: Material(
          color: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            side: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
          child: Stack(
            children: [
              // Priority left accent bar
              Positioned(
                left: 0, top: 0, bottom: 0,
                child: Container(width: 3, color: priorityColor),
              ),
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(17, 12, 14, 12),
                  child: DefaultTextStyle(
                    style: TextStyle(color: onSurface),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: checkbox + title + recurring icon + time badge
                        Row(
                          children: [
                            // Completion checkbox
                            GestureDetector(
                              onTap: () => ref
                                  .read(tasksNotifierProvider.notifier)
                                  .toggleTask(task),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: task.completed
                                      ? AppTheme.accent
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: task.completed
                                        ? AppTheme.accent
                                        : Theme.of(context).colorScheme.outline,
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: task.completed
                                    ? Icon(Icons.check_rounded,
                                        size: 14, color: Theme.of(context).scaffoldBackgroundColor)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Title
                            Expanded(
                              child: Text(
                                task.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  decoration: task.completed
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: task.completed
                                      ? Theme.of(context).disabledColor
                                      : onSurface,
                                ),
                                maxLines: _expanded ? null : 1,
                                overflow: _expanded ? null : TextOverflow.ellipsis,
                              ),
                            ),

                            // Recurring icon
                            if (task.isRecurring)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Tooltip(
                                  message: task.recurrenceLabel,
                                  child: Icon(Icons.repeat_rounded,
                                      size: 14, color: onSurfaceVariant),
                                ),
                              ),

                            // Due time badge
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _isOverdue
                                      ? AppTheme.priorityCritical.withValues(alpha: 0.15)
                                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radiusPill),
                                ),
                                child: Text(
                                  _dueLabel(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: _isOverdue
                                        ? AppTheme.priorityCritical
                                        : onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Expanded: description + actions
                        if (_expanded && task.description.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            task.description,
                            style: TextStyle(fontSize: 14, color: onSurfaceVariant),
                          ),
                        ],
                        if (_expanded) ...[
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _ActionBtn(
                                icon: Icons.edit_outlined,
                                label: 'Edit',
                                onTap: () => _showEditSheet(context, ref, task),
                              ),
                              const SizedBox(width: 8),
                              _ActionBtn(
                                icon: Icons.delete_outline_rounded,
                                label: 'Delete',
                                color: AppTheme.priorityCritical,
                                onTap: () {
                                  if (task.id != null) {
                                    ref
                                        .read(tasksNotifierProvider.notifier)
                                        .deleteTask(task.id!);
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: c),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: c,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add / Edit Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

Future<void> _showAddSheet(BuildContext context, WidgetRef ref) =>
    _showTaskSheet(context, ref, null);

Future<void> _showEditSheet(
  BuildContext context,
  WidgetRef ref,
  TaskItem task,
) => _showTaskSheet(context, ref, task);

Future<void> _showTaskSheet(
  BuildContext context,
  WidgetRef ref,
  TaskItem? existing,
) async {
  final titleCtrl = TextEditingController(text: existing?.title);
  final descCtrl = TextEditingController(text: existing?.description);
  var dueDate =
      existing?.dueDate ??
      DateTime.now()
          .add(const Duration(hours: 1))
          .copyWith(second: 0, millisecond: 0);
  var priority = existing?.priority ?? Priority.medium;
  var recurrenceRule = existing?.recurrenceRule;
  var showMore =
      existing != null &&
      (existing.description.isNotEmpty ||
          existing.recurrenceRule != null ||
          existing.priority != Priority.medium);

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppTheme.radiusL),
      ),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSt) => SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline,
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                existing == null ? 'New Task' : 'Edit Task',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),

              // Title (always visible)
              TextField(
                controller: titleCtrl,
                autofocus: existing == null,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: const InputDecoration(hintText: 'Task title'),
              ),

              // More options expander
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => setSt(() => showMore = !showMore),
                child: Row(
                  children: [
                    Icon(
                      showMore
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      showMore ? 'Fewer options' : 'More options',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              if (showMore) ...[
                const SizedBox(height: 14),
                // Description
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Description (optional)',
                  ),
                ),
                const SizedBox(height: 14),

                // Due date row
                _FieldRow(
                  icon: Icons.schedule_outlined,
                  label: DateFormat('EEE, d MMM · HH:mm').format(dueDate),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: ctx,
                      initialDate: dueDate,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 1),
                      ),
                      lastDate: DateTime.now().add(
                        const Duration(days: 365 * 5),
                      ),
                      builder: (_, child) =>
                          Theme(data: AppTheme.dark, child: child!),
                    );
                    if (date == null) return;
                    final time = await showTimePicker(
                      context: ctx,
                      initialTime: TimeOfDay.fromDateTime(dueDate),
                      builder: (_, child) =>
                          Theme(data: AppTheme.dark, child: child!),
                    );
                    setSt(() {
                      dueDate = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time?.hour ?? dueDate.hour,
                        time?.minute ?? dueDate.minute,
                      );
                    });
                  },
                ),

                const SizedBox(height: 10),
                // Priority row
                _FieldRow(
                  icon: Icons.flag_outlined,
                  label: 'Priority: ${priority.name}',
                  color: AppTheme.priorityColor(priority),
                  onTap: () async {
                    final p = await showDialog<Priority>(
                      context: ctx,
                      builder: (_) => _PriorityPicker(selected: priority),
                    );
                    if (p != null) setSt(() => priority = p);
                  },
                ),

                const SizedBox(height: 10),
                // Recurrence row
                _FieldRow(
                  icon: Icons.repeat_rounded,
                  label: recurrenceRule != null
                      ? (_recurrenceOptions.firstWhere(
                              (r) => r['rule'] == recurrenceRule,
                            )['label'] ??
                            'Repeat: None')
                      : 'Repeat: None',
                  onTap: () async {
                    final r = await showDialog<String?>(
                      context: ctx,
                      builder: (_) =>
                          _RecurrencePicker(selected: recurrenceRule),
                    );
                    if (r != null || r == null) {
                      setSt(() => recurrenceRule = r);
                    }
                  },
                ),
              ],

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final title = titleCtrl.text.trim();
                    if (title.isEmpty) return;
                    Navigator.pop(ctx);
                    if (existing == null) {
                      await ref
                          .read(tasksNotifierProvider.notifier)
                          .createTask(
                            title: title,
                            description: descCtrl.text.trim(),
                            dueDate: dueDate,
                            completed: false,
                            priority: priority,
                            recurrenceRule: recurrenceRule,
                          );
                    } else {
                      await ref
                          .read(tasksNotifierProvider.notifier)
                          .updateTask(
                            existing.id!,
                            title,
                            descCtrl.text.trim(),
                            dueDate,
                            existing.completed,
                            priority,
                            recurrenceRule: recurrenceRule,
                          );
                    }
                  },
                  child: Text(
                    existing == null ? 'Create Task' : 'Save Changes',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: color ?? Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: Theme.of(context).disabledColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityPicker extends StatelessWidget {
  const _PriorityPicker({required this.selected});
  final Priority selected;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
      ),
      title: Text(
        'Select Priority',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 16,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: Priority.values.map((p) {
          final color = AppTheme.priorityColor(p);
          return ListTile(
            dense: true,
            leading: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            title: Text(
              p.name,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            selected: p == selected,
            selectedTileColor: AppTheme.accentDim,
            onTap: () => Navigator.pop(context, p),
          );
        }).toList(),
      ),
    );
  }
}

class _RecurrencePicker extends StatelessWidget {
  const _RecurrencePicker({this.selected});
  final String? selected;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
      ),
      title: Text(
        'Repeat',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 16,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: _recurrenceOptions.map((opt) {
          return ListTile(
            dense: true,
            leading: Icon(
              opt['rule'] == null ? Icons.remove_rounded : Icons.repeat_rounded,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            title: Text(
              opt['label'] ?? '',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            selected: opt['rule'] == selected,
            selectedTileColor: AppTheme.accentDim,
            onTap: () => Navigator.pop(context, opt['rule']),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

extension on DateTime {
  DateTime copyWith({
    int? year,
    int? month,
    int? day,
    int? hour,
    int? minute,
    int? second,
    int? millisecond,
  }) => DateTime(
    year ?? this.year,
    month ?? this.month,
    day ?? this.day,
    hour ?? this.hour,
    minute ?? this.minute,
    second ?? 0,
    millisecond ?? 0,
  );
}
