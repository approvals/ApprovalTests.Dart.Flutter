---
description: Review and approve received approval-test snapshots
argument-hint: "[index | path/to/.received.txt]"
---

Promote reviewed `*.received.txt` output to approved snapshots for this package.

## Pending received files

!`dart run approval_tests:review --list 2>/dev/null || echo "Run 'flutter test' first to generate received files."`

## Task

Argument: `$ARGUMENTS` (a `--list` index, a path to a `.received.txt` file, or empty).

1. If no received files are listed, run `flutter test` to generate them, then re-list.
2. For each received file under review, diff it against its `*.approved.txt` neighbor and explain what changed and why before approving.
3. Promote the intended file(s) with `dart run approval_tests:review <index>` (or the given path). This overwrites the `.approved.txt`.
4. Re-run `flutter test` and confirm the suite is green.
5. If the snapshot format itself changed (not just the test input), flag it as a breaking change and add a CHANGELOG.md entry.

Approve only output you have reviewed and understand — an approval is the reviewed contract, not a rubber stamp.
