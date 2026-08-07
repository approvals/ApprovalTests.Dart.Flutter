import 'package:approval_tests_flutter/approval_tests_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_example/app.dart';
import 'package:flutter_example/features/counter/presentation/counter_controller.dart';
import 'package:flutter_example/features/counter/presentation/counter_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(ApprovalWidgets.setUpAll);
  tearDownAll(ApprovalWidgets.tearDownAll);

  group('CounterPage', () {
    late CounterController controller;

    setUp(() {
      controller = CounterController();
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('renders controller states', (tester) async {
      await tester.pumpWidget(
        ExampleApp(home: CounterPage(controller: controller)),
      );
      await tester.pumpAndSettle();

      await tester.approvalTest(description: 'initial state');

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      expect(controller.value, 1);
      await tester.approvalTest(description: 'incremented state');
    });
  });
}
