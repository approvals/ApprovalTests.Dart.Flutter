/// [String] extension
extension StringApprovedExtension on String {
  /// git diff complains when file doesn't end in newline. This getter ensures a string does.
  String get endWithNewline => endsWith('\n') ? this : '$this\n';
}
