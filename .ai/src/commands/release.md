---
description: Prepare a pub.dev release — version bump, CHANGELOG, and pre-publish checks
argument-hint: "<new-version>"
---

Prepare `approval_tests_flutter` for a pub.dev release at version `$ARGUMENTS`.

## Current state

!`grep -E '^version:' pubspec.yaml`
!`git log --oneline -5`

## Task

1. Set `version:` in `pubspec.yaml` to `$ARGUMENTS`, and update the version referenced in `README.md`.
2. Add a `## $ARGUMENTS` section at the top of `CHANGELOG.md` summarizing changes since the last tag — group user-facing behavior changes, new APIs, and fixes; mark any snapshot-format or public-API change as **breaking**.
3. Run the gates: `dart format .`, `flutter analyze`, `flutter test`.
4. Run `flutter pub publish --dry-run` and resolve any warnings (missing dartdoc, platform metadata, example).
5. Summarize the diff and the dry-run result. Do not publish or push tags — leave `flutter pub publish` and tagging to the maintainer.
