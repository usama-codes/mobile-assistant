import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:mobile_assistant/core/theme/app_theme.dart';
import 'package:mobile_assistant/features/chat/presentation/chat_provider.dart';
import 'package:mobile_assistant/features/chat/presentation/providers/voice_provider.dart';
import 'package:mobile_assistant/features/chat/presentation/widgets/action_confirmation_card.dart';
import 'package:mobile_assistant/features/chat/presentation/widgets/agent_action_card.dart';
import 'package:mobile_assistant/features/chat/presentation/widgets/chat_input_bar.dart';
import 'package:mobile_assistant/features/chat/presentation/widgets/message_bubble.dart';
import 'package:mobile_assistant/shared/models/agent_step.dart';
import 'package:mobile_assistant/shared/models/chat_message.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();
    await ref
        .read(chatNotifierProvider.notifier)
        .sendMessage(text, DateTime.now(), isUser: true);
    _scrollToBottom();
  }

  Future<void> _pickAndAttach() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusL),
        ),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              ),
            ),
            const SizedBox(height: 16),
            const _SheetOption(
              icon: Icons.photo_library_outlined,
              label: 'Choose from gallery',
              value: 'gallery',
            ),
            const _SheetOption(
              icon: Icons.camera_alt_outlined,
              label: 'Scan document (Camera OCR)',
              value: 'ocr',
            ),
            const _SheetOption(
              icon: Icons.insert_drive_file_outlined,
              label: 'Choose file (PDF/Text)',
              value: 'file',
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;

    final notifier = ref.read(chatNotifierProvider.notifier);

    if (action == 'file') {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'md', 'csv'],
      );
      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        String text = '';
        if (path.toLowerCase().endsWith('.pdf')) {
          final bytes = File(path).readAsBytesSync();
          final PdfDocument document = PdfDocument(inputBytes: bytes);
          text = PdfTextExtractor(document).extractText();
          document.dispose();
        } else {
          text = await File(path).readAsString();
        }
        if (mounted && text.isNotEmpty) {
          _inputCtrl.text = text;
        }
      }
    } else {
      final source = action == 'gallery'
          ? ImageSource.gallery
          : ImageSource.camera;
      final xfile = await _picker.pickImage(source: source, imageQuality: 85);
      if (xfile == null || !mounted) return;

      if (action == 'ocr') {
        final prompt = await notifier.processImageAttachment(xfile.path);
        if (prompt != null && mounted) {
          _inputCtrl.text = prompt;
        }
      } else {
        notifier.attachImage(xfile.path);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatNotifierProvider);
    final voiceState = ref.watch(voiceNotifierProvider);

    // Auto-scroll when new messages arrive
    ref.listen(chatNotifierProvider, (prev, next) {
      if ((prev?.messages.length ?? 0) < next.messages.length) {
        _scrollToBottom();
      }
    });

    // Live STT streaming: sync partial transcript into the input field
    ref.listen(voiceNotifierProvider, (prev, next) {
      if (next.isListening && next.transcript.isNotEmpty && mounted) {
        _inputCtrl
          ..text = next.transcript
          ..selection = TextSelection.fromPosition(
            TextPosition(offset: next.transcript.length),
          );
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: _SessionDrawer(state: state),
      appBar: _buildAppBar(context, state),
      body: Column(
        children: [
          // Error banner
          if (state.modelError != null)
            _ErrorBanner(
              message: state.modelError!,
              onDismiss: () =>
                  ref.read(chatNotifierProvider.notifier).clearErrors(),
            ),

          // Message list
          Expanded(child: _buildMessageList(state)),

          // Action confirmation card — shown when the pipeline proposes an action
          if (state.pendingAction != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: ActionConfirmationCard(
                proposal: state.pendingAction!,
                onConfirm: (p) =>
                    ref.read(chatNotifierProvider.notifier).confirmAction(p),
                onCancel: () =>
                    ref.read(chatNotifierProvider.notifier).cancelAction(),
              ),
            ),

          // Input bar
          ChatInputBar(
            controller: _inputCtrl,
            isGenerating: state.isGenerating,
            hasAttachment: state.pendingAttachmentPath != null,
            onSend: _sendMessage,
            onAttach: _pickAndAttach,
            onRemoveAttachment: () =>
                ref.read(chatNotifierProvider.notifier).removeAttachment(),
            isListening: voiceState.isListening,
            onMic: () async {
              final err = await ref.read(voiceNotifierProvider.notifier).startListening();
              if (err.isNotEmpty && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(err),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
            onMicStop: () async {
              await ref.read(voiceNotifierProvider.notifier).stopListening();
              final transcript =
                  ref.read(voiceNotifierProvider.notifier).consumeTranscript();
              if (transcript.isNotEmpty) {
                _inputCtrl.text = transcript;
                _sendMessage();
              }
            },
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ChatState state) {
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: Icon(
            Icons.menu_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          tooltip: 'Chat sessions',
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            state.currentSession?.title ?? 'Assistant',
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (state.isGenerating)
            Text(
              'Thinking…',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.add_comment_outlined,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          tooltip: 'New chat',
          onPressed: () =>
              ref.read(chatNotifierProvider.notifier).createNewSession(),
        ),
        PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          color: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
          onSelected: (v) async {
            if (v == 'clear') {
              ref.read(chatNotifierProvider.notifier).clearChat();
            } else if (v == 'delete' && state.currentSession?.id != null) {
              ref
                  .read(chatNotifierProvider.notifier)
                  .deleteSession(state.currentSession!.id!);
            }
          },
          itemBuilder: (_) => [
            _menuItem('clear', Icons.delete_sweep_outlined, 'Clear messages'),
            _menuItem(
              'delete',
              Icons.delete_forever_outlined,
              'Delete session',
            ),
          ],
        ),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(ChatState state) {
    if (state.messages.isEmpty && !state.isGenerating) {
      return _EmptyChatState(
        onSuggestion: (text) {
          _inputCtrl.text = text;
          _sendMessage();
        },
      );
    }

    // Build item list: messages + in-progress plan steps
    final items = <_ChatItem>[];
    for (final msg in state.messages) {
      items.add(_ChatItem.message(msg));
    }
    // Interleave plan steps before the typing indicator
    for (final step in state.currentPlan) {
      items.add(_ChatItem.step(step));
    }
    if (state.isGenerating && state.currentPlan.isEmpty) {
      items.add(_ChatItem.typing());
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        if (item.message != null) {
          return MessageBubble(message: item.message!);
        }
        if (item.step != null) {
          return AgentActionCard(step: item.step!);
        }
        return const TypingIndicator();
      },
    );
  }
}

class _ChatItem {
  const _ChatItem._({this.message, this.step, this.isTyping = false});
  factory _ChatItem.message(ChatMessage m) => _ChatItem._(message: m);
  factory _ChatItem.step(AgentStep s) => _ChatItem._(step: s);
  factory _ChatItem.typing() => const _ChatItem._(isTyping: true);
  final ChatMessage? message;
  final AgentStep? step;
  final bool isTyping;
}

// ── Session Drawer ─────────────────────────────────────────────────────────

class _SessionDrawer extends ConsumerWidget {
  const _SessionDrawer({required this.state});
  final ChatState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      backgroundColor: Theme.of(context).cardColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.history_rounded,
                    color: AppTheme.accent,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Chat History',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('New'),
                    onPressed: () {
                      ref
                          .read(chatNotifierProvider.notifier)
                          .createNewSession();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: state.sessions.isEmpty
                  ? Center(
                      child: Text(
                        'No sessions',
                        style: TextStyle(
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: state.sessions.length,
                      itemBuilder: (_, i) {
                        final session = state.sessions[i];
                        final isCurrent =
                            session.id == state.currentSession?.id;
                        return ListTile(
                          leading: Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 18,
                            color: isCurrent
                                ? AppTheme.accent
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                          ),
                          title: Text(
                            session.title,
                            style: TextStyle(
                              color: isCurrent
                                  ? AppTheme.accent
                                  : Theme.of(context).colorScheme.onSurface,
                              fontWeight: isCurrent
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          selected: isCurrent,
                          selectedTileColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                          onTap: () {
                            ref
                                .read(chatNotifierProvider.notifier)
                                .switchSession(session);
                            Navigator.pop(context);
                          },
                          trailing: isCurrent
                              ? null
                              : IconButton(
                                  icon: Icon(
                                    Icons.delete_outline_rounded,
                                    size: 16,
                                    color: Theme.of(context).disabledColor,
                                  ),
                                  onPressed: () {
                                    if (session.id != null) {
                                      ref
                                          .read(chatNotifierProvider.notifier)
                                          .deleteSession(session.id!);
                                    }
                                  },
                                ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty Chat State ───────────────────────────────────────────────────────

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState({required this.onSuggestion});
  final void Function(String) onSuggestion;

  static const List<Map<String, String>> _suggestions = [
    {
      'label': 'Create a task',
      'text': 'Create a task for me to finish the project report by Friday',
    },
    {
      'label': 'Remember something',
      'text': 'Remember that I prefer dark mode and early morning meetings',
    },
    {'label': 'Quick question', 'text': 'What tasks do I have due today?'},
    {
      'label': 'Scan document',
      'text': 'I want to save a document to my knowledge base',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 28,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'How can I help?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Try a suggestion or type anything.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 28),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _suggestions.map((s) {
                return ActionChip(
                  label: Text(s['label'] ?? ''),
                  onPressed: () => onSuggestion(s['text'] ?? ''),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error Banner ───────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});
  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.priorityCritical.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 16,
            color: AppTheme.priorityCritical,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppTheme.priorityCritical,
                fontSize: 13,
              ),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(
              Icons.close_rounded,
              size: 16,
              color: AppTheme.priorityCritical,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom Sheet Option Row ────────────────────────────────────────────────

class _SheetOption extends StatelessWidget {
  const _SheetOption({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: 22,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 15,
        ),
      ),
      onTap: () => Navigator.pop(context, value),
    );
  }
}
