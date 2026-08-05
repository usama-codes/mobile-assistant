import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_assistant/features/lock/presentation/providers/lock_providers.dart';
import 'package:mobile_assistant/main.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(lockProvider);

    ref.listen(lockProvider, (previous, next) {
      if (next.value == true) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF1D4ED8),
      body: Center(
        child: authState.isLoading
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
                    onPressed: () => ref.read(lockProvider.notifier).checkAuth(),
                  ),
                ],
              ),
      ),
    );
  }
}
