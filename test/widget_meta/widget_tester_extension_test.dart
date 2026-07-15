import 'dart:async';

import 'package:approval_tests_flutter/approval_tests_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _tapButtonKey = ValueKey<String>('tap-button');

void main() {
  group('tapWidget pump policy', () {
    testWidgets('does not pump when the policy is none', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: _CounterButton()));

      await _tapWith(
        tester,
        pumpPolicy: const WidgetActionPumpPolicy.none(),
      );

      expect(find.text('Count: 0'), findsOneWidget);
      await tester.pump();
      expect(find.text('Count: 1'), findsOneWidget);
    });

    testWidgets('pumps one frame when the policy is once', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: _CounterButton()));

      await _tapWith(
        tester,
        pumpPolicy: const WidgetActionPumpPolicy.once(),
      );

      expect(find.text('Count: 1'), findsOneWidget);
    });

    testWidgets('advances time by the fixed pump duration', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: _DelayedButton()));

      await _tapWith(
        tester,
        pumpPolicy: const WidgetActionPumpPolicy.forDuration(
          Duration(milliseconds: 200),
        ),
      );

      expect(find.text('Complete'), findsOneWidget);
    });

    testWidgets('uses the configured settle timeout', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Column(
            children: [
              _CounterButton(),
              CircularProgressIndicator(),
            ],
          ),
        ),
      );

      await expectLater(
        () => _tapWith(
          tester,
          pumpPolicy: const WidgetActionPumpPolicy.untilSettled(
            step: Duration(milliseconds: 10),
            timeout: Duration(milliseconds: 50),
          ),
        ),
        throwsA(isA<FlutterError>()),
      );
    });

    testWidgets('keeps pumpAndSettle as the legacy default', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: _CounterButton()));

      await _tapWith(tester);

      expect(find.text('Count: 1'), findsOneWidget);
    });

    testWidgets('keeps the legacy opt-out from pumping', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: _CounterButton()));

      await tester.tapWidget(
        intl: (_) => 'Tap',
        widgetType: TextButton,
        key: _tapButtonKey,
        // ignore: deprecated_member_use_from_same_package
        shouldPumpAndSettle: false,
      );

      expect(find.text('Count: 0'), findsOneWidget);
    });
  });
}

Future<void> _tapWith(
  WidgetTester tester, {
  WidgetActionPumpPolicy? pumpPolicy,
}) =>
    tester.tapWidget(
      intl: (_) => 'Tap',
      widgetType: TextButton,
      key: _tapButtonKey,
      pumpPolicy: pumpPolicy,
    );

class _CounterButton extends StatefulWidget {
  const _CounterButton();

  @override
  State<_CounterButton> createState() => _CounterButtonState();
}

class _CounterButtonState extends State<_CounterButton> {
  var _count = 0;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          TextButton(
            key: _tapButtonKey,
            onPressed: () => setState(() => _count++),
            child: const Text('Tap'),
          ),
          Text('Count: $_count'),
        ],
      );
}

class _DelayedButton extends StatefulWidget {
  const _DelayedButton();

  @override
  State<_DelayedButton> createState() => _DelayedButtonState();
}

class _DelayedButtonState extends State<_DelayedButton> {
  Timer? _timer;
  var _complete = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          TextButton(
            key: _tapButtonKey,
            onPressed: () {
              _timer = Timer(const Duration(milliseconds: 200), () {
                setState(() => _complete = true);
              });
            },
            child: const Text('Tap'),
          ),
          Text(_complete ? 'Complete' : 'Pending'),
        ],
      );
}
