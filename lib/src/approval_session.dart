import 'package:approval_tests_flutter/src/widget_meta/widget_meta.dart';
import 'package:approval_tests_flutter/src/widget_meta/widget_registry.dart';

/// Mutable capture state owned by one run of a test file.
///
/// Everything a capture accumulates lives here rather than in library
/// globals, so a group cannot observe — or corrupt — what another group
/// registered. Scope is the `setUpAll` → `tearDownAll` window.
final class ApprovalSession {
  /// Class names discovered by `ApprovalWidgets.setUpAll()`, or null before it
  /// has run.
  Set<String>? widgetNames;

  /// Types and names this session treats as registered.
  WidgetRegistry registry = WidgetRegistry.empty;

  /// Widget metas from the previous capture, used for delta output.
  List<WidgetMeta> previousWidgetMetas = [];

  /// Expect strings from the previous capture, used for delta output.
  List<String> previousExpectStrings = [];

  /// Localized text mapped back to the string ids that produce it.
  Map<String, List<String>> intlReverseLookup = {};

  /// Path the [intlReverseLookup] was loaded from.
  ///
  /// A path rather than a bool, so requesting a different file reloads instead
  /// of silently keeping the first one that happened to win.
  String? intlReverseLookupPath;

  /// The intl `S`-style holder set through `WidgetTesterExtension.s`.
  dynamic intlStrings;

  /// Adds [types] to this session's registry.
  void registerTypes(Set<Type> types) {
    registry = registry.copyWith(types: {...registry.types, ...types});
  }

  /// Adds [names] to this session's registry.
  void registerNames(Set<String> names) {
    registry = registry.copyWith(names: {...registry.names, ...names});
  }
}

/// Sentinel [ApprovalSession.intlReverseLookupPath] blocking loads from file.
///
/// Set by `addTextToIntlReverseLookup(markEnStringFileAsLoaded: true)`, whose
/// documented contract is that manual entries are not overwritten afterwards.
const String manualIntlReverseLookupPath = '<manual>';

ApprovalSession? _current;

/// The session the current test file is capturing into.
///
/// Created lazily rather than by `setUpAll`, so a consumer that calls
/// `registerTypes` or sets `WidgetTesterExtension.s` at the top of `main()`
/// keeps that state when setup later runs.
ApprovalSession get currentApprovalSession => _current ??= ApprovalSession();

/// Discards all capture state, restoring a first-run session.
void resetApprovalSession() => _current = null;
