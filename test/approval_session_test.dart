import 'package:approval_tests_flutter/approval_tests_flutter.dart';
import 'package:approval_tests_flutter/src/approval_session.dart';
import 'package:approval_tests_flutter/src/widget_meta/collect_widgets_meta_data.dart';
import 'package:approval_tests_flutter/src/widget_meta/widget_meta.dart';
import 'package:approval_tests_flutter/src/widget_meta/widget_registry.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Private so `runtimeType.toString()` cannot collide with a class discovered
/// in this package's own `lib/`.
class _MarkerBox extends StatelessWidget {
  const _MarkerBox();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

Future<void> _pumpMarker(WidgetTester tester) async {
  await tester.pumpWidget(
    const Directionality(
      textDirection: TextDirection.ltr,
      child: _MarkerBox(),
    ),
  );
  await tester.pump();
}

/// Two structurally identical groups; the third must not inherit from them.
void _registeringGroup(String name) {
  group(name, () {
    setUpAll(() async {
      await ApprovalWidgets.setUpAll();
      registerTypes({_MarkerBox});
    });
    tearDownAll(ApprovalWidgets.tearDownAll);

    testWidgets('captures the type it registered', (tester) async {
      await _pumpMarker(tester);

      expect(await tester.widgetsString, contains('_MarkerBox'));
    });
  });
}

void main() {
  _registeringGroup('first registering group');
  _registeringGroup('second registering group');

  group('a group that registers nothing', () {
    setUpAll(() async {
      await ApprovalWidgets.setUpAll();
    });
    tearDownAll(ApprovalWidgets.tearDownAll);

    testWidgets("does not inherit an earlier group's registered types",
        (tester) async {
      await _pumpMarker(tester);

      expect(await tester.widgetsString, isNot(contains('_MarkerBox')));
    });
  });

  group('session lifecycle', () {
    tearDown(ApprovalWidgets.tearDownAll);

    test('tearDownAll clears discovered names', () async {
      await ApprovalWidgets.setUpAll();
      expect(ApprovalWidgets.widgetNames, isNotNull);

      ApprovalWidgets.tearDownAll();

      expect(ApprovalWidgets.widgetNames, isNull);
    });

    test('tearDownAll is idempotent and safe before any setup', () {
      expect(ApprovalWidgets.tearDownAll, returnsNormally);
      expect(ApprovalWidgets.tearDownAll, returnsNormally);
    });

    test('registerTypes before setUpAll survives it', () async {
      registerTypes({_MarkerBox});

      await ApprovalWidgets.setUpAll();

      expect(
        currentApprovalSession.registry.isRegistered(_MarkerBox),
        isTrue,
      );
    });

    test('the intl holder survives setUpAll and clears on teardown', () async {
      WidgetTesterExtension.s = 'strings';

      await ApprovalWidgets.setUpAll();
      expect(WidgetTesterExtension.s, equals('strings'));

      ApprovalWidgets.tearDownAll();
      expect(WidgetTesterExtension.s, isNull);
    });

    testWidgets('widgetsString asserts when setUpAll has not run',
        (tester) async {
      ApprovalWidgets.tearDownAll();
      await _pumpMarker(tester);

      expect(() => tester.widgetsString, throwsAssertionError);
    });
  });

  group('capture isolation', () {
    tearDown(ApprovalWidgets.tearDownAll);

    testWidgets('two sessions capture one tree without seeing each other',
        (tester) async {
      await _pumpMarker(tester);

      final registered = ApprovalSession()..registerTypes({_MarkerBox});
      final bare = ApprovalSession();

      final withMarker = await collectWidgetsMetaData(
        tester,
        outputMeta: true,
        verbose: false,
        compareWithPrevious: false,
        session: registered,
      );
      final withoutMarker = await collectWidgetsMetaData(
        tester,
        outputMeta: true,
        verbose: false,
        compareWithPrevious: false,
        session: bare,
      );

      expect(withMarker.join('\n'), contains('_MarkerBox'));
      expect(withoutMarker.join('\n'), isNot(contains('_MarkerBox')));
    });

    testWidgets('a default WidgetMeta registry ignores other registrations',
        (tester) async {
      await _pumpMarker(tester);
      registerTypes({_MarkerBox});

      final meta = WidgetMeta(widget: const _MarkerBox());

      expect(meta.isWidgetTypeRegistered, isFalse);
      expect(
        WidgetMeta(
          widget: const _MarkerBox(),
          registry: const WidgetRegistry(types: {_MarkerBox}),
        ).isWidgetTypeRegistered,
        isTrue,
      );
    });

    testWidgets('a full capture leaves no delta memory behind', (tester) async {
      await ApprovalWidgets.setUpAll();
      registerTypes({_MarkerBox});
      await _pumpMarker(tester);

      // widgetsString is the capture approvalTest performs; calling it avoids
      // writing an approval artifact for a test that is not about approvals.
      await tester.widgetsString;
      final afterCapture = await collectWidgetsMetaData(
        tester,
        outputMeta: true,
        verbose: false,
      );

      expect(afterCapture.join('\n'), contains('_MarkerBox'));
    });
  });

  group('registration and lookup reloading', () {
    tearDown(ApprovalWidgets.tearDownAll);

    testWidgets('a later printExpects registers its own types', (tester) async {
      await ApprovalWidgets.setUpAll();
      await _pumpMarker(tester);

      await tester.printExpects(widgetTypes: {SizedBox});
      await tester.printExpects(widgetTypes: {_MarkerBox});

      expect(
        currentApprovalSession.registry.types,
        containsAll(<Type>[SizedBox, _MarkerBox]),
      );
    });

    test('a manual intl entry blocks a later load from file', () async {
      await addTextToIntlReverseLookup(
        stringId: 'greeting',
        stringContent: 'Hello',
      );

      expect(
        currentApprovalSession.intlReverseLookupPath,
        equals(manualIntlReverseLookupPath),
      );
      expect(currentApprovalSession.intlReverseLookup['Hello'], ['greeting']);
    });
  });
}
