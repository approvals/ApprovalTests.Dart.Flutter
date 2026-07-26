import 'dart:io';
import 'dart:typed_data';

import 'package:approval_tests_flutter/approval_tests_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDirectory;

  setUp(() {
    tempDirectory =
        Directory.systemTemp.createTempSync('approval_flutter_extensions');
  });

  tearDown(() {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  Options approvalOptions(String sourceName) => Options(
        approveResult: true,
        logResults: false,
        namer: Namer(
          filePath: p.join(tempDirectory.path, sourceName),
          addTestName: false,
        ),
      );

  testWidgets('approvalTest uses caller text and description', (tester) async {
    await tester.approvalTest(
      description: 'manual',
      textForReview: 'review me',
      options: approvalOptions('manual_test.dart'),
    );

    final approved = tempDirectory
        .listSync()
        .whereType<File>()
        .singleWhere((file) => file.path.endsWith('.approved.txt'));
    expect(approved.path, contains('manual'));
    expect(approved.readAsStringSync(), contains('review me'));
  });

  testWidgets('approvalSemantics approves the rendered semantics tree',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Semantics(
          label: 'Accessible label',
          button: true,
          child: const SizedBox(width: 10, height: 10),
        ),
      ),
    );

    await tester.approvalSemantics(
      description: 'semantics',
      options: approvalOptions('semantics_test.dart'),
    );

    final approved = tempDirectory
        .listSync()
        .whereType<File>()
        .singleWhere((file) => file.path.endsWith('.approved.txt'));
    expect(approved.readAsStringSync(), contains('Accessible label'));
  });

  testWidgets('approvalGolden derives a colocated PNG name', (tester) async {
    final previousComparator = goldenFileComparator;
    final comparator = _RecordingGoldenComparator();
    goldenFileComparator = comparator;
    addTearDown(() => goldenFileComparator = previousComparator);
    await tester.pumpWidget(
      const RepaintBoundary(
        child: SizedBox(width: 10, height: 10),
      ),
    );

    await tester.approvalGolden(
      find.byType(SizedBox),
      description: 'pixels',
    );

    expect(comparator.compared, isNotNull);
    expect(comparator.compared!.path, endsWith('.pixels.png'));
  });
}

final class _RecordingGoldenComparator extends GoldenFileComparator {
  Uri? compared;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    compared = golden;
    return true;
  }

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) async {
    compared = golden;
  }
}
