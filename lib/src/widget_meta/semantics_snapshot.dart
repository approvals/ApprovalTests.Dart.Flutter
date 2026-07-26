import 'package:flutter/semantics.dart';

/// Curated, high-signal semantic actions surfaced in approval snapshots.
///
/// Read through the stable [SemanticsData.hasAction]; flag/role serialization is
/// intentionally omitted because the only APIs for it are either deprecated
/// (`hasFlag`) or require Flutter 3.32+ (`flagsCollection`).
const Map<String, SemanticsAction> _snapshotActions = {
  'tap': SemanticsAction.tap,
  'longPress': SemanticsAction.longPress,
  'scrollLeft': SemanticsAction.scrollLeft,
  'scrollRight': SemanticsAction.scrollRight,
  'scrollUp': SemanticsAction.scrollUp,
  'scrollDown': SemanticsAction.scrollDown,
  'increase': SemanticsAction.increase,
  'decrease': SemanticsAction.decrease,
  'dismiss': SemanticsAction.dismiss,
};

/// Serializes the semantics [root] into a deterministic, geometry-free text
/// tree suitable for an approval snapshot.
///
/// Geometry (rects, transforms, scroll offsets) is intentionally omitted so the
/// snapshot stays stable across screen sizes and platforms.
String describeSemanticsTree(SemanticsNode? root) {
  if (root == null) {
    return 'No semantics tree available. '
        'Pump a widget that produces semantics before calling approvalSemantics().';
  }
  final buffer = StringBuffer();
  _describeNode(root, buffer, 0);
  return buffer.toString().trimRight();
}

void _describeNode(SemanticsNode node, StringBuffer buffer, int depth) {
  final data = node.getSemanticsData();
  final parts = <String>[];

  void addText(String key, String value) {
    if (value.isNotEmpty) {
      parts.add("$key: '$value'");
    }
  }

  addText('label', data.label);
  addText('value', data.value);
  addText('hint', data.hint);
  addText('tooltip', data.tooltip);
  addText('identifier', data.identifier);

  final actions = _snapshotActions.entries
      .where((entry) => data.hasAction(entry.value))
      .map((entry) => entry.key)
      .toList();
  if (actions.isNotEmpty) {
    parts.add('actions: [${actions.join(', ')}]');
  }

  final indent = '  ' * depth;
  buffer
      .writeln('$indent- ${parts.isEmpty ? '<container>' : parts.join(', ')}');

  node.visitChildren((child) {
    _describeNode(child, buffer, depth + 1);
    return true;
  });
}
