import 'package:flutter/material.dart';
import 'package:mobile_assistant/features/chat/chat_vm.dart';
import 'package:stacked/stacked.dart';

class ChatVU extends StackedView<ChatVM> {
  const ChatVU({super.key});

  @override
  Widget builder(BuildContext context, ChatVM viewModel, Widget? child) {
    return Scaffold(appBar: AppBar(title: Text("Hello World")),
    body: Center(
      child: Text("App is running"),
    ),);
  }

  @override
  ChatVM viewModelBuilder(BuildContext context) {
    return ChatVM();
  }
}
