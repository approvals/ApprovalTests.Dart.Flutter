import 'package:flutter/material.dart';
import 'package:flutter_example/features/counter/presentation/counter_controller.dart';

class CounterPage extends StatelessWidget {
  const CounterPage({
    required this.controller,
    super.key,
  });

  final CounterController controller;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Approval Tests counter'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('You have pushed the button this many times:'),
              ValueListenableBuilder<int>(
                valueListenable: controller,
                builder: (context, count, child) => Text(
                  '$count',
                  key: const ValueKey('counter-value'),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: controller.increment,
          child: const Icon(Icons.add),
        ),
      );
}
