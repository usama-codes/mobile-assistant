import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_assistant/core/theme/app_theme.dart';
import 'package:mobile_assistant/shared/models/chat_message.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({required this.message, super.key});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return message.isUser
        ? _UserBubble(message: message)
        : _AssistantBubble(message: message);
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(left: 60, right: 16, top: 4, bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Attachment preview
            if (message.attachmentPath != null &&
                File(message.attachmentPath!).existsSync())
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  child: Image.file(
                    File(message.attachmentPath!),
                    width: 180,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                border: Border.all(
                  color: AppTheme.accent.withValues(alpha: 0.25),
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.radiusL),
                  topRight: Radius.circular(AppTheme.radiusL),
                  bottomLeft: Radius.circular(AppTheme.radiusL),
                  bottomRight: Radius.circular(AppTheme.radiusS),
                ),
              ),
              child: Text(
                message.content,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssistantBubble extends StatelessWidget {
  const _AssistantBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 60, top: 4, bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar dot
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 10),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 14,
                  color: AppTheme.accent,
                ),
              ),
            ),
            Flexible(
              child: Text(
                message.content,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.55,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Three-dot typing indicator for when the assistant is generating.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 60, top: 4, bottom: 4),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 14,
              color: AppTheme.accent,
            ),
          ),
          const SizedBox(width: 10),
          Row(
            children: List.generate(3, (i) {
              return AnimatedBuilder(
                animation: _ctrl,
                builder: (_, _) {
                  final offset = (_ctrl.value - i * 0.15) % 1.0;
                  final scale =
                      0.6 +
                      0.4 * (offset < 0.5 ? offset * 2 : (1 - offset) * 2);
                  return Container(
                    margin: const EdgeInsets.only(right: 4),
                    width: 7 * scale,
                    height: 7 * scale,
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
