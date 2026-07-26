import 'dart:collection';
import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:approval_tests/approval_tests.dart';
import 'package:approval_tests_flutter/src/io/atomic_file.dart';
import 'package:approval_tests_flutter/src/widget_names/source_fingerprint.dart';
import 'package:approval_tests_flutter/src/widget_names/widget_name_cache.dart';
import 'package:path/path.dart' as p;

/// Widget names discovered for a project, and where they came from.
final class WidgetNameLoadResult {
  const WidgetNameLoadResult({required this.names, required this.fromCache});

  /// Public class names found under `lib/`, in ascending order.
  final Set<String> names;

  /// Whether a valid cache answered, so no analyzer run was needed.
  final bool fromCache;
}

/// Discovers the public class names a project's `lib/` declares.
///
/// Results are cached under `test/.approval_tests/` and validated by
/// fingerprint rather than by modification time, so a cache restored from
/// another checkout or written mid-edit is a miss instead of silently stale
/// input. Stale input would drop lines from a snapshot.
final class WidgetNameScanner {
  WidgetNameScanner({
    required this.location,
    String? sdkPath,
    String? sdkIdentity,
    this.replaceFile = replaceFileWithRetry,
    this.readCacheContents = _readFileAsString,
  })  : sdkPath = p.normalize(sdkPath ?? resolveDartSdkPath()),
        sdkIdentity = sdkIdentity ?? Platform.version;

  final WidgetNameCacheLocation location;
  final String sdkPath;
  final String sdkIdentity;
  final Future<void> Function(File from, File to) replaceFile;
  final Future<String> Function(File file) readCacheContents;

  /// Returns the project's widget names, using the cache when it is valid.
  Future<WidgetNameLoadResult> load() async {
    final fingerprint = await fingerprintSources();

    final cached = await readCache(fingerprint);
    if (cached != null) {
      return WidgetNameLoadResult(names: cached, fromCache: true);
    }

    ApprovalLogger.log(
      'package:approval_tests_flutter: searching for class names in '
      '${location.libPath}...',
    );
    final names = await scan(fingerprint);
    await writeCache(fingerprint, names);

    return WidgetNameLoadResult(names: names, fromCache: false);
  }

  /// Walks `lib/` once, collecting the sources and the identity to validate on.
  Future<SourceFingerprint> fingerprintSources() async => SourceFingerprint(
        sources: await collectDartSources(location.libPath),
        schemaVersion: cacheSchemaVersion,
        packageRoot: location.packageRoot,
        sdkPath: sdkPath,
        sdkIdentity: sdkIdentity,
      );

  /// Parses every source in [fingerprint] and collects public class names.
  Future<Set<String>> scan(SourceFingerprint fingerprint) async {
    if (fingerprint.sources.isEmpty) {
      return SplayTreeSet<String>();
    }

    final collection = AnalysisContextCollection(
      includedPaths: [location.libPath],
      sdkPath: sdkPath,
    );
    try {
      final session = collection.contexts.first.currentSession;
      final classNames = SplayTreeSet<String>();

      for (final source in fingerprint.sources) {
        final absolutePath = p.normalize(
          p.join(location.libPath, p.joinAll(p.url.split(source.relativePath))),
        );
        final parsed = session.getParsedUnit(absolutePath);
        // Skip files the analyzer cannot parse (e.g., syntax errors in user code).
        if (parsed is! ParsedUnitResult) {
          continue;
        }

        for (final member in parsed.unit.declarations) {
          if (member is ClassDeclaration) {
            final name = member.namePart.typeName.lexeme;
            if (!name.startsWith('_')) {
              classNames.add(name);
            }
          }
        }
      }

      return classNames;
    } finally {
      // The constructor starts an analysis scheduler; without this the driver
      // outlives setUpAll and stays alive for the whole test process.
      await collection.dispose();
    }
  }

  /// Reads the cache, or returns null when it is absent, unreadable, or stale.
  Future<Set<String>?> readCache(SourceFingerprint fingerprint) async {
    final file = location.cacheFile;
    try {
      if (!await file.exists()) {
        return null;
      }
      return decodeWidgetNameCache(
        contents: await readCacheContents(file),
        fingerprint: fingerprint,
      );
    } on FileSystemException {
      return null;
    }
  }

  /// Replaces the cache with [names], atomically.
  Future<void> writeCache(
    SourceFingerprint fingerprint,
    Set<String> names,
  ) =>
      writeFileAtomically(
        target: location.cacheFile,
        contents: encodeWidgetNameCache(
          fingerprint: fingerprint,
          names: names,
        ),
        replace: replaceFile,
      );
}

/// Locates the Dart SDK the analyzer should resolve against.
///
/// Prefers `FLUTTER_ROOT`, which `flutter test` sets: under `flutter test`,
/// `Platform.resolvedExecutable` points at the `flutter_tester` engine rather
/// than the Dart binary. Spawning a `flutter` process would be far slower.
String resolveDartSdkPath({
  Map<String, String>? environment,
  String? resolvedExecutable,
}) {
  final flutterRoot = (environment ?? Platform.environment)['FLUTTER_ROOT'];
  if (flutterRoot != null && flutterRoot.isNotEmpty) {
    return p.normalize(p.join(flutterRoot, 'bin', 'cache', 'dart-sdk'));
  }
  return p.normalize(
    File(resolvedExecutable ?? Platform.resolvedExecutable).parent.parent.path,
  );
}

/// Crawls the project and extracts public class names from the `/lib` folder.
///
/// `package:analyzer` is a runtime dependency, not a dev dependency, because
/// this runs inside the *consumer's* `setUpAll` and parses the *consumer's*
/// sources. Pub does not install a published package's dev dependencies for
/// downstream consumers, so moving it would make the import unresolvable in
/// every consumer's test run.
Future<Set<String>> getWidgetNames({WidgetNameCacheLocation? location}) async =>
    (await WidgetNameScanner(
      location: location ?? WidgetNameCacheLocation.forCurrentDirectory(),
    ).load())
        .names;

/// Reads a cache file, dropping blank lines and `#` comments.
Future<Set<String>> readWidgetsFile(String filePath) async {
  final text = await File(filePath).readAsString();
  return text
      .split('\n')
      .where((line) => line.isNotEmpty && !line.startsWith('#'))
      .toSet();
}

Future<String> _readFileAsString(File file) => file.readAsString();
