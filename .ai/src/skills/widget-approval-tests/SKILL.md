---
name: "widget-approval-tests"
description: >-
  Use this skill when writing, adding, or fixing a widget, semantics, or golden approval test in this package, or when an approval test fails and snapshots need reviewing or re-approving. Triggers on "add a widget test", "approval test", "snapshot test", "approvalTest / approvalSemantics / approvalGolden", "the approved file is wrong", "re-approve", "update goldens", "passes locally but not in CI", and Russian phrasings like "добавь виджет-тест", "approval-тест падает", "почему не совпадает снимок", "переаппрувить". Covers setUpAll wiring, deterministic snapshots, and the received/approved review loop.
---

# Widget Approval Tests

Author and maintain approval tests for `approval_tests_flutter` — widget-tree, semantics, and golden snapshots — and run the received/approved review loop.

## Steps

1. Wire setup once per file — inside `setUpAll`, call `await ApprovalWidgets.setUpAll()`. This crawls the consumer's `/lib`, caches widget class names, and is required before any snapshot helper.
2. Build and settle the tree — `await tester.pumpWidget(...)` then `await tester.pumpAndSettle()`.
3. Snapshot with the helper that fits:
   - `await tester.approvalTest(description: '...')` — widget-tree meta snapshot.
   - `await tester.approvalSemantics(description: '...')` — accessibility tree, geometry-free.
   - `await tester.approvalGolden(find.byType(MyApp), description: '...')` — golden PNG alongside the text approvals.
   Pass a `description` whenever a test makes more than one snapshot; it is appended to the approval file name.
4. Run `flutter test`. The first run writes `*.received.txt` and fails because no approved file exists yet.
5. Review and approve — `dart run approval_tests:review --list`, then `dart run approval_tests:review <index>` to promote a received file to `*.approved.txt`. Re-run `flutter test` to confirm green.
6. For goldens, create or update the image with `flutter test --update-goldens`, then review the pixel diff before committing.

## Re-approving after an intentional output change

- Run the suite, confirm the new `*.received.txt` is what you expect, then promote it with the review CLI (or overwrite the `.approved.txt`). Add a CHANGELOG note — changed snapshot output is a breaking change for consumers.

## Gotchas

- Calling a snapshot helper without `ApprovalWidgets.setUpAll()` first throws an assertion ("setUpAll() was not called"); the cache (`_widgetNames`) must be loaded.
- A second `approvalTest()` in one test is a full snapshot, not a delta — output is sorted and self-contained (`compareWithPrevious: false`). Do not expect only the changed widget.
- Commit `*.approved.txt` (and approved `.png`); leave `*.received.*` and the `.approval_tests/` cache out of git — they are git-ignored and regenerated.
- Custom widget types appear in snapshots only if they are public classes in the consumer's `/lib` (private `_`-prefixed, `.g.dart`, and `.freezed.dart` classes are skipped) or registered via `registerTypes({MyWidget})`.
- A stale `.approval_tests/class_names.txt` is reused while it is newer than every `lib/*.dart`; delete the `.approval_tests/` folder if widget-name detection looks out of date.
- Under `flutter test`, the Dart SDK is found via `FLUTTER_ROOT`; plain `dart test` falls back to the resolved executable. A "could not find Dart SDK" error usually means `FLUTTER_ROOT` is unset.
