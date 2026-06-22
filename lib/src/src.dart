import 'package:approval_tests/approval_tests.dart';
import 'package:approval_tests_flutter/src/get_widget_names.dart';
import 'package:approval_tests_flutter/src/widget_meta/collect_widgets_meta_data.dart'
    as widgets_meta_data;
import 'package:approval_tests_flutter/src/widget_meta/semantics_snapshot.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

export 'package:approval_tests_flutter/src/widget_meta/register_types.dart'
    show registerTypes;
export 'package:approval_tests_flutter/src/widget_meta/widget_tester_extension.dart';

Set<String>? _widgetNames;

/// Top-level helpers for configuring approval-based widget tests.
class ApprovalWidgets {
  /// File path extractor used when building widget approval namers.
  static const FilePathExtractor filePathExtractor =
      FilePathExtractor(stackTraceFetcher: StackTraceFetcher());

  /// Builds a database of the project's class names so approval tests can match
  /// widgets by their custom type.
  ///
  /// Typically called from within a flutter_test `setUpAll` callback.
  static Future<Set<String>> setUpAll() async {
    final names = await getWidgetNames();
    _widgetNames = names;
    return names;
  }

  /// Cached set of project widget names discovered during [setUpAll].
  static Set<String>? get widgetNames => _widgetNames;
}

Future<void> _runApprovalTest(
  String? description,
  String value,
  Options? options,
) async {
  final base = options ?? const Options();
  Approvals.verify(
    value,
    options: base.copyWith(
      namer: base.namer.copyWith(description: description),
    ),
  );
}

extension WidgetTesterApprovedExtension on WidgetTester {
  /// Returns the widget-tree meta data used as the approval snapshot.
  Future<String> get widgetsString async {
    assert(_widgetNames != null, '''
    Looks like ApprovalWidgets.setUpAll() was not called before running an approvalTest. Typically,
    this issue is solved by calling it from within setUpAll:

        setUpAll(() async {
          await ApprovalWidgets.setUpAll();
        });
''');

    final metaLines = await widgets_meta_data.collectWidgetsMetaData(
      this,
      outputMeta: true,
      verbose: false,
      // Each approval snapshot must be self-contained — a full picture of the
      // tree, not a diff from a prior approvalTest() call that shares this
      // isolate's cached widget metas.
      compareWithPrevious: false,
      widgetNames: ApprovalWidgets.widgetNames,
    )
      // Sort so the snapshot is stable across runs regardless of tree-traversal
      // order; otherwise approvals flake on insertion-order changes.
      ..sort();

    return metaLines.join('\n');
  }

  /// Performs an approval test against the current widget tree.
  ///
  /// [description] is appended to the generated approval file name.
  /// [textForReview] overrides the captured widget-tree meta data.
  /// [options] are forwarded to [Approvals.verify].
  Future<void> approvalTest({
    String? description,
    String? textForReview,
    Options? options,
  }) async {
    final value = textForReview ?? await widgetsString;
    await _runApprovalTest(description, value, options);
  }

  /// Outputs generated `expect` statements for the current tree to the console.
  ///
  /// [widgetTypes] registers custom widget types to match with `find.byType`.
  /// [widgetNames] overrides the project class names discovered during setup.
  Future<void> printExpects({
    Set<Type>? widgetTypes,
    Set<String>? widgetNames,
  }) =>
      widgets_meta_data.printExpects(
        this,
        widgetTypes: widgetTypes,
        widgetNames: widgetNames ?? ApprovalWidgets.widgetNames,
      );

  /// Performs an approval test on the rendered accessibility (semantics) tree.
  ///
  /// Captures a deterministic, geometry-free description of the semantics tree
  /// (labels, values, hints, tooltips, identifiers, and actions), making it a
  /// strong approval artifact for accessibility coverage in widget and
  /// integration tests.
  ///
  /// [description] is appended to the generated approval file name.
  /// [options] are forwarded to [Approvals.verify].
  Future<void> approvalSemantics({
    String? description,
    Options? options,
  }) async {
    final handle = ensureSemantics();
    try {
      final viewFinder = find.byType(View);
      final root =
          viewFinder.evaluate().isEmpty ? null : getSemantics(viewFinder);
      await _runApprovalTest(description, describeSemanticsTree(root), options);
    } finally {
      handle.dispose();
    }
  }

  /// Verifies a golden image of [finder] against an approved PNG.
  ///
  /// The golden file is named to sit alongside the text approvals
  /// (`<test_file>.<test_name>.<description>.png`), keeping pixel and text
  /// snapshots together. Run with `flutter test --update-goldens` to (re)create
  /// the approved image.
  Future<void> approvalGolden(
    Finder finder, {
    String? description,
  }) async {
    final namer = Namer(
      filePath: ApprovalWidgets.filePathExtractor.filePath,
      description: description,
    );
    final goldenName =
        namer.approvedFileName.replaceAll('.approved.txt', '.png');
    await expectLater(finder, matchesGoldenFile(goldenName));
  }
}
