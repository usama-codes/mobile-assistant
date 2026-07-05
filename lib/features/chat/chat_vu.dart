import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:mobile_assistant/features/chat/chat_vm.dart';
import 'package:mobile_assistant/shared/models/chat_session.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stacked/stacked.dart';

class ChatVU extends StackedView<ChatVM> {
  final ChatSession? initialSession;
  
  const ChatVU({super.key, this.initialSession});

  @override
  Widget builder(BuildContext context, ChatVM vm, Widget? child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(vm.currentSession?.title ?? 'Chat', style: const TextStyle(fontWeight: FontWeight.bold)),
            elevation: 0,
            actions: [
              IconButton(
                onPressed: vm.clearChat,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          drawer: Drawer(
            child: Column(
              children: [
                const DrawerHeader(
                  decoration: BoxDecoration(color: Colors.deepPurple),
                  child: Center(
                    child: Text('Chat Sessions', style: TextStyle(color: Colors.white, fontSize: 20)),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('New Chat'),
                  onTap: () {
                    vm.createNewSession();
                    Navigator.pop(context);
                  },
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: vm.sessions.length,
                    itemBuilder: (context, index) {
                      final session = vm.sessions[index];
                      return ListTile(
                        title: Text(session.title),
                        selected: vm.currentSession?.id == session.id,
                        onTap: () {
                          vm.switchSession(session);
                          Navigator.pop(context);
                        },
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
                            color: Colors.grey.shade200,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                              bottomLeft: Radius.zero,
                              bottomRight: Radius.circular(16),
                            ),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                            child: TypingIndicator(),
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
                          color: isUser ? Colors.deepPurple : Colors.grey.shade200,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                            bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                          ),
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
                                color: isUser ? Colors.white : Colors.black87,
                                fontSize: 16,
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
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
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
                                  child: const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
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
                                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.document_scanner_outlined),
                            color: Colors.grey.shade600,
                            tooltip: 'Scan Document (OCR)',
                            onPressed: vm.isProcessingImage ? null : () async {
                              final picker = ImagePicker();
                              final image = await picker.pickImage(source: ImageSource.gallery);
                              if (image != null) {
                                final text = await vm.processImageAttachment(image.path);
                                if (text != null) {
                                  vm.messageController.text += (vm.messageController.text.isEmpty ? "" : "\n\n") + text;
                                }
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.attach_file),
                            color: Colors.grey.shade600,
                            tooltip: 'Attach Image',
                            onPressed: vm.isProcessingImage ? null : () async {
                              final picker = ImagePicker();
                              final image = await picker.pickImage(source: ImageSource.gallery);
                              if (image != null) {
                                vm.attachImage(image.path);
                              }
                            },
                          ),
                          Expanded(
                            child: TextField(
                              controller: vm.messageController,
                              minLines: 1,
                              maxLines: 5,
                              textInputAction: TextInputAction.send,
                              decoration: const InputDecoration(
                                hintText: 'Message Assistant...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                              ),
                              onSubmitted: (value) {
                                if (value.trim().isNotEmpty) {
                                  vm.messageController.clear();
                                  vm.sendMessage(value.trim(), DateTime.now(), isUser: true);
                                }
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0, left: 4.0),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.deepPurple,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_upward, size: 20),
                                color: Colors.white,
                                onPressed: () {
                                  final value = vm.messageController.text;
                                  if (value.trim().isNotEmpty) {
                                    vm.messageController.clear();
                                    vm.sendMessage(value.trim(), DateTime.now(), isUser: true);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                child: CircleAvatar(radius: 4.5, backgroundColor: Colors.deepPurple),
              ),
            );
          }),
        );
      },
    );
  }
}
