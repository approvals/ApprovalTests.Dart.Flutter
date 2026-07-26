# Safe-Change Rules

A few areas break consumers or CI silently. Flag the risk and verify before editing.

## Flag before changing

- **Snapshot output format** — any change to widget-meta, semantics, or expect-string formatting invalidates every committed `*.approved.txt`. Re-approve, add a CHANGELOG entry, and call it out as a breaking change.
- **`analyzer` version constraint** (`>=12.0.0 <14.0.0`) — coupled to the `analyzer` that `flutter_test`'s pinned `test` / `test_api` require. Widening it risks an unresolvable version conflict; verify against the current Flutter SDK first. Bump `cacheSchemaVersion` in `widget_name_cache.dart` in the same change: the analyzer version is not readable at runtime, so that constant is the only thing that invalidates a cache built by a different analyzer.
- **`cacheSchemaVersion`** in `widget_name_cache.dart` — also bump it when discovery changes which declarations count, or when the fingerprint payload changes. Forgetting to means a stale cache reads as valid and silently drops names from snapshots.
- **Analyzer AST usage** in `get_widget_names.dart` — widget-name extraction uses the analyzer-12 API (`ClassDeclaration.namePart.typeName.lexeme`). Confirm the AST shape before bumping `analyzer`.
- **Paths handed to `AnalysisContextCollection`** — it rejects anything not absolute *and* already normalized, so `includedPaths` and `sdkPath` must go through `p.normalize`. Building them by string concatenation throws `ArgumentError` on Windows, where the normalized form uses `\`.
- **Dart SDK resolution** in `resolveDartSdkPath()` — resolves from `FLUTTER_ROOT` because under `flutter test`, `Platform.resolvedExecutable` points at the `flutter_tester` engine, not the Dart binary. Keep the `FLUTTER_ROOT` path; avoid reintroducing a `flutter` subprocess.

## Public surface

- Changing a public signature on a `WidgetTester` extension or `ApprovalWidgets` is an API break for a published package — preserve it or version the change deliberately.
