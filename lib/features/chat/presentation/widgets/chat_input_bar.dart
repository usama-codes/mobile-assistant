import 'package:flutter/material.dart';
import 'package:mobile_assistant/core/theme/app_theme.dart';

/// Persistent bottom input bar: mic stub, attach, send.
class ChatInputBar extends StatefulWidget {

  const ChatInputBar({
    required this.controller, required this.isGenerating, required this.hasAttachment, required this.onSend, required this.onAttach, required this.onRemoveAttachment, super.key,
    this.onMic,
  });
  final TextEditingController controller;
  final bool isGenerating;
  final bool hasAttachment;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final VoidCallback onRemoveAttachment;
  /// Called when mic icon is tapped (voice feature — Phase 2 wires this up).
  final VoidCallback? onMic;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChange);
  }

  void _onTextChange() {
    final has = widget.controller.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outline)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Attachment preview chip
            if (widget.hasAttachment)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.image_outlined, size: 16, color: AppTheme.accent),
                    const SizedBox(width: 6),
                    Text(
                      'Image attached',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppTheme.accent),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: widget.onRemoveAttachment,
                      child: Icon(Icons.close_rounded,
                          size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),

            // Input row
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Attach button
                _IconBtn(
                  icon: Icons.add_rounded,
                  tooltip: 'Attach',
                  onTap: widget.isGenerating ? null : widget.onAttach,
                ),
                const SizedBox(width: 8),

                // Text field
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    enabled: !widget.isGenerating,
                    maxLines: 5,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Message…',
                      hintStyle: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: Theme.of(context).disabledColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusL),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      isDense: true,
                    ),
                    onSubmitted: (_) {
                      if (!widget.isGenerating && _hasText) widget.onSend();
                    },
                  ),
                ),
                const SizedBox(width: 8),

                // Mic or Send button
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: _hasText
                      ? _SendBtn(
                          key: const ValueKey('send'),
                          isGenerating: widget.isGenerating,
                          onTap: widget.onSend,
                        )
                      : _IconBtn(
                          key: const ValueKey('mic'),
                          icon: Icons.mic_none_rounded,
                          tooltip: 'Voice input',
                          onTap: widget.isGenerating ? null : widget.onMic,
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {

  const _IconBtn({
    required this.icon, required this.tooltip, super.key,
    this.onTap,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
          child: Icon(
            icon,
            size: 20,
            color: onTap != null ? Theme.of(context).colorScheme.onSurfaceVariant : Theme.of(context).disabledColor,
          ),
        ),
      ),
    );
  }
}

class _SendBtn extends StatelessWidget {

  const _SendBtn({required this.isGenerating, required this.onTap, super.key});
  final bool isGenerating;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isGenerating ? null : onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isGenerating ? Theme.of(context).colorScheme.outline : AppTheme.accent,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        child: isGenerating
            ? Padding(
                padding: const EdgeInsets.all(10),
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Theme.of(context).colorScheme.onSurfaceVariant),
              )
            : Icon(Icons.arrow_upward_rounded,
                size: 20, color: Theme.of(context).scaffoldBackgroundColor),
      ),
    );
  }
}


