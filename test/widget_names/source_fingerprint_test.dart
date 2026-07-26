import 'dart:io';

import 'package:approval_tests_flutter/src/widget_names/source_fingerprint.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Creates a temp package root with its symlinks resolved.
///
/// On macOS `Directory.systemTemp` is `/var/folders/...`, a symlink to
/// `/private/var/folders/...`. The analyzer rejects a path that is not already
/// normalized, and context-root discovery misbehaves on the unresolved form.
Future<Directory> _createPackageRoot(String prefix) async {
  final created = await Directory.systemTemp.createTemp(prefix);
  final resolved = Directory(await created.resolveSymbolicLinks());
  await Directory(p.join(resolved.path, 'lib')).create(recursive: true);
  await File(p.join(resolved.path, 'pubspec.yaml'))
      .writeAsString('name: fixture\n');
  return resolved;
}

File _writeSource(Directory root, String relativePath, String contents) {
  final file = File(p.join(root.path, 'lib', relativePath));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(contents);
  return file;
}

Future<SourceFingerprint> _fingerprint(
  Directory root, {
  String sdkIdentity = 'sdk-1',
  String? packageRoot,
}) async =>
    SourceFingerprint(
      sources: await collectDartSources(p.join(root.path, 'lib')),
      schemaVersion: 2,
      packageRoot: packageRoot ?? root.path,
      sdkPath: '/sdk',
      sdkIdentity: sdkIdentity,
    );

void main() {
  late Directory root;

  setUp(() async {
    root = await _createPackageRoot('source_fingerprint');
  });

  tearDown(() => root.deleteSync(recursive: true));

  group('fnv1a64', () {
    test('is stable and 16 hex digits wide', () {
      expect(fnv1a64('abc'), equals(fnv1a64('abc')));
      expect(fnv1a64('abc'), hasLength(16));
      expect(fnv1a64('abc'), isNot(equals(fnv1a64('abd'))));
    });
  });

  group('collectDartSources', () {
    test('returns an empty list when the directory is absent', () async {
      expect(await collectDartSources(p.join(root.path, 'absent')), isEmpty);
    });

    test('excludes generated and non-Dart files', () async {
      _writeSource(root, 'a.dart', 'class A {}');
      _writeSource(root, 'a.g.dart', 'class AG {}');
      _writeSource(root, 'a.freezed.dart', 'class AF {}');
      _writeSource(root, 'notes.txt', 'text');

      final sources = await collectDartSources(p.join(root.path, 'lib'));

      expect(sources.map((s) => s.relativePath), equals(['a.dart']));
    });

    test('sorts by relative path using forward slashes', () async {
      _writeSource(root, 'z.dart', 'class Z {}');
      _writeSource(root, 'nested/a.dart', 'class A {}');
      _writeSource(root, 'b.dart', 'class B {}');

      final sources = await collectDartSources(p.join(root.path, 'lib'));

      expect(
        sources.map((s) => s.relativePath),
        equals(['b.dart', 'nested/a.dart', 'z.dart']),
      );
    });
  });

  group('SourceFingerprint.digest', () {
    test('is unchanged for an untouched tree', () async {
      _writeSource(root, 'a.dart', 'class A {}');

      expect((await _fingerprint(root)).digest,
          equals((await _fingerprint(root)).digest));
    });

    test('changes when only the size changes', () async {
      final file = _writeSource(root, 'a.dart', 'class A {}');
      final before = await _fingerprint(root);
      final timestamp = file.lastModifiedSync();

      file.writeAsStringSync('class A { final int longer = 1; }');
      file.setLastModifiedSync(timestamp);

      expect((await _fingerprint(root)).digest, isNot(equals(before.digest)));
    });

    test('changes when only the modification time changes', () async {
      final file = _writeSource(root, 'a.dart', 'class A {}');
      final before = await _fingerprint(root);

      file.setLastModifiedSync(
        file.lastModifiedSync().add(const Duration(minutes: 5)),
      );

      expect((await _fingerprint(root)).digest, isNot(equals(before.digest)));
    });

    test('changes when a file is added with a backdated timestamp', () async {
      final existing = _writeSource(root, 'a.dart', 'class A {}');
      final before = await _fingerprint(root);

      _writeSource(root, 'b.dart', 'class B {}').setLastModifiedSync(
        existing.lastModifiedSync().subtract(const Duration(days: 30)),
      );

      expect((await _fingerprint(root)).digest, isNot(equals(before.digest)));
    });

    test('changes when a file that is not the newest is deleted', () async {
      final older = _writeSource(root, 'a.dart', 'class A {}');
      final newer = _writeSource(root, 'b.dart', 'class B {}');
      newer.setLastModifiedSync(
        older.lastModifiedSync().add(const Duration(days: 1)),
      );
      final before = await _fingerprint(root);

      older.deleteSync();

      expect((await _fingerprint(root)).digest, isNot(equals(before.digest)));
    });

    test('changes when a rename preserves timestamps', () async {
      final file = _writeSource(root, 'a.dart', 'class A {}');
      final timestamp = file.lastModifiedSync();
      final before = await _fingerprint(root);

      final renamed = file.renameSync(p.join(root.path, 'lib', 'b.dart'));
      renamed.setLastModifiedSync(timestamp);

      expect((await _fingerprint(root)).digest, isNot(equals(before.digest)));
    });

    test('changes when only the SDK identity changes', () async {
      _writeSource(root, 'a.dart', 'class A {}');

      expect(
        (await _fingerprint(root, sdkIdentity: 'sdk-2')).digest,
        isNot(equals((await _fingerprint(root)).digest)),
      );
    });

    test('changes when only the package root changes', () async {
      _writeSource(root, 'a.dart', 'class A {}');

      expect(
        (await _fingerprint(root, packageRoot: '/elsewhere')).digest,
        isNot(equals((await _fingerprint(root)).digest)),
      );
    });
  });
}
