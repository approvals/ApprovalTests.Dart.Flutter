---
name: approval-tests-flutter-widget-testing
description: "Use when writing or reviewing approval_tests_flutter widget, semantics, or golden tests."
---

# Flutter widget approval tests

Use the public import
`package:approval_tests_flutter/approval_tests_flutter.dart`. It also exports
the core `approval_tests` API, including `Options` and `Namer`. Add
`approval_tests_flutter` and SDK `flutter_test` to `dev_dependencies`.
This skill describes Flutter package 1.5.2; check the resolved versions before
using newer core APIs.

## Choose the assertion

- Use `tester.approvalTest()` for readable widget metadata: text, keys, types,
  and counts. Each capture is a full snapshot, not a delta of the last one.
- Use `tester.approvalSemantics()` for accessibility labels, values, hints,
  identifiers, and actions. It manages its semantics handle and omits geometry.
- Use `tester.approvalGolden(finder)` when pixels, layout, or visual styling
  are the requirement. Widget metadata does not verify those properties.
- Keep focused assertions for interactions and business rules. Snapshot
  loading, loaded, empty, and error states using injected deterministic fakes;
  do not snapshot incidental implementation details or live service output.

## Set up and capture

Call and await `ApprovalWidgets.setUpAll()` from `setUpAll` before capturing
widget metadata. It discovers widget classes from the consumer's `lib/`.
Register additional types with `registerTypes({MyWidget})` during setup when
needed. `ApprovalWidgets.tearDownAll()` clears capture registrations and
localization state; use it to keep groups with different setups independent.

```dart
import 'package:approval_tests_flutter/approval_tests_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('profile approvals', () {
    setUpAll(() async {
      await ApprovalWidgets.setUpAll();
    });
    tearDownAll(ApprovalWidgets.tearDownAll);

    testWidgets('renders the profile', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('Ada Lovelace')),
        ),
      );
      await tester.pumpAndSettle();

      await tester.approvalTest(description: 'content');
      await tester.approvalSemantics(description: 'accessibility');
    });
  });
}
```

Run `flutter test`. Default text verification creates a missing approved file
and passes; inspect the generated baseline before committing. On a mismatch,
received text remains available for review.

Capture helpers never pump implicitly. Pump after interactions and await
every capture. For infinite animations or loading indicators, use a bounded
`tester.pump(duration)` or an explicit `WidgetActionPumpPolicy.forDuration`
with action helpers instead of `pumpAndSettle()`, which cannot settle an
infinite animation. `tapWidget` still requires its `intl` callback; use native
`tester.tap(find.byKey(...))` when localization lookup is unnecessary.

Give each capture in one test a unique `description`, including captures of
different kinds. Text and semantics share the same naming scheme. Use names
without path separators; pass path configuration through `Options.namer`.
Use `textForReview` on `approvalTest` only when supplying your own intentional
text representation instead of captured widget metadata.

## Pixel snapshots

```dart
import 'package:approval_tests_flutter/approval_tests_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the profile pixels', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 600);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Text('Ada Lovelace')),
      ),
    );
    await tester.pumpAndSettle();
    await tester.approvalGolden(
      find.byType(Scaffold),
      description: 'profile pixels',
    );
  });
}
```

Pin fonts, theme, locale, text scale, and runner platform as needed for the
app. The helper uses Flutter's `matchesGoldenFile`, with a `.png` name beside
the test rather than `.approved.txt`. It accepts a finder and description,
not core `Options` or `approveResult`. Generate or update images only in an
explicitly requested local baseline workflow with
`flutter test --update-goldens`; review the images and rerun without that flag.
The text review CLI does not review PNG goldens.

## Review and CI

- List text mismatches with `dart run approval_tests:review --list`, then run
  `dart run approval_tests:review` or pass a listed index or received path.
  View the diff before approving. A mismatch alone does not authorize
  changing a baseline; keep approval within the user's requested scope.
- Commit reviewed `*.approved.txt` and expected `.png` files. Ignore
  `*.received.*` and `**/.approval_tests/`; the widget-name cache is disposable.
- Never run CI with `approveResult: true` or `--update-goldens`. Guard against
  modified or untracked text baselines after testing, since default missing
  baselines are created automatically:

  ```sh
  git diff --exit-code -- '*.approved.*'
  test -z "$(git ls-files --others --exclude-standard -- '*.approved.*')"
  ```

- If the resolved core package is 1.5.0 or newer, pass
  `const Options(missingApprovedPolicy: MissingApprovedPolicy.writeReceivedAndFail)`
  to text and semantics captures to fail on missing baselines without writing
  them. The Flutter package permits older core versions, so check the lockfile
  before adding this option. Keep the Git guard as well.
- Validate changes with `flutter analyze` and the affected `flutter test`
  command. Use the app's existing test harness and snapshot fixtures.
