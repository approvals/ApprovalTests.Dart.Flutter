import 'dart:io';

import 'package:approval_tests_flutter/src/approval_session.dart';
import 'package:approval_tests_flutter/src/widget_meta/collect_widgets_meta_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

enum Keys {
  submit,
  container,
}

final class _RegisteredBox extends StatelessWidget {
  const _RegisteredBox({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

void main() {
  group('collectWidgetsMetaData', () {
    testWidgets('reports when the tree has no capturable widgets',
        (tester) async {
      await tester.pumpWidget(const SizedBox.shrink());

      final lines = await collectWidgetsMetaData(
        tester,
        session: ApprovalSession(),
      );

      expect(lines, ['No widgets found for approval testing.']);
    });

    testWidgets('generates key, type, text, and duplicate matchers',
        (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              _RegisteredBox(),
              Padding(
                padding: EdgeInsets.zero,
                child: _RegisteredBox(
                  key: ValueKey<String>('Boxes__shared'),
                ),
              ),
              Padding(
                padding: EdgeInsets.zero,
                child: _RegisteredBox(
                  key: ValueKey<String>('Boxes__shared'),
                ),
              ),
              SizedBox(key: ValueKey<Keys>(Keys.container)),
              SizedBox(key: ValueKey<String>('Keys__title')),
              Text('duplicate'),
              Text('duplicate'),
              Text(
                'submit',
                key: ValueKey<Keys>(Keys.submit),
              ),
              Text(
                'row',
                key: ValueKey<String>('Keys__row__2'),
              ),
            ],
          ),
        ),
      );
      final session = ApprovalSession();

      final lines = await collectWidgetsMetaData(
        tester,
        widgetTypes: {_RegisteredBox},
        session: session,
      );

      expect(lines.first, instructions);
      expect(
        lines,
        contains(
          '\texpect(find.byType(_RegisteredBox), findsWidgets);',
        ),
      );
      expect(
        lines,
        contains(
          '\ttester.expectWidget(widgetType: _RegisteredBox, '
          'key: Boxes.shared, matcher: findsWidgets,);',
        ),
      );
      expect(
        lines,
        contains(
          '\texpect(find.byKey(const ValueKey(Keys.container)), '
          'findsOneWidget);',
        ),
      );
      expect(
        lines,
        contains(
          '\texpect(find.byKey(Keys.title), findsOneWidget);',
        ),
      );
      expect(
        lines,
        contains(
          "\texpect(find.text('duplicate'), findsWidgets);",
        ),
      );
      expect(
        lines,
        contains(
          "\ttester.expectWidget(data: 'submit', key: Keys.submit);",
        ),
      );
      expect(
        lines,
        contains(
          "\ttester.expectWidget(data: 'row', key: Keys.row(2));",
        ),
      );
      expect(
        lines,
        contains(
          '\t// No reverse lookup found for the text in the expect '
          'statements below',
        ),
      );
    });

    testWidgets('generates intl alternatives and reloads a changed path',
        (tester) async {
      final tempDirectory =
          Directory.systemTemp.createTempSync('approval_flutter_intl');
      addTearDown(() => tempDirectory.deleteSync(recursive: true));
      final firstFile = File(p.join(tempDirectory.path, 'first.json'))
        ..writeAsStringSync('{"title": "Hello", "greeting": "Hello"}');
      final secondFile = File(p.join(tempDirectory.path, 'second.json'))
        ..writeAsStringSync('{"replacement": "Hello"}');
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Text('Hello', key: ValueKey<String>('title')),
        ),
      );
      final session = ApprovalSession();

      final first = await tester.runAsync(
        () => collectWidgetsMetaData(
          tester,
          pathToStrings: firstFile.path,
          compareWithPrevious: false,
          session: session,
        ),
      );
      final samePath = await tester.runAsync(
        () => collectWidgetsMetaData(
          tester,
          pathToStrings: firstFile.path,
          compareWithPrevious: false,
          session: session,
        ),
      );
      final reloaded = await tester.runAsync(
        () => collectWidgetsMetaData(
          tester,
          pathToStrings: secondFile.path,
          compareWithPrevious: false,
          session: session,
        ),
      );

      expect(first, contains(contains('Multiple matches for "Hello"')));
      expect(first, contains(contains('s.title')));
      expect(first, contains(contains('s.greeting')));
      expect(samePath, first);
      expect(reloaded, contains(contains('s.replacement')));
      expect(reloaded, isNot(contains(contains('s.title'))));
    });

    testWidgets('manual intl data blocks a file reload', (tester) async {
      final tempDirectory =
          Directory.systemTemp.createTempSync('approval_flutter_manual_intl');
      addTearDown(() => tempDirectory.deleteSync(recursive: true));
      final lookupFile = File(p.join(tempDirectory.path, 'strings.json'))
        ..writeAsStringSync('{"fileValue": "Hello"}');
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Text('Hello', key: ValueKey<String>('title')),
        ),
      );
      final session = ApprovalSession();
      await addTextToIntlReverseLookup(
        stringId: 'manualValue',
        stringContent: 'Hello',
        session: session,
      );

      final lines = await collectWidgetsMetaData(
        tester,
        pathToStrings: lookupFile.path,
        session: session,
      );

      expect(lines, contains(contains('s.manualValue')));
      expect(lines, isNot(contains(contains('s.fileValue'))));
    });

    testWidgets('emits only changes and marks a removed widget absent',
        (tester) async {
      final session = ApprovalSession();
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [Text('removed'), Text('stable')],
          ),
        ),
      );
      await collectWidgetsMetaData(
        tester,
        outputMeta: true,
        session: session,
      );

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Text('stable'),
        ),
      );
      final delta = await collectWidgetsMetaData(
        tester,
        outputMeta: true,
        session: session,
      );
      final unchanged = await collectWidgetsMetaData(
        tester,
        outputMeta: true,
        session: session,
      );

      expect(
        delta,
        contains("Text: {data: 'removed', count: 0}"),
      );
      expect(
        unchanged,
        [
          "/// No changes to widget with keys or custom types since the prior "
              "call to 'generateExpects'",
        ],
      );
    });

    testWidgets('reports many matches in widget metadata', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [Text('same'), Text('same')],
          ),
        ),
      );

      final lines = await collectWidgetsMetaData(
        tester,
        outputMeta: true,
        compareWithPrevious: false,
        verbose: false,
        session: ApprovalSession(),
      );

      expect(lines, ["Text: {data: 'same', count: many}"]);
    });

    testWidgets('rejects a function key without another matching attribute',
        (tester) async {
      await tester.pumpWidget(
        const SizedBox(key: ValueKey<String>('Keys__row__2')),
      );

      await expectLater(
        collectWidgetsMetaData(
          tester,
          session: ApprovalSession(),
        ),
        throwsA(isA<Exception>()),
      );
    });

    testWidgets('silent capture updates delta memory without output',
        (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Text('silent'),
        ),
      );
      final session = ApprovalSession();

      final silent = await collectWidgetsMetaData(
        tester,
        silent: true,
        session: session,
      );
      final next = await collectWidgetsMetaData(tester, session: session);

      expect(silent, isEmpty);
      expect(
        next,
        [
          "/// No changes to widget with keys or custom types since the prior "
              "call to 'generateExpects'",
        ],
      );
    });

    testWidgets('explains when candidates produce no valid metadata',
        (tester) async {
      await tester.pumpWidget(
        _RegisteredBox(key: ObjectKey(Object())),
      );

      final lines = await collectWidgetsMetaData(
        tester,
        widgetTypes: {_RegisteredBox},
        session: ApprovalSession(),
      );

      expect(
        lines,
        ['/// No widget with keys or custom types found to test'],
      );
    });
  });

  group('getGesture', () {
    test('recognizes button and toggle names case-insensitively', () {
      expect(getGesture('SAVE_BUTTON'), 'onTap');
      expect(getGesture('accountToggle'), 'onTap');
    });

    test('returns null for empty and unrelated names', () {
      expect(getGesture(''), isNull);
      expect(getGesture('label'), isNull);
    });
  });
}
