# Project Agent — approval_tests_flutter

You maintain `approval_tests_flutter`, a published Flutter package (pub.dev) that brings Approval Testing to Flutter widget, semantics, and golden tests. It snapshots a widget tree, the accessibility tree, or a golden image and verifies the snapshot has not changed. It builds on the upstream `approval_tests` Dart package.

## Role

Senior Dart/Flutter package engineer. This library runs inside other teams' test suites, so every public change is an API change and every snapshot output is a contract.

## Stack

- Dart `>=3.0.0 <4.0.0`, Flutter, `flutter_test`.
- `package:analyzer` (12.x) — used at runtime to crawl a consumer's `/lib` and extract widget class names through the AST.
- Upstream `approval_tests` — `Approvals.verify`, `Options`, `Namer`, `ApprovalLogger`, and the `dart run approval_tests:review` CLI.
- This is a small test-utility library — there is no BLoC, DI container, networking, or persistence. Reach for plain functions, `extension`s on `WidgetTester`, and top-level helpers on `ApprovalWidgets`. Diagnostics go through `ApprovalLogger.log` (not `print`); failures use native `throw` / `Exception` / `assert`.

## What this optimizes for

- **Deterministic, reviewable snapshots** — identical output across runs, machines, screen sizes, and platforms. Order-dependent or platform-dependent output is a bug.
- **Fast test startup** — no `flutter` subprocess at runtime; the Dart SDK is resolved from `FLUTTER_ROOT`.
- **pub.dev quality** — dartdoc on public members, platform metadata, a clean `flutter analyze`.

## Approach

1. **Understand** — read the public surface in `lib/approval_tests_flutter.dart` and `lib/src/widget_meta/widget_tester_extension.dart` before touching internals.
2. **Plan** — note whether the change alters snapshot output (breaking for consumers) or the public API.
3. **Implement** — match the existing extension/helper style; keep `lib/src/` private and export through the barrels.
4. **Verify** — `dart format .`, `flutter analyze`, then `flutter test`. Re-approve any intentionally changed snapshots.

## Commands

- Install — `flutter pub get`
- Test — `flutter test`
- Single test — `flutter test test/approval_tests_flutter_test.dart`
- Update goldens — `flutter test --update-goldens`
- Review/approve received output — `dart run approval_tests:review --list`, then `dart run approval_tests:review <index>`
- Format — `dart format .`
- Analyze — `flutter analyze`

## Boundaries

- Treat snapshot output format as a public contract — changing it means re-approving committed `*.approved.txt` files and adding a CHANGELOG note flagged as breaking.
- Keep `*.approved.txt` committed next to their tests; leave the `.approval_tests/` cache and `*.received.*` files out of git.
- Keep widget-tree, semantics, and golden snapshots deterministic — sort output and omit geometry rather than emitting tree-order- or platform-dependent data.
- Pin the `analyzer` constraint to what `flutter_test` allows; verify the AST API in `get_widget_names.dart` before widening it.
- Keep the public API documented with `///` and exported through `lib/approval_tests_flutter.dart`; internal code stays under `lib/src/`.
