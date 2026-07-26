import 'dart:io';

import 'package:approval_tests/approval_tests.dart';
import 'package:path/path.dart' as p;

const _errorAccessDenied = 5;
const _errorSharingViolation = 32;
const _errorLockViolation = 33;

/// Windows error codes raised when another process holds the destination open.
const _retryableWindowsRenameErrors = {
  _errorAccessDenied,
  _errorSharingViolation,
  _errorLockViolation,
};

const _maxRenameAttempts = 100;
const _renameRetryDelay = Duration(milliseconds: 1);

int _tempFileCounter = 0;

/// Whether [error] is a transient Windows lock that a retry can clear.
bool isRetryableRenameError(Object error) =>
    Platform.isWindows &&
    error is PathAccessException &&
    _retryableWindowsRenameErrors.contains(error.osError?.errorCode);

/// Renames [from] onto [to], retrying transient Windows lock failures.
///
/// On POSIX a same-directory rename is atomic and never needs a retry. On
/// Windows an antivirus scanner, the search indexer, or a parallel
/// `flutter_tester` can hold the destination open briefly.
Future<void> replaceFileWithRetry(File from, File to) async {
  for (var attempt = 1; attempt <= _maxRenameAttempts; attempt++) {
    try {
      await from.rename(to.path);
      return;
    } on FileSystemException catch (error) {
      if (attempt == _maxRenameAttempts || !isRetryableRenameError(error)) {
        rethrow;
      }
      await Future<void>.delayed(_renameRetryDelay);
    }
  }
}

/// Writes [contents] to [target] through a same-directory temporary file.
///
/// `flutter test` runs test files in parallel processes, each of which may
/// rewrite a shared cache while another reads it. A direct write is observable
/// as a truncated file; a rename is not.
///
/// The temporary name carries the process id and a counter, so concurrent
/// writers cannot reuse each other's scratch file.
///
/// Failure is logged and swallowed rather than thrown: the caller already holds
/// the value being cached, and losing a race with a file scanner must not fail
/// a consumer's test run.
Future<void> writeFileAtomically({
  required File target,
  required String contents,
  Future<void> Function(File from, File to) replace = replaceFileWithRetry,
}) async {
  final temporary = File(
    p.join(
      target.parent.path,
      '${p.basename(target.path)}.$pid.${_tempFileCounter++}.tmp',
    ),
  );

  try {
    await target.parent.create(recursive: true);
    await temporary.writeAsString(contents, flush: true);
    await replace(temporary, target);
  } on FileSystemException catch (error) {
    ApprovalLogger.log(
      'package:approval_tests_flutter: could not update ${target.path} '
      '(${error.message}); continuing without it.',
    );
    if (temporary.existsSync()) {
      await temporary.delete();
    }
  }
}
