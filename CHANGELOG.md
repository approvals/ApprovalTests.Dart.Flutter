## 1.5.1

### Documentation

- Reworked the package guide with a first Flutter approval test, guidance for
  choosing approval snapshots versus focused assertions, and a CI policy for
  reviewing and committing baselines safely.
- Expanded the executable example with a feature-first orders slice covering
  dependency-injected state management, typed failures, loading/loaded/error
  approvals, focused retry and empty-state assertions, and repository lifecycle
  changes.

## 1.5.0

### Fixed

- Widget-name cache writes are now atomic. `flutter test` runs test files in
  parallel processes that share one cache file, so the previous single write
  was observable by another process as a truncated file — a short read drops
  names, which silently drops lines from a snapshot.
- Widget-name discovery no longer throws `ArgumentError` on Windows.
  `AnalysisContextCollection` rejects a path that is not absolute *and*
  normalized; the `lib` and Dart SDK paths were built by string concatenation.
- Cache freshness is validated by fingerprint instead of newest modification
  time. The old check missed a deleted non-newest file, a checkout with
  backdated timestamps, and a timestamp-preserving rename, and it treated a
  write racing an edit as fresh. Any cache problem is now a rescan, never an
  error.
- The cache is byte-stable: discovered sources and class names are sorted.
- The analysis context is disposed, so its driver no longer outlives `setUpAll`.
- Blocking `listSync` / `createSync` / `writeAsStringSync` calls inside the
  async setup path are now awaited.
- `printExpects(widgetTypes: ...)` no longer ignores its argument after the
  first call. A one-shot latch meant only the first set was ever registered.
- The intl reverse lookup reloads when `pathToStrings` changes. Its "already
  loaded" flag was checked but never set, so the file was re-read on every
  call, and a different path could never win.

### Changed

- Capture state — registered types and names, previous-capture memory, the
  localization lookup, and the intl string holder — moved out of library
  globals into an explicit session.
- Added `ApprovalWidgets.tearDownAll()`, which discards that session. It is
  **optional**: omitting it reproduces the previous behaviour exactly. Add it
  when one test file has groups with different registrations, since a
  `registerTypes` call otherwise stays in effect for every later group in the
  file and changes their snapshots.
- `registerTypes` keeps its signature but now writes into the current session.
- `printExpects(widgetNames: ...)` adds to the session's registered names
  instead of replacing them, so a narrower set no longer hides names discovered
  by `setUpAll`. This affects console output only, never an approved file.
- Added `path` as a direct dependency; it was already resolved transitively.

### Removed

- `loadWidgetNames()` and the `StringApprovedExtension.endWithNewline` helper
  in `src/common.dart`, both unused after the discovery rewrite. Neither was
  exported from the package's public API.

Snapshot output is unchanged. No `*.approved.txt` needs re-approving.

### Internal

- Expanded deterministic coverage for widget metadata and expect generation,
  finder and pump policies, semantics and golden approvals, widget-name cache
  failures, and bounded Windows rename retries.
- Reached 100% executable line coverage (594/594 lines); all 100 test
  executions pass.

## 1.4.1

- Added `WidgetActionPumpPolicy` so `tapWidget()` callers can explicitly choose no pump, one pump, a fixed-duration pump, or bounded settling.
- Deprecated `tapWidget(shouldPumpAndSettle: ...)`. Existing calls still settle by default throughout 1.x; migrate to the explicit `pumpPolicy` parameter.
- Approval capture helpers remain caller-controlled and never pump or settle implicitly.

## 1.4.0

- **Fix (behavior change):** `approvalTest()` now writes a full, self-contained snapshot of the widget tree on every call. Previously a second call in the same test emitted only the _delta_ from the prior call, producing snapshots that could not be reviewed in isolation. Existing approved files that relied on the old delta output must be re-approved.
- Snapshot lines are now sorted deterministically, so approvals no longer flake on widget tree-traversal order.
- Added `tester.approvalSemantics()` — approval testing of the rendered accessibility (semantics) tree (labels, values, hints, tooltips, identifiers, actions); geometry is omitted so output is stable across platforms.
- Added `tester.approvalGolden(finder)` — golden/pixel approvals named to sit alongside the text approvals; run `flutter test --update-goldens` to (re)create the image.
- Exported the `expectWidget` / `tapWidget` / `findBy` finder helpers and `registerTypes`, and exposed `widgetTypes` / `widgetNames` on `tester.printExpects()`.
- Removed the cold-start `flutter --version` subprocess; the Dart SDK is now resolved from `FLUTTER_ROOT`, making widget-name extraction faster and not dependent on `flutter` being on `PATH`.
- Removed the unused `match` dependency.
- Internal cleanup: replaced the `Completer`/`.then` wrappers with `async`/`await` (failures now propagate instead of hanging to timeout), guarded the analyzer parse-result cast, fixed the stale `Approved.initialize()` setup hint, and stopped tracking the generated `.approval_tests/` cache.

## 1.3.2

- Raised the `analyzer` constraint to `>=12.0.0 <14.0.0` to resolve a version conflict with `flutter_test` on current Flutter/Dart SDKs, whose pinned `test`/`test_api` require analyzer 12+.
- Migrated widget-name extraction to the analyzer 12 AST API (`ClassDeclaration.namePart.typeName`), replacing the removed `name` token getter.
- Note: this drops support for analyzer 8–11 (older Flutter SDKs).

## 1.3.1

- Fixed `loadWidgetNames` to return an empty string when the widget cache file is missing, avoiding `LateInitializationError`.
- Restored intl reverse-lookup loading by re-enabling JSON parsing in `loadEnStringReverseLookup`.
- Updated `WidgetMeta.hashCode` to match its equality semantics, ensuring set/map deduplication works as intended.
- Added regression tests covering widget name loading, intl reverse lookup, and `WidgetMeta` equality.
- Declared an upper bound on the supported Dart SDK (`<4.0.0`) to satisfy pub publishing requirements.
- Added explicit platform support metadata (Android, iOS, Linux, macOS, Windows) so pub scoring can detect supported platforms.
- Replaced the bundled license text with the standard Apache 2.0 wording recognized by pub.dev.
- Added a minimal `example/main.dart` showcasing a widget approval test.
- Updated dependency constraints (for example `approval_tests` now targets 1.3.3) to stay aligned with upstream packages.
- `ContextLocator` replaced by `AnalysisContextCollection`

## 1.1.6

- Upgraded all dependencies to actuals.

## 1.1.3

- Updated README.md file: fix links.

## 1.1.2

- Added CLI additional options:  
   Usage: `dart run approval_tests:review [arguments]`
  - Arguments:
    - `--help` Print this usage information.
    - `--list` Print a list of project .received.txt files.
    - `<index>` Review an .received.txt file indexed by --list.
    - `<path/to/.received.txt>` Review an .received.txt file.

## 1.1.1

- Updated README.md file.

## 1.1.0

- **Breaking release**:
  - Added new reporter: `GitReporter`. It allows you to use `git` to view the differences between the received and approved files.
  - Added support to approve files using CLI. Now you can approve files using the command line: `dart run approval_tests:review`
  - Added support to use ApprovalTests during widget tests.
  - Added header to generated files. For resolved issues you can add this to approved files:  
    '# This file was generated by approval_tests. Please do not edit.\n'
  - Some minor changes and code improvements.
    Thanks to [Richard Coutts](https://github.com/buttonsrtoys)

## 1.0.0

- Initial major release.

## 0.5.1

- Updated documentation.
- Updated dependencies.
- Updated `README.md` file.
- Updated `TODO.md` file.
- Rewrited comparators. Now it is only FileComparator.
- Rewrited Scrubbers: regex scrubber, date scrubber.
- Now, first run automatically create approved snapshot. You can approve another snapshot by setting `approveResult` to `true` and using Diff Tool.
- Completely rewritten `CommandLineReporter`.
  There were changes with the comparison method, as well as highlighting by color the places where there are differences. Green - approved. White text on red background - Differences in received file.
- Internal updates such as:
  - Adding android studio installation via github actions to test Diff Reporter on different devices.
  - Full code test coverage after significant changes.
  - Changes to getting file name and path depending on platform.

## 0.4.6

- Updated dependencies. Removed `dcli` package.
- Issue https://github.com/approvals/ApprovalTests.Dart/issues/3 was fixed.
- Minor changes: `IDEComparator` now gets the current `StackTrace` if an error occurs.

## 0.4.5

- Updated dependencies and actions versions.
- Updated Logger's output: now it is more informative.
- Updated `CONTRIBUTING.md` file: added Arlo's Commit Notation.

## 0.4.4

- Added setup visual studio code action to the `build_and_test` workflow for test `IDEComparator`.

## 0.4.3

- Completed coverage of the project with tests. Now the project has 100% coverage.

## 0.4.2

- Autopublish to `pub.dev` if the version in `pubspec.yaml` has been changed by auto adding a new tag to the repositories.
- Codecov added to `github` actions. Codecov badge, graph was added to `README.md`.
- Added `mdsnippets` to `github` actions. And example snippets added to `README.md`.
- Added `ApprovalTests.Dart.StarterProject`. You can find it in the `README.md` file.

## 0.3.9

- Fix with default file path if package from `pub.dev`.
- Gilded rose moved to starter project.
- Code formatted.

## 0.3.8

- Test publish action with new version: `v0.3.8`.

## 0.3.6-dev

- Updated `pubspec.yaml` file: changed homepage.

## 0.3.5-dev

- The repository has been moved to Approvals.
- Fixed bug with checking of strings received from `txt` file.
- Added `Github` Actions.
- Added `dependabot`.
- Updated `README.md` file.
- Updated `TODO.md` file.

## 0.3.3-dev

- Updated `README.md` file.

## 0.3.2-dev

- Default `lints` replaced by `sizzle_lints`.
- Updated `analysis_options` file.
- Updated `README.md` file.

## 0.3.1-dev

- Updated `README.md` file.

## 0.3.0-dev

- Approval was refactored.
- Added tests.
- Code formatted.
- `deleteReceivedFile` field was added to the `ApprovalTests` class. If it is set to `true`, the received file will be deleted after test. By default, it is set to `false`.
- `logErrors` field was added to the `ApprovalTests` class. If it is set to `true`, the errors will be logged. By default, it is set to `true`.
- `logResults` field was added to the `ApprovalTests` class. If it is set to `true`, the success results will be logged. By default, it is set to `true`.

## 0.2.1-dev

- Fix: `approval_dart` changed to `approval_tests`.
- Code formatted.

## 0.2.0-dev

- I rewrote the main functions of the class. Now you can use several comparison options.
- Added methods for comparing `JSON` strings.
- Added methods for array comparison.
- Improved documentation.
- Added more examples: each method has its own small example.

## 0.1.0-dev

- Added `verifyAll` method to verify array of items _(or use array as inputs)_.
- Added `verifyAllCombinationsAsJson` method to verify all combinations of items as `JSON`.
- Updated `README.md` file.

## 0.0.9-dev

- Updated `README.md` file.

## 0.0.8-dev

- Updated `README.md` file: added examples, more info.

## 0.0.7-dev

- Comparator completed, some refactoring. Updated `README.md` file.

## 0.0.6-dev

- Some updates with `README.md` file.

## 0.0.5-dev

- First working version, need to expand functionality and add more flexibilty. Also need to add more tests.

## 0.0.1-dev

- Initial version.
