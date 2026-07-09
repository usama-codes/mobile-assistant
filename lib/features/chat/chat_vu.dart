import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:mobile_assistant/features/chat/chat_vm.dart';
import 'package:mobile_assistant/features/memory/memory_vu.dart';
import 'package:mobile_assistant/shared/models/chat_session.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stacked/stacked.dart';

class ChatVU extends StackedView<ChatVM> {
  final ChatSession? initialSession;
  
  const ChatVU({super.key, this.initialSession});

  @override
  Widget builder(BuildContext context, ChatVM vm, Widget? child) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.cardColor,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu_rounded, color: theme.iconTheme.color, size: 28),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: theme.dividerColor, height: 1.0),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Assistant', style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold, fontSize: 24)),
            Text(
              'Always here to help',
              style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 13, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        toolbarHeight: 70,
        actions: [
          IconButton(
            onPressed: () => vm.createNewSession(),
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF1D4ED8), size: 28),
            padding: const EdgeInsets.only(right: 16),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: theme.cardColor,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60, bottom: 20, left: 20, right: 20),
              decoration: const BoxDecoration(
                color: Color(0xFF1D4ED8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.chat_bubble_outline, color: theme.cardColor, size: 32),
                  const SizedBox(height: 12),
                  Text('Conversations', style: TextStyle(color: theme.cardColor, fontSize: 22, fontWeight: FontWeight.bold)),
                  Text('${vm.sessions.length} total chats', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.psychology, color: Color(0xFF1D4ED8)),
              title: const Text('Agent Memory', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context); // close drawer
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MemoryVU()));
              },
            ),
            const Divider(),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: vm.sessions.length,
                separatorBuilder: (context, index) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final session = vm.sessions[index];
                  final isSelected = vm.currentSession?.id == session.id;
                  return Container(
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      leading: Icon(
                        Icons.chat_bubble_outline, 
                        color: isSelected ? const Color(0xFF1D4ED8) : Colors.grey.shade600,
                        size: 20,
                      ),
                      title: Text(
                        session.title,
                        style: TextStyle(
                          color: isSelected ? const Color(0xFF1D4ED8) : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 15,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                        onPressed: () {
                          if (session.id != null) {
                            vm.deleteSession(session.id!);
                          }
                        },
                      ),
                      onTap: () {
                        vm.switchSession(session);
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (vm.hasError)
            Container(
              color: Colors.red.shade100,
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      vm.modelError.toString(),
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => vm.clearErrors(),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              reverse: true,
              itemCount: vm.messages.length + (vm.isGenerating ? 1 : 0),
              itemBuilder: (context, index) {
                if (vm.isGenerating && index == 0) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (vm.currentPlan.isNotEmpty) ...[
                            ...vm.currentPlan.map((step) => Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    step.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                                    size: 16,
                                    color: step.isCompleted ? Colors.green : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      step.description,
                                      style: TextStyle(
                                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )).toList(),
                            const Divider(),
                            const SizedBox(height: 4),
                          ],
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                            child: TypingIndicator(),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final adjustedIndex = vm.isGenerating ? index - 1 : index;
                final message = vm.messages[vm.messages.length - 1 - adjustedIndex];
                final isUser = message.isUser;
                
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isUser 
                        ? (isDark ? theme.colorScheme.primary.withOpacity(0.8) : theme.colorScheme.primary)
                        : theme.cardColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: isUser ? null : Border.all(color: theme.dividerColor, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.attachmentPath != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(message.attachmentPath!),
                              width: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Text(
                          message.content,
                          style: TextStyle(
                            color: isUser ? Colors.white : theme.textTheme.bodyLarge?.color,
                            fontSize: 16,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            "${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}",
                            style: TextStyle(
                              color: isUser ? Colors.white.withOpacity(0.7) : theme.textTheme.bodySmall?.color,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                children: [
                  if (vm.selectedImagePath != null || vm.pendingAttachmentPath != null)
                    Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File((vm.selectedImagePath ?? vm.pendingAttachmentPath)!),
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          if (vm.isProcessingImage)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: theme.cardColor,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (vm.pendingAttachmentPath != null && !vm.isProcessingImage)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: vm.removeAttachment,
                                child: Container(
                                  margin: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.close, color: theme.cardColor, size: 16),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (vm.messages.isEmpty)
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(bottom: 8),
                        children: [
                          _buildShortcut(context, vm, 'Create a task'),
                          _buildShortcut(context, vm, 'Remember my name is...'),
                          _buildShortcut(context, vm, 'What is my workload like?'),
                          _buildShortcut(context, vm, 'Summarize document...'),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      PopupMenuButton<String>(
                        color: theme.cardColor,
                        surfaceTintColor: theme.cardColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        icon: Container(
                          decoration: BoxDecoration(
                            color: theme.scaffoldBackgroundColor,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(Icons.add, color: Color(0xFF1D4ED8)),
                        ),
                        offset: const Offset(0, -120),
                        onSelected: (String value) async {
                          if (value == 'scan' || value == 'attach') {
                            final ImagePicker picker = ImagePicker();
                            final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                            if (image != null) {
                              if (value == 'scan') {
                                vm.processImageAttachment(image.path).then((text) {
                                  if (text != null) {
                                    vm.messageController.text = text;
                                  }
                                });
                              } else if (value == 'attach') {
                                vm.attachImage(image.path);
                              }
                            }
                          }
                        },
                        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'attach',
                            child: ListTile(
                              leading: Icon(Icons.attach_file),
                              title: Text('Attach Image'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'scan',
                            child: ListTile(
                              leading: Icon(Icons.document_scanner_outlined),
                              title: Text('Scan Document (OCR)'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: theme.dividerColor),
                          ),
                          child: TextField(
                            controller: vm.messageController,
                            minLines: 1,
                            maxLines: 5,
                            textInputAction: TextInputAction.send,
                            decoration: const InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            onSubmitted: (value) {
                              if (value.trim().isNotEmpty) {
                                vm.messageController.clear();
                                vm.sendMessage(value.trim(), DateTime.now(), isUser: true);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          final value = vm.messageController.text;
                          if (value.trim().isNotEmpty) {
                            vm.messageController.clear();
                            vm.sendMessage(value.trim(), DateTime.now(), isUser: true);
                          }
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1D4ED8),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.send, color: theme.cardColor, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  ChatVM viewModelBuilder(BuildContext context) => ChatVM();

  @override
  void onViewModelReady(ChatVM viewModel) {
    viewModel.loadSessions();
  }

  Widget _buildShortcut(BuildContext context, ChatVM vm, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        label: Text(text, style: const TextStyle(fontSize: 12)),
        onPressed: () {
          vm.messageController.text = text;
        },
      ),
    );
  }
}

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});
  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            double progress = (_controller.value - delay);
            if (progress < 0) progress += 1.0;
            final bounce = math.sin(progress * math.pi);
            final offset = (bounce > 0 && progress < 0.6) ? bounce * -4 : 0.0;
            return Transform.translate(
              offset: Offset(0, offset),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2.5),
                child: CircleAvatar(radius: 4.5, backgroundColor: Color(0xFF1D4ED8)),
              ),
            );
          }),
        );
      },
    );
  }
}
