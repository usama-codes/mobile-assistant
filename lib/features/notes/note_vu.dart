import 'package:flutter/material.dart';
import 'package:mobile_assistant/features/notes/note_vm.dart';
import 'package:stacked/stacked.dart';

class NoteVU extends StackedView<NoteVM> {
  const NoteVU({super.key});

  @override
  Widget builder(BuildContext context, NoteVM viewModel, Widget? child) {
    return Scaffold(
      appBar: AppBar(title: Text("Note View")),
      body: Center(child: Text("Hello Notes")),
    );
  }

  @override
  NoteVM viewModelBuilder(BuildContext context) {
    return NoteVM();
  }
}
