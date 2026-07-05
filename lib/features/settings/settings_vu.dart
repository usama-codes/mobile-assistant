import 'package:flutter/material.dart';
import 'package:mobile_assistant/features/settings/settings_vm.dart';
import 'package:stacked/stacked.dart';

class SettingsVU extends StackedView<SettingsVM> {
  const SettingsVU({super.key});

  @override
  Widget builder(BuildContext context, SettingsVM viewModel, Widget? child) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: const Center(child: Text("Hello Settings")),
    );
  }

  @override
  SettingsVM viewModelBuilder(BuildContext context) {
    return SettingsVM();
  }
}
