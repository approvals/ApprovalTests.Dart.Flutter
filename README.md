<div align="center">
<p align="center">
    <a href="https://github.com/approvals/ApprovalTests.Dart.Flutter" align="center">
        <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/approval_tests/approval_tests_flutter.png?raw=true" width="400px">
    </a>
</p>
</div>

<h2 align="center"> Approval Tests implementation in Flutter 🚀 </h2>
<br>
<p align="center">
  <a href="https://app.codecov.io/gh/approvals/ApprovalTests.Dart.Flutter"><img src="https://codecov.io/gh/approvals/ApprovalTests.Dart.Flutter/branch/main/graph/badge.svg" alt="codecov"></a>
  <a href="https://pub.dev/packages/approval_tests_flutter"><img src="https://img.shields.io/pub/v/approval_tests_flutter.svg" alt="Pub"></a>
  <a href="https://www.apache.org/licenses/"><img src="https://img.shields.io/badge/license-APACHE-blue.svg" alt="License: APACHE"></a>
  <!-- <a href="https://github.com/approvals/ApprovalTests.Dart.Flutter"><img src="https://hits.dwyl.com/approvals/ApprovalTests.Dart.Flutter.svg?style=flat" alt="Repository views"></a> -->
  <a href="https://github.com/approvals/ApprovalTests.Dart.Flutter"><img src="https://img.shields.io/github/stars/approvals/ApprovalTests.Dart.Flutter?style=social" alt="Stars"></a>
</p>
<p align="center">
  <a href="https://pub.dev/packages/approval_tests_flutter/score"><img src="https://img.shields.io/pub/likes/approval_tests_flutter?logo=flutter" alt="Pub likes"></a>
  <!-- <a href="https://pub.dev/packages/approval_tests_flutter/score"><img src="https://img.shields.io/pub/popularity/approval_tests_flutter?logo=flutter" alt="Pub popularity"></a> -->
  <a href="https://pub.dev/packages/approval_tests_flutter/score"><img src="https://img.shields.io/pub/points/approval_tests_flutter?logo=flutter" alt="Pub points"></a>
</p>
<!-- <p align="center">
  <a href="https://github.com/approvals/ApprovalTests.Dart.Flutter/actions/workflows/build_and_test.yml"><img src="https://github.com/approvals/ApprovalTests.Dart.Flutter/actions/workflows/build_and_test.yml/badge.svg" alt="Build and test badge"></a>
  <a href="https://github.com/approvals/ApprovalTests.Dart.Flutter/actions/workflows/publish.yml"><img src="https://github.com/approvals/ApprovalTests.Dart.Flutter/actions/workflows/publish.yml/badge.svg" alt="Deploy and Create Release"></a>
  <a href="https://github.com/approvals/ApprovalTests.Dart.Flutter/actions/workflows/mdsnippets.yml"><img src="https://github.com/approvals/ApprovalTests.Dart.Flutter/actions/workflows/mdsnippets.yml/badge.svg" alt="mdsnippets"></a>
</p> -->

## 📖 About

**[Approval Tests](https://approvaltests.com/)** complement focused assertions by
capturing a readable snapshot of a larger result and verifying that it has not
changed. This package can snapshot a Flutter widget tree, accessibility tree,
or golden image.

Use the smallest assertion that explains the behavior:

| Prefer approval testing for | Prefer `expect()` for |
| --- | --- |
| A screen with many meaningful widgets | A boolean, count, or calculation |
| Loading, loaded, empty, and error UI states | One or two exact properties |
| Accessibility trees and generated output | A business rule with one clear result |
| Regression coverage before a large refactor | An interaction that must call one dependency |

The two styles work well together: assert a precise state transition with
`expect()`, then approve the complete rendered state.

I am writing an implementation of **[Approval Tests](https://approvaltests.com/)** in Dart. If anyone wants to help, please **[text](https://t.me/yelmuratoff)** me. 🙏

Thanks to **[Richard Coutts](https://github.com/buttonsrtoys)** for special contributions to the `approval_tests_flutter` package.

## Packages

ApprovalTests is designed for two level: Dart and Flutter. <br>

| Package                                                                                             | Version                                                                                                              | Description                                                               |
| --------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------- |
| [approval_tests](https://github.com/approvals/ApprovalTests.Dart)                                  | [![Pub](https://img.shields.io/pub/v/approval_tests.svg?style=flat-square)](https://pub.dev/packages/approval_tests) | **Dart** package for approval testing of `unit` tests _(main)_            |
| [approval_tests_flutter](https://github.com/approvals/ApprovalTests.Dart.Flutter)                   | [![Pub](https://img.shields.io/pub/v/approval_tests_flutter.svg)](https://pub.dev/packages/approval_tests_flutter)   | **Flutter** package for approval testing of `widget`, `integration` tests |

## First Flutter approval test

1. Add the package to `dev_dependencies` because it is used from tests:

   ```yaml
   dev_dependencies:
     approval_tests_flutter: ^1.5.0
   ```

2. Ignore disposable output, but keep approved baselines in Git:

   ```gitignore
   *.received.*
   **/.approval_tests/
   ```

3. Create a widget test:

   ```dart
   import 'package:approval_tests_flutter/approval_tests_flutter.dart';
   import 'package:flutter/material.dart';
   import 'package:flutter_test/flutter_test.dart';

   void main() {
     setUpAll(ApprovalWidgets.setUpAll);
     tearDownAll(ApprovalWidgets.tearDownAll);

     testWidgets('renders the profile', (tester) async {
       await tester.pumpWidget(
         const MaterialApp(
           home: Scaffold(
             body: Text('Ada Lovelace'),
           ),
         ),
       );
       await tester.pumpAndSettle();

       await tester.approvalTest();
     });
   }
   ```

4. Run the test. The first run creates `*.approved.txt` and passes:

   ```shell
   flutter test test/profile_page_test.dart
   ```

5. Read the approved file before committing it. It is a test expectation, not
   disposable generated output. A later mismatch leaves `*.received.txt`,
   prints a diff, and fails. Review it with:

   ```shell
   dart run approval_tests:review
   ```

   Approve the change only when the new output is intentional, rerun the test,
   and commit the updated approved file with the code that required it.

> Each call to `approvalTest()` writes a **full, self-contained snapshot** of the
> current widget tree. Calling it several times in one test produces independent
> snapshots (e.g. before and after a tap), and snapshot lines are sorted so the
> output is stable across runs.

## State management in a medium or large project

The executable [Flutter example](example/flutter_example) includes two levels:
a minimal counter for a first approval test and an `orders` vertical slice that
shows how approvals fit a feature-first application:

```text
lib/
├── app.dart
├── main.dart
└── features/
    ├── counter/presentation/
    │   ├── counter_controller.dart
    │   └── counter_page.dart
    └── orders/
        ├── domain/
        │   ├── order.dart
        │   ├── orders_load_exception.dart
        │   └── orders_repository.dart
        ├── data/demo_orders_repository.dart
        └── presentation/
            ├── orders_controller.dart
            ├── orders_state.dart
            ├── orders_screen.dart
            └── orders_view.dart
test/
├── features/
│   ├── counter/presentation/
│   └── orders/
│       ├── domain/order_test.dart
│       └── presentation/
│           ├── orders_controller_test.dart
│           ├── orders_screen_test.dart
│           └── orders_screen_test.*.approved.txt
└── support/
    ├── fake_orders_repository.dart
    └── order_fixtures.dart
```

The orders presentation layer imports the domain repository interface, never
the data implementation. `main.dart` is the composition root that connects
them. Controller tests cover the `loading → loaded/failure` business flow,
while widget approvals cover the three complex rendered states: loading,
loaded, and failure.

```dart
expect(states, [isA<OrdersLoading>(), isA<OrdersLoaded>()]);

await tester.pumpWidget(
  ExampleApp(home: OrdersScreen(repository: repository)),
);
await tester.pumpAndSettle();
await tester.approvalTest();
```

The empty result and retry interaction use focused `expect()` assertions rather
than more snapshots. This keeps the approved set small as the application
grows. The same repository boundary and screen/view split work with BLoC,
Cubit, Riverpod, or Provider; only the state-holder implementation changes.

## 🧪 Snapshotting the accessibility tree

`approvalSemantics()` captures a deterministic, geometry-free description of the
rendered semantics tree (labels, values, hints, tooltips, identifiers, and
actions). It is a strong approval artifact for accessibility coverage and reads
cleanly in a diff:

```dart
    testWidgets('home screen semantics', (tester) async {
        await tester.pumpWidget(const MyApp());
        await tester.pumpAndSettle();

        await tester.approvalSemantics(description: 'home a11y');
    });
```

## 🖼 Golden (pixel) approvals

`approvalGolden()` wires Flutter's native golden workflow into the same naming
convention as the text approvals, so the `.png` sits next to the `.approved.txt`
files. Create or update the approved image with `flutter test --update-goldens`:

```dart
    testWidgets('home screen pixels', (tester) async {
        await tester.pumpWidget(const MyApp());
        await tester.pumpAndSettle();

        await tester.approvalGolden(find.byType(MyApp), description: 'home pixels');
    });
```

## 🎯 Matching widgets by type

Register your custom widget types to include them in approval snapshots and to
use the `expectWidget` / `tapWidget` finder helpers:

```dart
    setUpAll(() async {
      await ApprovalWidgets.setUpAll();
      registerTypes({MyButton, MyCard});
    });
    tearDownAll(ApprovalWidgets.tearDownAll);

    tester.expectWidget(key: MyKeys.submit, matcher: findsOneWidget);
    await tester.tapWidget(intl: (_) => 'Submit');
```

Register from `setUpAll`. Registrations, the discovered class names, the intl
string holder set through `WidgetTesterExtension.s`, and the previous-capture
memory all belong to one capture session scoped to the
`setUpAll` → `tearDownAll` window.

`ApprovalWidgets.tearDownAll()` is optional: leave it out and state persists for
the whole test process, exactly as before 1.5.0. Add it when one test file has
groups with different registrations — without it, a `registerTypes` call in one
group is still in effect for every later group in that file, which changes
their snapshots.

For backwards compatibility, `tapWidget()` calls `pumpAndSettle()` after the
tap. Flutter's default settle timeout is ten minutes, so an indeterminate
animation can make a test wait much longer than intended. New tests should
choose an explicit pump policy:

```dart
    // Dispatch the tap without rendering another frame.
    await tester.tapWidget(
      intl: (_) => 'Submit',
      pumpPolicy: const WidgetActionPumpPolicy.none(),
    );

    // Render exactly one frame.
    await tester.tapWidget(
      intl: (_) => 'Submit',
      pumpPolicy: const WidgetActionPumpPolicy.once(),
    );

    // Advance the test clock by a fixed duration and render one frame.
    await tester.tapWidget(
      intl: (_) => 'Submit',
      pumpPolicy: const WidgetActionPumpPolicy.forDuration(
        Duration(milliseconds: 300),
      ),
    );

    // Settle with an explicit frame step and upper time bound.
    await tester.tapWidget(
      intl: (_) => 'Submit',
      pumpPolicy: const WidgetActionPumpPolicy.untilSettled(
        step: Duration(milliseconds: 50),
        timeout: Duration(seconds: 2),
      ),
    );
```

The legacy `shouldPumpAndSettle` parameter is deprecated. Its default behavior
will remain unchanged throughout 1.x; use
`WidgetActionPumpPolicy.none()` instead of passing `false`. When both parameters
are supplied, `pumpPolicy` takes precedence.

Approval capture helpers (`approvalTest`, `approvalSemantics`, and
`approvalGolden`) never pump or settle implicitly.

## 🔎 Widget-name discovery and its cache

`ApprovalWidgets.setUpAll()` parses your project's `lib/` and collects the
public class names, so a snapshot can label a widget by its own type rather
than by the nearest framework type. Results are cached in
`test/.approval_tests/class_names.txt`, which is generated and belongs in
`.gitignore`.

The cache is validated by fingerprint, not by modification time. The stored
token covers a schema revision, the package root, the Dart SDK path and
version, and every scanned source's relative path, size, and timestamp. A
modification-time check alone would miss three ordinary cases — deleting a file
that is not the newest, checking out a branch whose files carry older
timestamps, and renaming with timestamps preserved — and each of those would
leave the cache silently stale, dropping lines from a snapshot.

Consequences worth knowing:

- A fresh CI checkout rewrites every timestamp, so CI always rescans. That is
  correct rather than a regression.
- Any cache problem — missing, truncated, written by an older version, copied
  from another checkout — is a rescan, never an error. A cache must not fail
  your test run.
- The cache is written through a temporary file and a rename. `flutter test`
  runs test files in parallel processes that share one cache file, so a direct
  write is observable by another process as a truncated file.
- Only the fingerprint digest is stored, never the package root or SDK path, so
  the file carries no absolute paths from your machine.

### Why `analyzer` is a runtime dependency

`package:analyzer` sits in `dependencies`, not `dev_dependencies`, and that is
deliberate. Discovery runs inside *your* `setUpAll` and parses *your* sources.
Pub does not install a published package's dev dependencies for downstream
consumers, so moving `analyzer` there would make the import unresolvable in
every consumer's test run.

It can only move once discovery stops happening at test time — either a
build-time step that checks in the generated name list, or a separate
`_gen`-style package you add as a dev dependency. Until then, note that
`analyzer` and `_fe_analyzer_shared` are the heaviest transitive dependencies
this package brings in.

## Coverage

The 1.5.0 release has 100% line coverage for executable code under `lib`
(594/594 lines). The full suite passes all 100 test executions.

To reproduce the report locally:

```shell
flutter test --coverage
```

## 📚 How to use

In order to use `Approval Tests`, the user needs to:

1. Set up a test: This involves importing the Approval Tests library into your own code.

2. Optionally, set up a reporter: Reporters are tools that highlight differences between approved and received files when a test fails. Although not necessary, they make it significantly easier to see what changes have caused a test to fail. The default reporter is the `CommandLineReporter`. You can also use the `DiffReporter` to compare the files in your IDE, and the `GitReporter` to see the differences in the `Git GUI`.

3. Manage the `approved` file: When the test is run for the first time, an approved file is created automatically. This file will represent the expected outcome. Once the test results in a favorable outcome, the approved file should be updated to reflect these changes. A little bit below I wrote how to do it.

This setup is useful because it shortens feedback loops, saving developers time by only highlighting what has been altered rather than requiring them to parse through their entire output to see what effect their changes had.

### Approving Results

Approving results just means saving the `.approved.txt` file with your desired results.

We’ll provide more explanation in due course, but, briefly, here are the most common approaches to do this.

#### • Via Diff Tool

Most diff tools have the ability to move text from left to right, and save the result.
How to use diff tools is just below, there is a `Comparator` class for that.

#### • Via CLI command

You can run the command in a terminal to review your files:

```bash
dart run approval_tests:review
```

After running the command, the files will be analyzed and you will be asked to choose one of the options:

- `y` - Approve the received file.
- `n` - Reject the received file.
- `v`iew - View the differences between the received and approved files. After selecting `v` you will be asked which IDE you want to use to view the differences.

The command `dart run approval_tests:review` has additional options, including listing files, selecting
files to review from this list by index, and more. For its current capabilities, run

```bash
  dart run approval_tests:review --help
```

Typing 'dart run approval_tests:review' is tedious! To reduce your typing, alias the command in your
`.zshrc` or `.bashrc` file

```
  alias review='dart run approval_tests:review'
```

or PowerShell profile

```shell
  function review {
      dart run approval_tests:review
  }
```

#### • Via approveResult property

`approveResult` is a deliberate local migration tool for creating or replacing
many baselines. Remove it immediately after reviewing the generated files. Do
not enable it in normal tests or CI: automation should verify approved output,
not silently replace it.

```dart
void main() {
  test('test JSON object', () {
    final complexObject = {
      'name': 'JsonTest',
      'features': ['Testing', 'JSON'],
      'version': 0.1,
    };

    Approvals.verifyAsJson(
      complexObject,
      options: const Options(
        approveResult: true,
      ),
    );
  });
}
```

this will result in the following file
`example_test.test_JSON_object.approved.txt`

```txt
{
  "name": "JsonTest",
  "features": [
    "Testing",
    "JSON"
  ],
  "version": 0.1
}
```

#### • Via file rename

You can just rename the `.received` file to `.approved`.

### Reporters

Reporters are the part of Approval Tests that launch diff tools when things do not match. They are the part of the system that makes it easy to see what has changed.

There are several reporters available in the package:

- `CommandLineReporter` - This is the default reporter, which will output the diff in the terminal.
- `GitReporter` - This reporter will open the diff in the Git GUI.
- `DiffReporter` - This reporter will open the Diff Tool in your IDE.
  - For Diff Reporter I using the default paths to the IDE, if something didn't work then you in the console see the expected correct path to the IDE and specify customDiffInfo. You can also contact me for help.

<img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/approval_tests/diff_command_line.png?raw=true" alt="CommandLineComparator img" title="ApprovalTests" style="max-width: 500px;">

To use `DiffReporter` you just need to add it to `options`:

```dart
 options: const Options(
   reporter: const DiffReporter(),
 ),
```

<div style="display: flex; justify-content: center; align-items: center;">
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/approval_tests/diff_tool_vs_code.png?raw=true" alt="Visual Studio code img" style="width: 45%;margin-right: 1%;" />
  <img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/approval_tests/diff_tool_studio.png?raw=true" alt="Android Studio img" style="width: 45%;" />
</div>

## 📝 Examples

The [Flutter example project](example/flutter_example) is executable and shows
dependency-injected state management, snapshots before and after an
interaction, focused assertions alongside approvals, feature-first folders,
and committed baselines. The core
[`approval_tests`](https://github.com/approvals/ApprovalTests.Dart) repository
contains the JSON, query, sequence, and generated-text examples.

### JSON example

With `verifyAsJson`, if you pass data models as `JsonItem`, with nested other models as `AnotherItem` and `SubItem`, then you need to add an `toJson` method to each model for the serialization to succeed.

```dart
void main() {
  const jsonItem = JsonItem(
    id: 1,
    name: "JsonItem",
    anotherItem: AnotherItem(id: 1, name: "AnotherItem"),
    subItem: SubItem(
      id: 1,
      name: "SubItem",
      anotherItems: [
        AnotherItem(id: 1, name: "AnotherItem 1"),
        AnotherItem(id: 2, name: "AnotherItem 2"),
      ],
    ),
  );

  test('verify model', () {
    Approvals.verifyAsJson(jsonItem);
  });
}
```

this will result in the following file
`verify_as_json_test.verify_model.approved.txt`

```txt
{
  "jsonItem": {
    "id": 1,
    "name": "JsonItem",
    "subItem": {
      "id": 1,
      "name": "SubItem",
      "anotherItems": [
        {
          "id": 1,
          "name": "AnotherItem 1"
        },
        {
          "id": 2,
          "name": "AnotherItem 2"
        }
      ]
    },
    "anotherItem": {
      "id": 1,
      "name": "AnotherItem"
    }
  }
}
```

<img src="https://github.com/yelmuratoff/packages_assets/blob/main/assets/approval_tests/passed.png?raw=true" alt="Passed test example" title="ApprovalTests" style="max-width: 800px;">

## Managing snapshots on a team

Treat approval files like test code:

| Artifact | Source control policy |
| --- | --- |
| `*.approved.txt` and approved `.png` goldens | Review and commit |
| `*.received.*` | Inspect locally, never commit |
| `**/.approval_tests/` | Ignore; this is a generated cache |

Use this `.gitignore` baseline:

```gitignore
*.received.*
**/.approval_tests/
```

For every snapshot change, reviewers should confirm that the diff expresses an
intentional product change, contains no timestamps, random IDs, machine paths,
or personal data, and stays small enough to understand. Prefer focused
snapshots over one application-wide artifact.

At scale, keep state transitions and business rules in fast unit tests. Approve
only core rendered states, reuse scenario fakes or fixtures across the feature,
and add theme, locale, or text-scale variants deliberately instead of
multiplying every snapshot by every possible combination.

CI must never run with `approveResult: true` or `--update-goldens`. Because the
default first-run workflow creates a missing approved file, CI should also fail
when tests leave an untracked or modified `*.approved.*` artifact. This catches
a deleted or forgotten baseline instead of accepting it silently.

Use a version-independent guard after the test step:

```yaml
- name: Verify approval baselines
  run: |
    git diff --exit-code -- '*.approved.*'
    test -z "$(git ls-files --others --exclude-standard -- '*.approved.*')"
```

Projects that resolve `approval_tests` 1.7.0 or newer can additionally make
missing baselines fail at verification time:

```dart
await tester.approvalTest(
  options: const Options(
    missingApprovedPolicy: MissingApprovedPolicy.writeReceivedAndFail,
  ),
);
```

Keep the Git guard as well: strict verification catches a missing baseline,
while Git catches an intentionally or accidentally changed one.

## ✉️ For More Information

### Questions?

Ask me on Telegram: [`@yelmuratoff`](https://t.me/yelmuratoff).  
Email: [`yelamanyelmuratov@gmail.com`](mailto:yelamanyelmuratov@gmail.com)

### Video Tutorials

- [Getting Started with ApprovalTests.Swift](https://qualitycoding.org/approvaltests-swift-getting-started/)
- [How to Verify Objects (and Simplify TDD)](https://qualitycoding.org/approvaltests-swift-verify-objects/)
- [Verify Arrays and See Simple, Clear Diffs](https://qualitycoding.org/verify-arrays-approvaltests-swift/)
- [Write Parameterized Tests by Transforming Sequences](https://qualitycoding.org/parameterized-tests-approvaltests-swift/)
- [Wrangle Legacy Code with Combination Approvals](https://qualitycoding.org/wrangle-legacy-code-combination-approvals/)

You can also watch a series of short videos about [using ApprovalTests in .Net](https://www.youtube.com/playlist?list=PL0C32F89E8BBB5368) on YouTube.

### Podcasts

Prefer learning by listening? Then you might enjoy the following podcasts:

- [Hanselminutes](https://www.hanselminutes.com/360/approval-tests-with-llewellyn-falco)
- [Herding Code](https://www.developerfusion.com/media/122649/herding-code-117-llewellyn-falcon-on-approval-tests/)
- [The Watir Podcast](https://watirpodcast.com/podcast-53/)

## Coverage

[![](https://codecov.io/gh/approvals/ApprovalTests.Dart.Flutter/branch/main/graphs/sunburst.svg)](https://codecov.io/gh/approvals/ApprovalTests.Dart.Flutter/branch/main)

## 🤝 Contributing

Show some 💙 and <a href="https://github.com/approvals/ApprovalTests.Dart.Flutter">star the repo</a> to support the project! 🙌  
The project is in the process of development and we invite you to contribute through pull requests and issue submissions. 👍  
We appreciate your support. 🫰

<br><br>

<div align="center" >
  <p>Thanks to all contributors of this package</p>
  <a href="https://github.com/approvals/ApprovalTests.Dart.Flutter/graphs/contributors">
    <img src="https://contrib.rocks/image?repo=approvals/ApprovalTests.Dart.Flutter" />
  </a>
</div>
<br>
