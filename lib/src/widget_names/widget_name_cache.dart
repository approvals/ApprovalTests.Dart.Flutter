import 'dart:io';

import 'package:approval_tests/approval_tests.dart';
import 'package:approval_tests_flutter/src/widget_names/source_fingerprint.dart';
import 'package:path/path.dart' as p;

/// Cache format revision.
///
/// Bump this whenever discovery changes which declarations count, whenever the
/// fingerprint payload changes, and whenever the `analyzer` constraint in
/// `pubspec.yaml` moves — the analyzer version is not readable at runtime, so
/// this constant stands in for it.
const int cacheSchemaVersion = 2;

const String _versionTokenPrefix = '# approval-tests-flutter-cache:';

/// Filesystem locations a widget-name scan reads and writes.
///
/// Every path is resolved and normalized against [packageRoot] rather than the
/// process working directory. `AnalysisContextCollection` rejects a path that
/// is not absolute and already normalized, so `'$root/lib'` built by string
/// concatenation throws on Windows, where the normalized form uses `\`.
final class WidgetNameCacheLocation {
  WidgetNameCacheLocation({
    required String packageRoot,
    String? cacheDirectory,
  })  : packageRoot = p.normalize(p.absolute(packageRoot)),
        libPath = p.normalize(p.absolute(p.join(packageRoot, 'lib'))),
        cacheDirectory = p.normalize(
          p.absolute(
            cacheDirectory ?? p.join(packageRoot, 'test', '.approval_tests'),
          ),
        );

  /// Resolves against [Directory.current], matching how `flutter test` runs.
  factory WidgetNameCacheLocation.forCurrentDirectory() =>
      WidgetNameCacheLocation(packageRoot: Directory.current.absolute.path);

  final String packageRoot;
  final String libPath;
  final String cacheDirectory;

  String get cacheFilePath => p.join(cacheDirectory, 'class_names.txt');

  File get cacheFile => File(cacheFilePath);
}

/// Serializes [names] into the v2 cache format for [fingerprint].
///
/// The first two lines are the shared `ApprovalTestsConstants.widgetHeader`,
/// which carries no trailing newline of its own. The third line is the version
/// and digest token; a reader from before this format simply drops it along
/// with every other `#` line, so downgrading keeps working.
///
/// Only the digest is persisted, never the package root or SDK path: the cache
/// lives under `test/` and must not carry a developer's home directory.
String encodeWidgetNameCache({
  required SourceFingerprint fingerprint,
  required Set<String> names,
}) {
  final sorted = names.toList()..sort();
  return [
    ApprovalTestsConstants.widgetHeader,
    '$_versionTokenPrefix v$cacheSchemaVersion fnv1a64=${fingerprint.digest}',
    ...sorted,
    '',
  ].join('\n');
}

/// Reads [contents] as a v2 cache, or returns null when it cannot be trusted.
///
/// Every problem — absent token, unknown revision, malformed line, digest
/// mismatch, truncation — is a recoverable miss. A cache must never fail a
/// consumer's test run.
Set<String>? decodeWidgetNameCache({
  required String contents,
  required SourceFingerprint fingerprint,
}) {
  final lines = contents.split('\n');
  final versionLine = lines.firstWhere(
    (line) => line.startsWith(_versionTokenPrefix),
    orElse: () => '',
  );
  if (versionLine.isEmpty) {
    return null;
  }

  final tokens = versionLine.substring(_versionTokenPrefix.length).split(' ')
    ..removeWhere((token) => token.isEmpty);
  if (tokens.length != 2 ||
      tokens.first != 'v$cacheSchemaVersion' ||
      tokens.last != 'fnv1a64=${fingerprint.digest}') {
    return null;
  }

  return lines
      .where((line) => line.isNotEmpty && !line.startsWith('#'))
      .toSet();
}
