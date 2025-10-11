import 'dart:io';

import 'package:approval_tests/approval_tests.dart';
import 'package:approval_tests_flutter/src/get_widget_names.dart';
import 'package:approval_tests_flutter/src/widget_meta/load_string_en.dart';
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
}
