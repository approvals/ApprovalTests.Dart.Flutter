# ApprovalTests.Dart.Flutter Roadmap

Last updated: 2026-07-15

Current baseline:

- latest published package:
  [`approval_tests_flutter 1.4.1`](https://pub.dev/packages/approval_tests_flutter);
- repository baseline: `refactor/approval-experience` at `1b68abd`;
- current core constraint: `approval_tests: ^1.3.6`, while the published core
  package is `1.4.3`;
- unreleased work: `WidgetActionPumpPolicy` adds explicit no-pump, single-frame,
  fixed-duration, and bounded-settling behavior to `tapWidget()` while keeping
  the 1.x default source compatible;
- `analyzer` is a runtime dependency because `ApprovalWidgets.setUpAll()`
  currently parses the consuming project's `lib/` sources at test runtime;
- compatibility policy: existing text snapshots and golden names remain stable
  throughout 1.x unless a documented correctness fix requires re-approval.

This roadmap describes the intended direction of `approval_tests_flutter`. It
is a priority guide, not a release schedule or a commitment to exact API names.
Public APIs and snapshot formats must be validated against real Flutter test
suites before they are finalized.

The package builds on
[`approval_tests`](https://github.com/approvals/ApprovalTests.Dart). Generic
artifact handling, scrubbers, reporters, CLI behavior, and approval naming
belong in the core Dart package. This roadmap covers Flutter-specific capture
and test-environment behavior.

## Vision

Make Flutter approval tests deterministic, accessible, and reviewable across
local development and CI for:

- widget-tree metadata;
- rendered semantics;
- golden images;
- multiple device and theme variants;
- user interactions and animations over time.

The package should remain a focused test utility. It should not become an app
framework, state-management layer, router, or localization solution.

## Guiding principles

1. **Snapshot output is a public contract.** Text or image changes require
   review, re-approval, and an explicit CHANGELOG entry.
2. **The environment is explicit.** Viewport, pixel ratio, locale, theme,
   text scaling, platform, and frame time must not depend on the developer's
   machine.
3. **No hidden settling.** Helpers do not call unbounded `pumpAndSettle()`
   implicitly; tests control when the UI is ready.
4. **Every snapshot is self-contained.** A second snapshot in one test must not
   depend on a previous capture.
5. **Geometry is opt-in.** Text and semantics snapshots omit volatile geometry
   unless a dedicated format can make it deterministic.
6. **Core behavior stays upstream.** Flutter uses core writers, scrubbers,
   reporters, and CLI functionality rather than forking them.
7. **Related captures form one result.** Widget metadata, semantics, and images
   from the same frame share one verification context and are reported
   together without being merged into one file.
8. **Capture state belongs to a session.** Concurrent or repeated tests must not
   communicate through mutable library globals.

## Priority model

- **P0 — Correctness and release alignment:** dependencies, hidden test
  behavior, leaked state, cache corruption, and misleading documentation.
- **P1 — Deterministic capture foundation:** explicit environments, context,
  and reusable capture contracts.
- **P2 — Product capability:** matrices, stories, animations, and richer
  semantics built on P1 and the core artifact pipeline.
- **Experimental:** device or render behavior that is not deterministic enough
  for a supported API yet.

## Current foundation

- [x] `tester.approvalTest()` for deterministic, sorted widget-tree metadata.
- [x] Full snapshots on every call rather than delta output.
- [x] `tester.approvalSemantics()` for geometry-free accessibility snapshots.
- [x] `tester.approvalGolden()` using Flutter's native golden matcher.
- [x] Descriptive names for multiple approvals in one test.
- [x] `findBy`, `expectWidget`, and `tapWidget` helpers.
- [x] Explicit `tapWidget()` pump policies with a backwards-compatible 1.x
      default.
- [x] Custom widget type registration and project class-name discovery.
- [x] Runtime AST scanning through `package:analyzer` without launching a
      nested Flutter process.
- [x] Regression coverage for widget-name loading, key parsing, metadata value
      equality, snapshot completeness, ordering, and semantics output.

## Milestone 0 — Safe 1.x maintenance

### Dependency and release alignment — P0

- [ ] Verify whether `approval_tests 1.3.6` actually supports every current
      Flutter API; `^1.3.6` already permits Pub to resolve `1.4.3`.
- [ ] Keep `1.3.6` as the minimum when tests prove compatibility; raise it only
      when Flutter starts consuming a newer core API.
- [ ] Test both the declared lower bound and the latest compatible core release
      before publishing.
- [ ] Record the exact minimum core version required by each Flutter feature.
- [ ] Keep Flutter and core CHANGELOG entries linked whenever a behavior spans
      both repositories.
- [ ] Merge and release from a branch whose history contains the published
      `1.4.1` source and tag.

### Explicit action settling — P0

`tapWidget()` currently calls `pumpAndSettle()` by default. Removing that
behavior immediately would be a breaking change, so migration must be additive.

- [x] Document the existing implicit settling behavior and its timeout risk.
- [x] Add an explicit action API where the caller chooses no pump, one pump, a
      fixed duration, or bounded settling.
- [x] Deprecate the implicit-settling convenience only after the explicit API
      is available.
- [x] Change or remove the implicit default only in a major release.
- [x] Never add hidden settling to approval capture methods.

### Capture-state isolation — P0

- [ ] Move registered widget names/types, previous metadata, previous generated
      expectations, and localization lookup state into an explicit test session.
- [ ] Ensure `approvalTest()` always captures a complete snapshot without
      mutating state used by another test.
- [ ] Provide deterministic setup and teardown that restores all library-owned
      state on success and failure.
- [ ] Cover repeated groups and concurrent zones with isolation regression
      tests even if Flutter currently schedules widget tests serially.

### Widget-name discovery and cache safety — P0

- [ ] Replace synchronous directory enumeration and cache writes inside async
      setup with consistently awaited filesystem operations.
- [ ] Sort discovered source files and class names before writing the cache.
- [ ] Write the cache atomically and handle an interrupted or malformed cache
      as a recoverable miss.
- [ ] Include the package root, analyzer-compatible SDK identity, and relevant
      source timestamps in cache validation.
- [ ] Document why `analyzer` cannot move to `dev_dependencies` while runtime
      discovery remains public behavior.
- [ ] Measure setup time before adding caching or isolate complexity.

Acceptance criteria for Milestone 0:

- the package resolves against its declared minimum core constraint;
- no helper introduces an undocumented pump or settle;
- test sessions cannot observe another session's registered types or previous
  snapshots;
- cache output is byte-identical for unchanged sources;
- `flutter analyze`, `flutter test`, and `dart pub publish --dry-run` pass.

## Milestone 1 — Explicit deterministic environments

### Immutable environment model

- [ ] Define an immutable Flutter approval environment model.
- [ ] Represent logical viewport size and device-pixel ratio explicitly.
- [ ] Represent locale, text scaling, brightness/theme variant, and target
      platform only where the package can apply them predictably.
- [ ] Provide documented presets for common phones, tablets, and desktop
      windows without pretending to emulate complete physical devices.
- [ ] Keep environment values independent of global mutable state.

The design should separate view configuration from app configuration. Viewport
and pixel ratio can be applied through `WidgetTester`; locale and theme usually
belong in the widget supplied by the test.

Acceptance criteria:

- applying an environment produces the same constraints on supported hosts;
- every changed test view property is restored after the test;
- parallel tests do not share mutable environment state;
- presets are immutable values with value equality;
- existing snapshot helpers remain source compatible.

### Deterministic pump harness

- [ ] Provide an optional helper for applying and restoring view configuration.
- [ ] Let callers supply the widget tree, localization delegates, and theme
      rather than hiding them inside package globals.
- [ ] Require explicit `pump`, fixed-duration pumps, or caller-controlled
      settling before capture.
- [ ] Document how to stub network images and animations.
- [ ] Surface timeout and unfinished-animation failures clearly.

Non-goal: an automatic `pumpWidget()` wrapper that guesses application setup or
waits forever for an indeterminate animation.

### Stability recipes

- [ ] Document a canonical single-device widget approval setup.
- [ ] Document deterministic locale, theme, text-scaling, and platform tests.
- [ ] Document fonts and golden-test requirements for local machines and CI.
- [ ] Explain when to choose widget metadata, semantics, a golden image, or a
      combination of them.
- [ ] Adopt the core explicit approval context when available so Flutter
      captures do not require stack-trace parsing for source paths and test names.
- [ ] Keep current artifact names stable while the explicit-context API is
      introduced.

## Milestone 2 — Golden and snapshot matrices

### Variant model

- [ ] Define a small variant model for viewport, pixel ratio, locale, theme,
      text scaling, and target platform.
- [ ] Generate deterministic, filesystem-safe names for each variant.
- [ ] Reject duplicate names before running captures.
- [ ] Preserve declaration order in reporting while keeping artifact naming
      independent of iteration accidents.

### Golden matrix

- [ ] Add an approval helper for rendering the same widget across explicit
      variants.
- [ ] Pump a fresh widget tree for each variant to prevent state leakage.
- [ ] Restore the test view after every variant, including failure paths.
- [ ] Aggregate mismatches so one run reports every failed variant.
- [ ] Support filtering variants for local development and CI shards.
- [ ] Integrate with core artifact/reporting APIs when image-aware reporter
      selection becomes available.
- [ ] Reuse Flutter's `GoldenFileComparator` contract for pixel comparison;
      do not ship a second image-diff engine in this package.
- [ ] Allow an explicitly supplied comparator or tolerance policy without
      leaking it into later tests through the global binding.
- [ ] Record the comparator identity and tolerance in diagnostics so a changed
      threshold cannot silently explain a passing golden.

Example use case:

```text
home.phone.light.en.png
home.phone.dark.en.png
home.tablet.light.en.png
home.phone.light.ar.png
```

Acceptance criteria:

- variant names and output paths are stable across platforms;
- locale, theme, and viewport changes cannot leak into later tests;
- failed variants are reported together;
- tests cover duplicate names, setup failure, capture failure, and cleanup;
- matrix size is visible before execution.

### Pairwise variant coverage

- [ ] Reuse the core pairwise-combination engine when full Flutter matrices are
      too large.
- [ ] Make pairwise selection explicit; never silently replace a requested full
      matrix.
- [ ] Include selected and total scenario counts in diagnostics.

## Milestone 3 — Interaction and time-based approvals

### Interaction stories

- [ ] Add a Flutter storyboard API built on the core storyboard model.
- [ ] Capture named widget-tree and/or semantics frames around caller-defined
      actions.
- [ ] Let tests perform taps, text entry, drags, navigation, and pumps
      explicitly.
- [ ] Keep every frame complete and independently reviewable.
- [ ] Support descriptions that produce deterministic artifact names.

Example flow:

```text
Initial
After entering email
After validation failure
After successful submission
```

### Animation approvals

- [ ] Capture frames at explicit `Duration` offsets.
- [ ] Support individual golden frames first; consider contact sheets only when
      the core artifact pipeline supports them cleanly.
- [ ] Never use wall-clock time or sleeps.
- [ ] Verify exact frame ordering and frame-to-file naming.
- [ ] Restore ticker and view state after success or failure.

Acceptance criteria:

- animation tests use fixed simulated time;
- frame counts and timestamps are explicit in the approved artifact;
- repeated runs produce byte-identical images under the supported golden
  environment;
- infinite animations do not cause hidden settling or timeouts.

### Mixed artifact stories

- [ ] Build one scenario result that produces widget metadata, semantics, and
      golden artifacts through the core multi-artifact bundle.
- [ ] Implement Flutter capture as a core converter or equivalent explicit
      adapter, not as a second comparison and reporting pipeline.
- [ ] Use a shared verification context and stable frame name for all artifacts
      from the same capture.
- [ ] Report all mismatches without losing which capture mode failed.
- [ ] Keep each artifact separately reviewable rather than embedding binary data
      into text snapshots.
- [ ] Clean up temporary image and capture resources even when conversion,
      comparison, or reporting fails.

Acceptance criteria:

- one capture can report any combination of `.txt`, semantics text,
  and `.png` artifacts;
- missing, changed, and unexpected artifacts are reported together;
- disabling one capture mode has explicit stale-artifact behavior;
- the Flutter package reuses core naming, async execution, typed failures, and
  reporter selection.

## Milestone 4 — Semantics depth and Flutter-specific normalization

### Richer semantics snapshots

- [ ] Add stable roles/flags when the minimum supported Flutter SDK exposes a
      non-deprecated API for them.
- [ ] Consider focusability, enabled/disabled state, checked/toggled state,
      heading level, selected state, and live-region behavior.
- [ ] Keep geometry, transforms, and scroll offsets excluded by default.
- [ ] Version or explicitly migrate semantics output when new fields are added.
- [ ] Add examples for controls, forms, validation errors, and navigation.

Acceptance criteria:

- fields are emitted in a stable documented order;
- platform-dependent semantics are either normalized or clearly scoped;
- adding a field is treated as an intentional snapshot contract change;
- accessibility examples run on supported CI platforms.

### Flutter-specific volatile values

- [ ] Catalog actual volatile widget and semantics values before adding
      scrubbers.
- [ ] Add narrowly scoped, opt-in scrubbers for generated runtime identifiers
      only when they cannot be omitted at the capture source.
- [ ] Reuse core aliasing so repeated identifiers preserve relationships.
- [ ] Do not scrub widget text, keys, counts, or geometry broadly.

### Widget metadata evolution

- [ ] Document the stable metadata schema and ordering rules.
- [ ] Evaluate whether type, key, text, state, and selected public properties
      provide enough diagnostic value without exposing private implementation
      details.
- [ ] Add schema changes only with regression fixtures and migration notes.
- [ ] Benchmark collection on large widget trees before optimizing it.

## Milestone 5 — Developer experience, CI, and package maturity

### Task-oriented examples

- [ ] Add recipes for forms, localized screens, responsive layouts, dialogs,
      lists, navigation, and accessibility.
- [ ] Add a complete golden-matrix example application.
- [ ] Add an interaction-story example showing text and semantics captures.
- [ ] Add a decision table explaining which snapshot mode to use.
- [ ] Document how core scrubbers and reporters apply to Flutter text artifacts.

### CI workflows

- [ ] Provide supported GitHub Actions examples for text approvals and goldens.
- [ ] Upload received text and image artifacts on failure.
- [ ] Reuse the core typed mismatch model and machine-readable manifest.
- [ ] Document how stale-approval checks work with Flutter test filtering,
      shards, golden variants, and multi-artifact frames.
- [ ] Document font installation and rendering constraints.
- [ ] Keep approval explicit; CI does not update goldens automatically.

### Performance and compatibility

- [ ] Add benchmarks for startup, AST widget-name discovery, large widget
      trees, semantics trees, golden matrices, and animation frames.
- [ ] Measure before changing caching or traversal behavior.
- [ ] Test supported Flutter versions against the pinned analyzer range.
- [ ] Add compatibility checks before raising the minimum Flutter or analyzer
      version.
- [ ] Keep package startup free of nested `flutter` subprocesses.

### Release coordination

- [ ] Document which Flutter features require a minimum core
      `approval_tests` version.
- [ ] Update the minimum core constraint only when the Flutter package uses a
      newer API.
- [ ] Coordinate CHANGELOG entries for cross-package behavior changes.
- [ ] Publish migration notes for snapshot format or naming changes.

## Experimental backlog

### Optional source discovery

- [ ] Measure how many real approval snapshots need project-wide AST discovery
      rather than runtime widget types, keys, text, or explicit `registerTypes()`.
- [ ] Prototype an opt-in CLI or companion dev tool that generates the widget
      name cache before tests.
- [ ] Compare that workflow with keeping `analyzer` in runtime dependencies,
      including setup time, version conflicts, discoverability, and CI ergonomics.
- [ ] Remove the mandatory runtime analyzer only if the replacement preserves
      existing snapshot coverage and has a clear migration path.
- [ ] Do not move `analyzer` mechanically to `dev_dependencies`; consuming
      applications cannot use this package's dev dependencies at runtime.

### Render summaries

- [ ] Prototype a stable render summary only if it provides information that
      widget metadata and goldens do not.
- [ ] Avoid raw render-object dumps, hashes, memory addresses, and geometry.
- [ ] Validate usefulness on real layout regressions before exposing an API.

### Focus traversal approvals

- [ ] Explore deterministic keyboard/focus traversal stories.
- [ ] Capture focused semantics identity after explicit traversal actions.
- [ ] Separate platform-specific expectations where behavior intentionally
      differs.

### Integration-test capture

- [ ] Evaluate snapshot capture under `integration_test` on physical devices and
      emulators.
- [ ] Define how artifacts are transported back to the host and CI.
- [ ] Keep device-specific output separate from deterministic widget-test
      approvals.

## Explicit non-goals

- Moving `package:analyzer` to `dev_dependencies` while runtime AST discovery
  depends on it.
- Hidden or unbounded `pumpAndSettle()` calls.
- Automatic approval or golden updates in normal CI runs.
- A global mutable locale, theme, viewport, or device singleton.
- Raw geometry-heavy semantics output by default.
- Reimplementing core scrubbers, writers, reporters, naming, or CLI behavior.
- Pretending presets fully emulate branded physical devices.
- App architecture, routing, state management, networking, or localization
  frameworks.

## Ordered delivery slices

Every slice must be independently reviewable and green. Flutter work that
depends on an unreleased core API starts only after that core slice is released
or consumed through an explicitly documented temporary path dependency.

| Order | Deliverable                                        | Primary files                                                                                                              | Focused verification                                             |
| ----- | -------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| 1     | Lower-bound/latest core compatibility matrix       | `pubspec.yaml`, CI workflows, `CHANGELOG.md`                                                                               | `flutter pub get`, `flutter analyze`, `flutter test`             |
| 2     | Explicit tap/pump actions                          | `lib/src/widget_meta/widget_tester_extension.dart`, action tests                                                           | `flutter test test/approval_tests_flutter_regressions_test.dart` |
| 3     | Isolated capture session                           | `lib/src/approval_session.dart`, `lib/src/src.dart`, `lib/src/widget_meta/collect_widgets_meta_data.dart`, isolation tests | focused regression test, then full suite                         |
| 4     | Awaited and atomic widget-name cache               | `lib/src/get_widget_names.dart`, cache tests                                                                               | `flutter test test/approval_tests_flutter_regressions_test.dart` |
| 5     | Immutable approval environment and restore harness | `lib/src/environment/`, environment tests                                                                                  | `flutter test test/environment_test.dart`                        |
| 6     | Core `ApprovalContext` adoption                    | `lib/src/src.dart`, naming tests                                                                                           | `flutter test test/approval_context_test.dart`                   |
| 7     | Golden variant model and comparator restoration    | `lib/src/goldens/`, golden matrix tests                                                                                    | `flutter test test/golden_matrix_test.dart`                      |
| 8     | Interaction and animation stories                  | `lib/src/stories/`, story tests                                                                                            | `flutter test test/approval_story_test.dart`                     |
| 9     | Widget/semantics/golden artifact bundle            | `lib/src/capture/`, multi-artifact tests                                                                                   | `flutter test test/multi_artifact_capture_test.dart`             |
| 10    | Rich semantics and CI recipes                      | `lib/src/widget_meta/semantics_snapshot.dart`, examples, workflow docs                                                     | semantics tests, example tests, full suite                       |

After every slice run:

```shell
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

Before release also run:

```shell
dart pub publish --dry-run
```

Expected result: all commands exit `0`, snapshots are byte-identical across
two consecutive supported-host runs, and every changed snapshot format has a
CHANGELOG entry plus migration note.

## Prior-art adoption matrix

| Prior-art capability                             | Flutter decision                                                                   | Roadmap location                   |
| ------------------------------------------------ | ---------------------------------------------------------------------------------- | ---------------------------------- |
| Verify: several outputs from one test            | Adopt widget metadata, semantics, and PNG as one core artifact bundle              | Milestone 3                        |
| Verify: converter extensions                     | Adopt an explicit Flutter capture adapter over the core converter contract         | Milestone 3                        |
| Verify: async and cleanup                        | Reuse the awaited core engine and always restore binding/session state             | Milestones 0–3                     |
| Verify: no stack-trace naming                    | Consume core `ApprovalContext` with a 1.x compatibility fallback                   | Milestone 1                        |
| Verify: machine-readable failures                | Reuse typed core mismatches and run manifests                                      | Milestone 5                        |
| Verify: dangling-file checks                     | Reuse core checks with variant, shard, and filtered-run safeguards                 | Milestone 5                        |
| ApprovalTests.Swift: UI approvals                | Adopt explicit text, semantics, and golden captures rather than one ambiguous dump | Current foundation and Milestone 3 |
| ApprovalTests.Java: storyboards and combinations | Adopt interaction stories and core pairwise variant selection                      | Milestones 2–3                     |
| ApprovalTests.Python: file/CI workflows          | Reuse core artifacts, reporters, manifests, and explicit approval                  | Milestones 3 and 5                 |
| Flutter native goldens                           | Keep `matchesGoldenFile`/`GoldenFileComparator` as the pixel-comparison seam       | Milestone 2                        |

## Quality and release gates

Every roadmap item must meet the following gates before release:

- [ ] Public APIs have dartdoc and complete widget-test examples.
- [ ] Tests cover setup, capture, cleanup, and failure paths.
- [ ] New deterministic capture and configuration logic maintains at least 80%
      line coverage, including restoration failures.
- [ ] Snapshot output is deterministic and intentionally reviewed.
- [ ] Any output change includes updated approved fixtures and a CHANGELOG note.
- [ ] `dart format .` produces no changes.
- [ ] `flutter analyze` reports no issues.
- [ ] `flutter test` passes on supported Flutter versions.
- [ ] `dart pub publish --dry-run` succeeds before a release.
- [ ] View, semantics, ticker, and global binding state is restored after tests.
- [ ] Performance claims are backed by benchmarks.
- [ ] Snapshots and diagnostics do not expose secrets, credentials, or PII by
      default.

## Dependencies on the core roadmap

The following Flutter milestones should reuse core work:

| Flutter capability               | Core prerequisite                            |
| -------------------------------- | -------------------------------------------- |
| Image-aware reporter selection   | Artifact-aware reporters                     |
| Mixed text and image stories     | Async multi-artifact and converter pipeline  |
| Pairwise golden matrices         | Best-covering-pairs engine                   |
| Interaction stories              | Core storyboard model                        |
| Explicit test naming             | Core `ApprovalContext` and test adapter      |
| CI mismatch collection           | Typed failures and machine-readable manifest |
| Stale golden detection           | Core stale-approval checks                   |
| Runtime identifier normalization | Alias-preserving scrubbers                   |
| Scoped Flutter defaults          | Async-safe scoped `Options` foundation       |

## Prior art

This roadmap adapts ideas from mature approval-testing libraries while keeping
Flutter's test binding and rendering model explicit:

- [ApprovalTests.Swift](https://github.com/approvals/ApprovalTests.Swift) — UI
  writers, file-type-aware reporters, sequences, and verifiable objects.
- [ApprovalTests.Java](https://github.com/approvals/ApprovalTests.Java) — image
  approvals, storyboards, pairwise combinations, and multi-artifact workflows.
- [ApprovalTests.Python](https://github.com/approvals/ApprovalTests.Python) —
  storyboards, file artifacts, reporter composition, and CI workflows.
- [Verify](https://github.com/VerifyTests/Verify) — one verification producing
  multiple related artifacts, converter-based extensions, awaited I/O, and
  machine-readable integration output.
- [Flutter golden testing](https://api.flutter.dev/flutter/flutter_test/matchesGoldenFile.html)
  — the native comparison mechanism used by `approvalGolden()`.
