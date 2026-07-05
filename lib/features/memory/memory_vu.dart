import 'package:flutter/material.dart';
import 'package:mobile_assistant/features/memory/memory_vm.dart';
import 'package:stacked/stacked.dart';

class MemoryVU extends StackedView<MemoryVM> {
  const MemoryVU({super.key});

  @override
  Widget builder(BuildContext context, MemoryVM viewModel, Widget? child) {
    return ViewModelBuilder<MemoryVM>.reactive(
      viewModelBuilder: () => MemoryVM(),
      onViewModelReady: (vm) => vm.getMemories(),
      builder: (context, vm, child) {
        return Scaffold(
          appBar: AppBar(title: const Text('Memory')),
          body: ListView.builder(
            itemCount: vm.memories.length,
            itemBuilder: (context, index) {
              final memory = vm.memories[index];

              return ListTile(
                title: Text(memory.fact),
                subtitle: Text('Importance: ${memory.importance}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => vm.deleteMemory(memory.id!),
                ),
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              vm.createMemory('Sample memory', 0.8, DateTime.now());
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  @override
  MemoryVM viewModelBuilder(BuildContext context) {
    return MemoryVM();
  }
}
