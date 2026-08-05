import 'package:flutter/material.dart';
import 'package:mobile_assistant/core/theme/app_theme.dart';
import 'package:mobile_assistant/shared/models/agent_step.dart';

/// Inline card rendered in the chat message list when the agent executes a tool.
class AgentActionCard extends StatelessWidget {

  const AgentActionCard({required this.step, super.key});
  final AgentStep step;

  static IconData _iconFor(String description) {
    final d = description.toLowerCase();
    if (d.contains('task')) return Icons.check_circle_outline_rounded;
    if (d.contains('memory') || d.contains('remember')) return Icons.psychology_outlined;
    if (d.contains('document') || d.contains('doc')) return Icons.description_outlined;
    if (d.contains('calendar') || d.contains('event')) return Icons.event_outlined;
    if (d.contains('plan')) return Icons.account_tree_outlined;
    if (d.contains('search')) return Icons.search_rounded;
    if (d.contains('delete') || d.contains('forget')) return Icons.delete_outline_rounded;
    return Icons.bolt_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = step.isCompleted;
    final hasError = step.result != null &&
        (step.result!.toLowerCase().contains('error') ||
            step.result!.toLowerCase().contains('fail'));

    final color = hasError
        ? AppTheme.priorityCritical
        : isCompleted
            ? AppTheme.accent
            : AppTheme.textDisabled;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(
            color: isCompleted ? color.withValues(alpha: 0.3) : Theme.of(context).colorScheme.outline,
          ),
        ),
        child: Row(
          children: [
            // Icon / spinner
            SizedBox(
              width: 20,
              height: 20,
              child: isCompleted
                  ? Icon(_iconFor(step.description), size: 18, color: color)
                  : const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: AppTheme.accent,
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (step.result != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      step.result!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: hasError ? AppTheme.priorityCritical : color,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
