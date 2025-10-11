import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:approval_tests_flutter/approval_tests_flutter.dart';

void main() {
  setUpAll(() async => ApprovalWidgets.setUpAll());

  testWidgets('smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const _CounterApp());
    await tester.pumpAndSettle();

    await tester.approvalTest(description: 'counter initial state');
  });
}

class _CounterApp extends StatelessWidget {
  const _CounterApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            '0',
            key: ValueKey<String>('counter'),
          ),
        ),
      ),
    );
  }
}
