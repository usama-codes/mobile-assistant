import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:mobile_assistant/features/lock/lock_screen_vm.dart';

class LockScreenVU extends StackedView<LockScreenVM> {
  const LockScreenVU({super.key});

  @override
  Widget builder(BuildContext context, LockScreenVM vm, Widget? child) {
    // Only call once
    if (vm.isChecking && !vm.hasFired) {
      vm.hasFired = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        vm.checkAuth(context);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1D4ED8),
      body: Center(
        child: vm.isChecking
            ? const CircularProgressIndicator(color: Colors.white)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, size: 80, color: Colors.white),
                  const SizedBox(height: 24),
                  const Text(
                    'App Locked',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.fingerprint, color: Color(0xFF1D4ED8)),
                    label: const Text('Unlock', style: TextStyle(color: Color(0xFF1D4ED8))),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    onPressed: () => vm.checkAuth(context),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  LockScreenVM viewModelBuilder(BuildContext context) => LockScreenVM();
}
