import 'dart:io';

import 'package:approval_tests/approval_tests.dart';
import 'package:approval_tests_flutter/src/get_widget_names.dart';
import 'package:approval_tests_flutter/src/io/atomic_file.dart';
import 'package:approval_tests_flutter/src/widget_names/widget_name_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Creates a temp package root with its symlinks resolved.
///
/// The analyzer rejects a path that is not already normalized, so the macOS
/// `/var` -> `/private/var` symlink has to be resolved first. The stub
/// `pubspec.yaml` stops context-root discovery from walking up into this repo.
Future<Directory> _createPackageRoot(String prefix) async {
  final created = await Directory.systemTemp.createTemp(prefix);
  final resolved = Directory(await created.resolveSymbolicLinks());
  await Directory(p.join(resolved.path, 'lib')).create(recursive: true);
  await File(p.join(resolved.path, 'pubspec.yaml'))
      .writeAsString('name: fixture\nenvironment:\n  sdk: ">=3.0.0 <4.0.0"\n');
  return resolved;
}

File _writeSource(Directory root, String relativePath, String contents) {
  final file = File(p.join(root.path, 'lib', relativePath));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(contents);
  return file;
}

WidgetNameScanner _scanner(
  Directory root, {
  Future<void> Function(File from, File to)? replaceFile,
  Future<String> Function(File file)? readCacheContents,
}) =>
    WidgetNameScanner(
      location: WidgetNameCacheLocation(packageRoot: root.path),
      sdkPath: resolveDartSdkPath(),
      sdkIdentity: 'fixture-sdk',
      replaceFile: replaceFile ?? replaceFileWithRetry,
      readCacheContents: readCacheContents ?? ((file) => file.readAsString()),
    );

File _cacheFile(Directory root) =>
    WidgetNameCacheLocation(packageRoot: root.path).cacheFile;

void main() {
  late Directory root;

  setUp(() async {
    root = await _createPackageRoot('widget_name_cache');
  });

  tearDown(() => root.deleteSync(recursive: true));

  group('WidgetNameCacheLocation', () {
    test('normalizes every path it derives', () {
      final location = WidgetNameCacheLocation(
        packageRoot: p.join(root.path, 'nested', '..'),
      );

      expect(location.packageRoot, equals(p.normalize(root.path)));
      expect(location.libPath, equals(p.join(root.path, 'lib')));
      expect(
        location.cacheFilePath,
        equals(p.join(root.path, 'test', '.approval_tests', 'class_names.txt')),
      );
    });
  });

  group('scan', () {
    test('returns public class names and skips private ones', () async {
      _writeSource(root, 'a.dart', 'class Public {}\nclass _Private {}');

      final result = await _scanner(root).load();

      expect(result.names, equals({'Public'}));
    });

    test('skips an unparseable file and keeps the rest', () async {
      _writeSource(root, 'good.dart', 'class Good {}');
      _writeSource(root, 'bad.dart', 'class {{{');

      final result = await _scanner(root).load();

      expect(result.names, contains('Good'));
    });

    test('returns an empty set when lib has no sources', () async {
      final result = await _scanner(root).load();

      expect(result.names, isEmpty);
    });
  });

  group('load', () {
    test('reports a cold run and writes a sorted body', () async {
      _writeSource(root, 'a.dart', 'class Zebra {}\nclass Alpha {}');

      final result = await _scanner(root).load();

      expect(result.fromCache, isFalse);
      expect(
        await readWidgetsFile(_cacheFile(root).path),
        equals({'Alpha', 'Zebra'}),
      );
      expect(
        _cacheFile(root).readAsLinesSync().where((l) => !l.startsWith('#')),
        equals(['Alpha', 'Zebra']),
      );
      expect(_cacheFile(root).readAsStringSync(), endsWith('Zebra\n'));
    });

    test('reports a warm run with the same names', () async {
      _writeSource(root, 'a.dart', 'class A {}');
      final cold = await _scanner(root).load();

      final warm = await _scanner(root).load();

      expect(warm.fromCache, isTrue);
      expect(warm.names, equals(cold.names));
    });

    test('writes a byte-identical cache across two cold runs', () async {
      _writeSource(root, 'a.dart', 'class Zebra {}\nclass Alpha {}');

      await _scanner(root).load();
      final first = _cacheFile(root).readAsBytesSync();
      _cacheFile(root).deleteSync();
      await _scanner(root).load();

      expect(_cacheFile(root).readAsBytesSync(), equals(first));
    });

    test('creates a missing cache directory chain', () async {
      _writeSource(root, 'a.dart', 'class A {}');
      expect(_cacheFile(root).parent.existsSync(), isFalse);

      await _scanner(root).load();

      expect(_cacheFile(root).existsSync(), isTrue);
    });

    test('recovers when an existing cache cannot be read', () async {
      _writeSource(root, 'a.dart', 'class A {}');
      await _scanner(root).load();

      final result = await _scanner(
        root,
        readCacheContents: (file) async => throw FileSystemException(
          'unreadable',
          file.path,
        ),
      ).load();

      expect(result.fromCache, isFalse);
      expect(result.names, {'A'});
    });
  });

  group('cache invalidation', () {
    test('misses after a source is touched', () async {
      final file = _writeSource(root, 'a.dart', 'class A {}');
      await _scanner(root).load();

      file.setLastModifiedSync(
        file.lastModifiedSync().add(const Duration(minutes: 1)),
      );

      expect((await _scanner(root).load()).fromCache, isFalse);
    });

    test('misses after a backdated source is added', () async {
      final existing = _writeSource(root, 'a.dart', 'class A {}');
      await _scanner(root).load();

      _writeSource(root, 'b.dart', 'class B {}').setLastModifiedSync(
        existing.lastModifiedSync().subtract(const Duration(days: 7)),
      );

      expect((await _scanner(root).load()).fromCache, isFalse);
    });

    test('misses after a source is deleted', () async {
      _writeSource(root, 'a.dart', 'class A {}');
      final removable = _writeSource(root, 'b.dart', 'class B {}');
      await _scanner(root).load();

      removable.deleteSync();

      expect((await _scanner(root).load()).fromCache, isFalse);
    });

    test('misses when a valid cache is copied into another package', () async {
      _writeSource(root, 'a.dart', 'class A {}');
      await _scanner(root).load();

      final other = await _createPackageRoot('widget_name_cache_other');
      addTearDown(() => other.deleteSync(recursive: true));
      _writeSource(other, 'a.dart', 'class A {}');
      _cacheFile(other).parent.createSync(recursive: true);
      _cacheFile(root).copySync(_cacheFile(other).path);

      expect((await _scanner(other).load()).fromCache, isFalse);
    });
  });

  group('malformed and legacy caches are a recoverable miss', () {
    Future<void> expectMiss(String contents) async {
      _writeSource(root, 'a.dart', 'class A {}');
      _cacheFile(root).parent.createSync(recursive: true);
      _cacheFile(root).writeAsStringSync(contents);

      final result = await _scanner(root).load();

      expect(result.fromCache, isFalse);
      expect(result.names, equals({'A'}));
      expect(
        decodeWidgetNameCache(
          contents: _cacheFile(root).readAsStringSync(),
          fingerprint: await _scanner(root).fingerprintSources(),
        ),
        equals({'A'}),
      );
    }

    test('a 1.4.1 file without a version line', () async {
      await expectMiss('${ApprovalTestsConstants.widgetHeader}\nStale\n');
    });

    test('an unknown schema revision', () async {
      await expectMiss(
        '${ApprovalTestsConstants.widgetHeader}\n'
        '# approval-tests-flutter-cache: v999 fnv1a64=0000000000000000\nStale\n',
      );
    });

    test('an empty file', () => expectMiss(''));

    test('a truncated header', () async {
      await expectMiss('# This file was autogen');
    });

    // Escaped rather than literal: raw control bytes in the source make git
    // classify the whole file as binary, losing line diffs and blame.
    test('random bytes', () => expectMiss('\x00\x01 nonsense \x02'));

    test('a garbage digest token', () async {
      await expectMiss(
        '${ApprovalTestsConstants.widgetHeader}\n'
        '# approval-tests-flutter-cache: v2 garbage\nStale\n',
      );
    });
  });

  group('write failures do not fail the run', () {
    test('returns the names, logs, and leaves no temp file', () async {
      _writeSource(root, 'a.dart', 'class A {}');

      final result = await _scanner(
        root,
        replaceFile: (from, to) async => throw PathAccessException(
          to.path,
          const OSError('locked', 5),
        ),
      ).load();

      expect(result.names, equals({'A'}));
      expect(_cacheFile(root).existsSync(), isFalse);
      expect(
        _cacheFile(root)
            .parent
            .listSync()
            .where((e) => e.path.endsWith('.tmp')),
        isEmpty,
      );
    });
  });

  group('concurrent loads', () {
    test('agree on the names and leave a valid cache', () async {
      _writeSource(root, 'a.dart', 'class Alpha {}\nclass Beta {}');

      final results = await Future.wait(
        List.generate(8, (_) => _scanner(root).load()),
      );

      for (final result in results) {
        expect(result.names, equals({'Alpha', 'Beta'}));
      }
      expect(
        decodeWidgetNameCache(
          contents: _cacheFile(root).readAsStringSync(),
          fingerprint: await _scanner(root).fingerprintSources(),
        ),
        equals({'Alpha', 'Beta'}),
      );
    });
  });

  group('readWidgetsFile', () {
    test('drops blank lines and comments', () async {
      final file = File(p.join(root.path, 'names.txt'))
        ..writeAsStringSync('# comment\n\nAlpha\nBeta\n');

      expect(await readWidgetsFile(file.path), equals({'Alpha', 'Beta'}));
    });
  });

  group('resolveDartSdkPath', () {
    test('uses FLUTTER_ROOT when it is present', () {
      expect(
        resolveDartSdkPath(
          environment: {'FLUTTER_ROOT': p.join(root.path, 'flutter')},
        ),
        p.join(root.path, 'flutter', 'bin', 'cache', 'dart-sdk'),
      );
    });

    test('falls back to the resolved executable', () {
      expect(
        resolveDartSdkPath(
          environment: const {},
          resolvedExecutable: p.join(root.path, 'dart-sdk', 'bin', 'dart'),
        ),
        p.join(root.path, 'dart-sdk'),
      );
    });
  });

  group('isRetryableRenameError', () {
    for (final errorCode in [5, 32, 33]) {
      test('accepts Windows lock error $errorCode', () {
        expect(
          isRetryableRenameError(
            PathAccessException('x', OSError('locked', errorCode)),
            isWindows: true,
          ),
          isTrue,
        );
      });
    }

    test('rejects a non-lock failure', () {
      expect(
        isRetryableRenameError(
          const PathAccessException('x', OSError('other', 999)),
          isWindows: true,
        ),
        isFalse,
      );
    });

    test('rejects a non-filesystem error', () {
      expect(isRetryableRenameError(StateError('nope')), isFalse);
    });
  });

  group('replaceFileWithRetry', () {
    test('retries transient Windows locks and then succeeds', () async {
      final from = File(p.join(root.path, 'from.txt'))
        ..writeAsStringSync('new');
      final to = File(p.join(root.path, 'to.txt'))..writeAsStringSync('old');
      var attempts = 0;

      await replaceFileWithRetry(
        from,
        to,
        isWindows: true,
        rename: (source, destination) async {
          attempts++;
          if (attempts < 3) {
            throw PathAccessException(
              destination,
              const OSError('locked', 32),
            );
          }
          await source.rename(destination);
        },
      );

      expect(attempts, 3);
      expect(to.readAsStringSync(), 'new');
    });

    test('stops after the bounded retry count', () async {
      final from = File(p.join(root.path, 'from.txt'))
        ..writeAsStringSync('new');
      final to = File(p.join(root.path, 'to.txt'))..writeAsStringSync('old');
      var attempts = 0;

      await expectLater(
        replaceFileWithRetry(
          from,
          to,
          isWindows: true,
          rename: (_, destination) async {
            attempts++;
            throw PathAccessException(
              destination,
              const OSError('locked', 5),
            );
          },
        ),
        throwsA(isA<PathAccessException>()),
      );

      expect(attempts, 100);
      expect(to.readAsStringSync(), 'old');
    });
  });
}
