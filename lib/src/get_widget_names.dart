import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:approval_tests/approval_tests.dart';
import 'package:approval_tests_flutter/src/common.dart';

final _widgetNamesDir = Directory(ApprovalTestsConstants.resourceLocalPath);
final _widgetNamesPath = '${_widgetNamesDir.path}/class_names.txt';

Future<Set<String>> getWidgetNames() async {
  if (await isWidgetNamesFileFresh()) {
    return readWidgetsFile(_widgetNamesPath);
  }

  final libPath = '${Directory.current.absolute.path}/lib';
  ApprovalLogger.log(
    'package:approval_tests_flutter: searching for class names in $libPath...',
  );

  final widgetNames = await extractWidgetNames(libPath);

  _widgetNamesDir.createSync(recursive: true);
  final widgetNamesString = widgetNames.join('\n').endWithNewline;
  File(_widgetNamesPath).writeAsStringSync(
      '${ApprovalTestsConstants.widgetHeader}\n$widgetNamesString');

  return widgetNames;
}

String _resolveDartSdkPath() {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null && flutterRoot.isNotEmpty) {
    return '$flutterRoot/bin/cache/dart-sdk';
  }
  // Fallback for plain `dart test`, where the executable is the Dart binary.
  return File(Platform.resolvedExecutable).parent.parent.path;
}

String loadWidgetNames() {
  final widgetNamesFile = File(_widgetNamesPath);
  if (!widgetNamesFile.existsSync()) {
    return '';
  }
  return widgetNamesFile.readAsStringSync();
}

/// Crawls the project and extracts public class names from the `/lib` folder.
///
/// Resolves the Dart SDK from `FLUTTER_ROOT` (set by `flutter test`) so no
/// `flutter` process is spawned. Under `flutter test`,
/// `Platform.resolvedExecutable` points at the `flutter_tester` engine rather
/// than the Dart binary, so it is only a fallback for plain `dart test`.
Future<Set<String>> extractWidgetNames(String libPath) async {
  final collection = AnalysisContextCollection(
    includedPaths: [libPath],
    sdkPath: _resolveDartSdkPath(),
  );
  final analysisContext = collection.contexts.first;

  final classNames = <String>{};
  final libDirectory = Directory(libPath);
  final dartFiles = libDirectory.listSync(recursive: true).where(
        (file) =>
            file.path.endsWith('.dart') &&
            !file.path.contains('.g.dart') &&
            !file.path.contains('.freezed.dart'),
      );

  for (final file in dartFiles) {
    final parsedResult =
        analysisContext.currentSession.getParsedUnit(file.path);
    // Skip files the analyzer cannot parse (e.g., syntax errors in user code).
    if (parsedResult is! ParsedUnitResult) {
      continue;
    }

    for (final member in parsedResult.unit.declarations) {
      if (member is ClassDeclaration) {
        final name = member.namePart.typeName.lexeme;
        if (!name.startsWith('_')) {
          classNames.add(name);
        }
      }
    }
  }

  return classNames;
}

Future<Set<String>> readWidgetsFile(String filePath) async {
  final text = await File(filePath).readAsString();
  return text
      .split('\n')
      .where((line) => line.isNotEmpty && !line.startsWith('#'))
      .toSet();
}

Future<bool> isWidgetNamesFileFresh() async {
  final newestDartFile = await findNewestDartFileTimestamp(Directory('lib'));
  if (newestDartFile == null) {
    return false;
  }

  final widgetNamesFile = File(_widgetNamesPath);
  return widgetNamesFile.existsSync() &&
      widgetNamesFile.lastModifiedSync().isAfter(newestDartFile);
}

Future<DateTime?> findNewestDartFileTimestamp(Directory dir) async {
  DateTime? newestTimestamp;

  if (!await dir.exists()) {
    return null;
  }

  await for (final FileSystemEntity entity in dir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final DateTime lastModified = await entity.lastModified();

      if (newestTimestamp == null || lastModified.isAfter(newestTimestamp)) {
        newestTimestamp = lastModified;
      }
    }
  }

  return newestTimestamp;
}
