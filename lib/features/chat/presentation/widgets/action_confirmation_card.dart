import 'package:flutter/material.dart';
import 'package:mobile_assistant/core/theme/app_theme.dart';
import 'package:mobile_assistant/shared/models/action_proposal.dart';

/// A rich in-chat card for confirming or editing an extracted action proposal
/// before any write to the calendar/task/expense system.
///
/// Shows the extracted fields with edit capability and three actions:
/// ✅ Confirm → execute the action
/// ✏️ Edit → fields become editable
/// ❌ Cancel → dismiss the proposal
class ActionConfirmationCard extends StatefulWidget {
  const ActionConfirmationCard({
    super.key,
    required this.proposal,
    required this.onConfirm,
    required this.onCancel,
  });

  final ActionProposal proposal;
  final void Function(ActionProposal confirmed) onConfirm;
  final VoidCallback onCancel;

  @override
  State<ActionConfirmationCard> createState() =>
      _ActionConfirmationCardState();
}

class _ActionConfirmationCardState extends State<ActionConfirmationCard> {
  late bool _isEditing;
  late ActionProposal _proposal;

  // Editable controllers
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;

  @override
  void initState() {
    super.initState();
    _isEditing = false;
    _proposal = widget.proposal;
    _titleController = TextEditingController(text: _proposal.title);
    _descriptionController =
        TextEditingController(text: _proposal.description ?? '');
    _locationController =
        TextEditingController(text: _proposal.location ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _applyEdits() {
    _proposal = _proposal.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
    );
    setState(() => _isEditing = false);
  }

  Color _confidenceColor() {
    if (_proposal.confidence >= 0.8) return Colors.green;
    if (_proposal.confidence >= 0.6) return Colors.amber;
    return Colors.orange;
  }

  String _actionLabel() {
    switch (_proposal.action) {
      case 'create_calendar_event':
        return '📅 Calendar Event';
      case 'create_task':
        return '✅ Task';
      case 'log_expense':
        return '💰 Expense';
      default:
        return '⚡ Action';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: _confidenceColor().withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _confidenceColor().withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: action type + confidence
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                // Action type chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _confidenceColor().withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _actionLabel(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _confidenceColor(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Confidence badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(_proposal.confidence * 100).round()}%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: _confidenceColor(),
                    ),
                  ),
                ),
                const Spacer(),
                if (_proposal.sourceDocTitle != null)
                  _SourceDocBadge(title: _proposal.sourceDocTitle!),
              ],
            ),
          ),

          // Fields
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                _FieldRow(
                  icon: Icons.title_rounded,
                  label: 'Title',
                  child: _isEditing
                      ? _EditableTextField(controller: _titleController)
                      : Text(
                          _proposal.title,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),

                // Start date
                if (_proposal.startDate != null || _proposal.isCalendarEvent)
                  _FieldRow(
                    icon: Icons.play_arrow_rounded,
                    label: 'Start',
                    child: _isEditing
                        ? _EditableDateChip(
                            date: _proposal.startDate,
                            onPicked: (d) =>
                                setState(() => _proposal.startDate = d),
                          )
                        : Text(
                            _proposal.startDate != null
                                ? _formatDateTime(_proposal.startDate!)
                                : 'Not set',
                            style: theme.textTheme.bodyMedium,
                          ),
                  ),

                // End date (calendar events only)
                if (_proposal.isCalendarEvent)
                  _FieldRow(
                    icon: Icons.stop_rounded,
                    label: 'End',
                    child: _isEditing
                        ? _EditableDateChip(
                            date: _proposal.endDate,
                            onPicked: (d) =>
                                setState(() => _proposal.endDate = d),
                          )
                        : Text(
                            _proposal.endDate != null
                                ? _formatDateTime(_proposal.endDate!)
                                : 'Not set',
                            style: theme.textTheme.bodyMedium,
                          ),
                  ),

                // Description
                if (_proposal.description != null || _isEditing)
                  _FieldRow(
                    icon: Icons.notes_rounded,
                    label: 'Notes',
                    child: _isEditing
                        ? _EditableTextField(
                            controller: _descriptionController, maxLines: 2)
                        : Text(
                            _proposal.description ?? '—',
                            style: theme.textTheme.bodyMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                  ),

                // Location (calendar events)
                if (_proposal.isCalendarEvent)
                  _FieldRow(
                    icon: Icons.location_on_outlined,
                    label: 'Location',
                    child: _isEditing
                        ? _EditableTextField(controller: _locationController)
                        : Text(
                            _proposal.location ?? '—',
                            style: theme.textTheme.bodyMedium,
                          ),
                  ),
              ],
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Row(
              children: [
                // Cancel
                Expanded(
                  child: _ActionButton(
                    icon: Icons.close_rounded,
                    label: 'Cancel',
                    color: theme.disabledColor,
                    onTap: widget.onCancel,
                  ),
                ),
                const SizedBox(width: 8),
                // Edit / Done
                Expanded(
                  child: _ActionButton(
                    icon: _isEditing ? Icons.check_rounded : Icons.edit_rounded,
                    label: _isEditing ? 'Done' : 'Edit',
                    color: AppTheme.accent,
                    onTap: _isEditing
                        ? _applyEdits
                        : () => setState(() => _isEditing = true),
                  ),
                ),
                const SizedBox(width: 8),
                // Confirm
                Expanded(
                  child: _ActionButton(
                    icon: Icons.check_circle_rounded,
                    label: 'Confirm',
                    color: Colors.green,
                    filled: true,
                    onTap: () => widget.onConfirm(_proposal),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    final day = local.day;
    const monthNames = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$day ${monthNames[local.month]} $hour12:$minute $ampm';
  }
}

// ── Sub-widgets ─────────────────────────────────────────────────────────────

class _SourceDocBadge extends StatelessWidget {
  const _SourceDocBadge({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.description_outlined,
              size: 10, color: AppTheme.accent),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.accent,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.icon,
    required this.label,
    required this.child,
  });

  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).disabledColor),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).disabledColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _EditableTextField extends StatelessWidget {
  const _EditableTextField({
    required this.controller,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide:
              BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide:
              BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
    );
  }
}

class _EditableDateChip extends StatelessWidget {
  const _EditableDateChip({required this.date, required this.onPicked});
  final DateTime? date;
  final ValueChanged<DateTime> onPicked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
        );
        if (picked != null && context.mounted) {
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(date ?? DateTime.now()),
          );
          final dt = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time?.hour ?? (date?.hour ?? 9),
            time?.minute ?? 0,
          );
          onPicked(dt);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
          border:
              Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_rounded,
                size: 12, color: AppTheme.accent),
            const SizedBox(width: 4),
            Text(
              date != null
                  ? _ActionConfirmationCardState._formatDateTime(date!)
                  : 'Pick date',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: filled ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color.withValues(alpha: filled ? 0 : 0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: filled ? Colors.white : color,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: filled ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
