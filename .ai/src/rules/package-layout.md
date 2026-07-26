# Package Layout Rules

`approval_tests_flutter` is a published library; its file structure and public surface are part of its contract.

## Structure

- Put implementation under `lib/src/`; widget-metadata internals live in `lib/src/widget_meta/`.
- Export the public API through the barrels `lib/approval_tests_flutter.dart` and `lib/src/src.dart` — add new public symbols there intentionally.
- Import sibling library files with `package:approval_tests_flutter/src/...`, not relative paths.
- Add behavior to `WidgetTester` as an `extension` (see `WidgetTesterApprovedExtension`); keep top-level configuration on `ApprovalWidgets`.

## Public API discipline

- Document every public member with `///` dartdoc — purpose, parameters, side effects, and any thrown recoverable exception.
- Prefer `const` constructors and trailing commas; the repo enables an extensive `dart_code_metrics` ruleset (`prefer-single-widget-per-file`, `no-empty-block`, `prefer-declaring-const-constructor`) in `analysis_options.yaml`.
- Run `dart format .` and `flutter analyze` before presenting a change.

## Style

- Comments earn their place — capture the *why* (the snapshot-sort rationale, the geometry omission), not the mechanism.
- Surface failures with native `throw` / `Exception` / `assert`; route diagnostic output through `ApprovalLogger.log`, never `print`.
