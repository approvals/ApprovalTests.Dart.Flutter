---
paths:
  - "test/**"
  - "example/**"
---

# Testing Rules

Tests here double as living documentation of the package's own behavior.

## Widget approval tests

- Call `await ApprovalWidgets.setUpAll()` inside `setUpAll` before any snapshot helper — `widgetsString` asserts the widget-name cache is loaded.
- Pump and settle (`pumpWidget` → `pumpAndSettle`) before snapshotting so the tree is stable.
- Give each `approvalTest()` / `approvalSemantics()` / `approvalGolden()` a `description` when a test makes more than one snapshot; the description is appended to the approval file name.

## Conventions

- Name tests by the behavior verified — `test('returns a full self-contained snapshot on each call, not a delta')`, not by the method called.
- Keep `setUp` / `tearDown` scoped inside `group(...)`; clean up any temp directories or `.approval_tests/` cache they create.
- Keep tests deterministic — no real clocks, randomness, or sleeps; assert on stable substrings of the snapshot.
- Cover the package's own logic (key parsing, reverse lookup, `WidgetMeta` equality) with plain `test(...)`; reserve `testWidgets` for tree and semantics snapshots.
