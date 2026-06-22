import 'dart:io';

import 'package:approval_tests_flutter/approval_tests_flutter.dart';
import 'package:approval_tests_flutter/src/get_widget_names.dart';
import 'package:approval_tests_flutter/src/widget_meta/load_string_en.dart';
import 'package:approval_tests_flutter/src/widget_meta/semantics_snapshot.dart';
import 'package:approval_tests_flutter/src/widget_meta/widget_meta.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('loadWidgetNames', () {
    late Directory widgetNamesDirectory;
    late File widgetNamesFile;

    setUp(() {
      widgetNamesDirectory =
          Directory(ApprovalTestsConstants.resourceLocalPath);
      widgetNamesFile = File('${widgetNamesDirectory.path}/class_names.txt');
      if (widgetNamesDirectory.existsSync()) {
        widgetNamesDirectory.deleteSync(recursive: true);
      }
    });

    tearDown(() {
      if (widgetNamesDirectory.existsSync()) {
        widgetNamesDirectory.deleteSync(recursive: true);
      }
    });

    test('returns empty string when the widget names file is missing', () {
      expect(loadWidgetNames(), isEmpty);
    });

    test('returns file contents when the widget names file exists', () {
      widgetNamesDirectory.createSync(recursive: true);
      const fileContents = 'ExampleWidget\nAnotherWidget\n';
      widgetNamesFile.writeAsStringSync(fileContents);

      expect(loadWidgetNames(), fileContents);
    });
  });

  group('loadEnStringReverseLookup', () {
    late Directory tempDirectory;
    late String lookupFilePath;

    setUp(() async {
      tempDirectory =
          await Directory.systemTemp.createTemp('approval_tests_flutter_intl_');
      lookupFilePath = '${tempDirectory.path}/strings.json';
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('throws when the lookup file is missing', () async {
      expect(
        () => loadEnStringReverseLookup(lookupFilePath),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('builds a reverse lookup map for intl strings', () async {
      const lookupContents = '''
/* intl strings */
{
  "title": "Hello",
  "subtitle": "World"
}
''';
      final lookupFile = File(lookupFilePath)
        ..writeAsStringSync(lookupContents);

      final reverseLookup = await loadEnStringReverseLookup(lookupFile.path);

      expect(reverseLookup['Hello'], containsAll(<String>['title']));
      expect(reverseLookup['World'], containsAll(<String>['subtitle']));
      expect(
        reverseLookup['HELLO'],
        contains('title.toUpperCase()'),
      );
    });
  });

  group('WidgetMeta', () {
    test('hashCode matches equality semantics for deduplication', () {
      const widget = Text(
        'Example',
        key: ValueKey<String>('Example'),
      );

      final metaA = WidgetMeta(widget: widget);
      final metaB = WidgetMeta(widget: widget);

      expect(metaA, equals(metaB));
      expect(metaA.hashCode, equals(metaB.hashCode));
      final uniqueMetas = <WidgetMeta>{metaA, metaB};
      expect(uniqueMetas.length, 1);
    });
  });

  group('WidgetMeta key parsing', () {
    WidgetMeta metaFor(Key key) => WidgetMeta(widget: Container(key: key));

    test('parses a plain string ValueKey', () {
      final meta = metaFor(const ValueKey('counter'));
      expect(meta.keyType, KeyType.stringValueKey);
      expect(meta.keyString, "'counter'");
    });

    test('parses a dotted value as an enum-style key', () {
      final meta = metaFor(const ValueKey('MyEnum.value'));
      expect(meta.keyType, KeyType.enumValue);
      expect(meta.keyString, 'MyEnum.value');
    });

    test('parses a double-underscore key as Class.field', () {
      final meta = metaFor(const ValueKey('Keys__title'));
      expect(meta.keyType, KeyType.stringValueKey);
      expect(meta.keyString, 'Keys.title');
    });

    test('parses a triple-segment key as a function call', () {
      final meta = metaFor(const ValueKey('Keys__item__0'));
      expect(meta.keyType, KeyType.functionValueKey);
      expect(meta.keyString, 'Keys.item(0)');
    });
  });

  group('widget snapshot', () {
    setUpAll(() async {
      await ApprovalWidgets.setUpAll();
    });

    Widget twoTexts(String first) => MaterialApp(
          home: Column(
            children: [
              Text(first, key: const ValueKey('first')),
              const Text('stable', key: ValueKey('second')),
            ],
          ),
        );

    testWidgets(
      'returns a full self-contained snapshot on each call, not a delta',
      (tester) async {
        await tester.pumpWidget(twoTexts('alpha'));
        await tester.pumpAndSettle();
        final firstSnapshot = await tester.widgetsString;
        expect(firstSnapshot, contains("data: 'alpha'"));

        await tester.pumpWidget(twoTexts('omega'));
        await tester.pumpAndSettle();
        final secondSnapshot = await tester.widgetsString;

        // A delta-only snapshot would drop the unchanged widget and keep the
        // removed 'alpha' as a count:0 entry. The full snapshot does neither.
        expect(secondSnapshot, contains("key: 'second'"));
        expect(secondSnapshot, contains("data: 'omega'"));
        expect(secondSnapshot, isNot(contains("data: 'alpha'")));
      },
    );

    testWidgets('orders snapshot lines deterministically', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Column(
            children: [
              Text('zeta', key: ValueKey('z')),
              Text('alpha', key: ValueKey('a')),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final snapshot = await tester.widgetsString;
      final lines = snapshot.split('\n');
      final sortedLines = [...lines]..sort();
      expect(lines, sortedLines);
    });
  });

  group('semantics snapshot', () {
    testWidgets('captures labels and actions deterministically',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const Text('Title'),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Submit'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      String capture() {
        final handle = tester.ensureSemantics();
        try {
          return describeSemanticsTree(tester.getSemantics(find.byType(View)));
        } finally {
          handle.dispose();
        }
      }

      final snapshot = capture();

      expect(snapshot, contains("label: 'Title'"));
      expect(snapshot, contains("label: 'Submit'"));
      expect(snapshot, contains('tap'));
      expect(capture(), snapshot);
    });
  });
}
