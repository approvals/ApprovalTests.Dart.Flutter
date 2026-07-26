import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// FNV-1a 64-bit hash of [value], rendered as 16 lowercase hex digits.
///
/// Hand-rolled rather than taken from `crypto`: this keys a cache, it is not a
/// security boundary. `String.hashCode` would not do — the VM's string hash is
/// not stable across SDK versions.
String fnv1a64(String value) {
  var hash = 0xcbf29ce484222325;
  for (final byte in utf8.encode(value)) {
    hash ^= byte;
    hash = (hash * 0x100000001b3) & 0xffffffffffffffff;
  }
  // Dart's int is signed, so toRadixString would prefix a minus for a hash
  // with the top bit set. Render the two halves separately instead.
  final high = (hash >>> 32).toRadixString(16).padLeft(8, '0');
  final low = (hash & 0xffffffff).toRadixString(16).padLeft(8, '0');
  return '$high$low';
}

/// One `.dart` file considered by widget-name discovery.
final class DartSource {
  const DartSource({
    required this.relativePath,
    required this.modifiedMicroseconds,
    required this.size,
  });

  /// Path relative to the scanned root, always with `/` separators.
  final String relativePath;
  final int modifiedMicroseconds;
  final int size;

  String get _digestInput => '$relativePath|$modifiedMicroseconds|$size';
}

/// The set of sources a scan covered, plus the identity of the tooling.
///
/// [digest] is what a cache stores and re-checks. Modification time alone is
/// not enough: deleting a file that is not the newest, checking out a branch
/// with backdated timestamps, and renaming with timestamps preserved all leave
/// the newest-mtime unchanged. Comparing a digest for equality also sidesteps
/// filesystems with one-second timestamp granularity, where an ordering
/// comparison can miss an edit made in the same second as the cache write.
final class SourceFingerprint {
  const SourceFingerprint({
    required this.sources,
    required this.schemaVersion,
    required this.packageRoot,
    required this.sdkPath,
    required this.sdkIdentity,
  });

  /// Discovered sources, ordered by [DartSource.relativePath].
  final List<DartSource> sources;
  final int schemaVersion;
  final String packageRoot;
  final String sdkPath;

  /// Identity of the running SDK, catching an in-place upgrade that leaves
  /// [sdkPath] unchanged.
  final String sdkIdentity;

  /// Stable digest over the sources and the tooling identity.
  String get digest => fnv1a64(
        [
          'v$schemaVersion',
          packageRoot,
          sdkPath,
          sdkIdentity,
          ...sources.map((source) => source._digestInput),
        ].join('\n'),
      );
}

bool _isScannableDartFile(String path) =>
    path.endsWith('.dart') &&
    !path.endsWith('.g.dart') &&
    !path.endsWith('.freezed.dart');

/// Lists the `.dart` files under [root], sorted by relative path.
///
/// One traversal collects both the file list and the stats the digest needs;
/// discovery used to walk the tree twice, once to scan and once to check
/// freshness against a different (relative) path.
Future<List<DartSource>> collectDartSources(String root) async {
  final directory = Directory(root);
  if (!await directory.exists()) {
    return const [];
  }

  final sources = <DartSource>[];
  await for (final entity in directory.list(recursive: true)) {
    if (entity is! File || !_isScannableDartFile(entity.path)) {
      continue;
    }
    final stat = await entity.stat();
    sources.add(
      DartSource(
        relativePath: p.url.joinAll(
          p.split(p.relative(entity.path, from: root)),
        ),
        modifiedMicroseconds: stat.modified.microsecondsSinceEpoch,
        size: stat.size,
      ),
    );
  }

  sources.sort((a, b) => a.relativePath.compareTo(b.relativePath));
  return sources;
}
