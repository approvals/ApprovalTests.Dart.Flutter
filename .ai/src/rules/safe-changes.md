# Safe-Change Rules

A few areas break consumers or CI silently. Flag the risk and verify before editing.

## Flag before changing

- **Snapshot output format** — any change to widget-meta, semantics, or expect-string formatting invalidates every committed `*.approved.txt`. Re-approve, add a CHANGELOG entry, and call it out as a breaking change.
- **`analyzer` version constraint** (`>=12.0.0 <14.0.0`) — coupled to the `analyzer` that `flutter_test`'s pinned `test` / `test_api` require. Widening it risks an unresolvable version conflict; verify against the current Flutter SDK first.
- **Analyzer AST usage** in `get_widget_names.dart` — widget-name extraction uses the analyzer-12 API (`ClassDeclaration.namePart.typeName.lexeme`). Confirm the AST shape before bumping `analyzer`.
- **Dart SDK resolution** in `_resolveDartSdkPath()` — resolves from `FLUTTER_ROOT` because under `flutter test`, `Platform.resolvedExecutable` points at the `flutter_tester` engine, not the Dart binary. Keep the `FLUTTER_ROOT` path; avoid reintroducing a `flutter` subprocess.

## Public surface

- Changing a public signature on a `WidgetTester` extension or `ApprovalWidgets` is an API break for a published package — preserve it or version the change deliberately.
