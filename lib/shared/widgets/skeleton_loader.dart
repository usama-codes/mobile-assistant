import 'package:flutter/material.dart';
import 'package:mobile_assistant/core/theme/app_theme.dart';

/// Skeleton placeholder that matches the shape of a chat message row.
class ChatMessageSkeleton extends StatefulWidget {
  const ChatMessageSkeleton({super.key, this.isUser = false});
  final bool isUser;

  @override
  State<ChatMessageSkeleton> createState() => _ChatMessageSkeletonState();
}

class _ChatMessageSkeletonState extends State<ChatMessageSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 8,
        bottom: 8,
        left: widget.isUser ? 60 : 16,
        right: widget.isUser ? 16 : 60,
      ),
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, _) => Column(
          crossAxisAlignment: widget.isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            _bar(120 + 40 * _anim.value, 14),
            const SizedBox(height: 6),
            _bar(80 + 60 * _anim.value, 14),
          ],
        ),
      ),
    );
  }

  Widget _bar(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
      ),
    );
  }
}

/// Skeleton placeholder for a task row.
class TaskRowSkeleton extends StatefulWidget {
  const TaskRowSkeleton({super.key});

  @override
  State<TaskRowSkeleton> createState() => _TaskRowSkeletonState();
}

class _TaskRowSkeletonState extends State<TaskRowSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 11,
                    width: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.border,
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
