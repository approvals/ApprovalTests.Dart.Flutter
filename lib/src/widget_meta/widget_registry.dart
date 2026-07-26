/// Widget types and class names a capture treats as registered.
///
/// A registered widget is included in a snapshot under its own type rather
/// than only when it carries a key or text. Types come from `registerTypes`,
/// names from the project scan performed by `ApprovalWidgets.setUpAll()`.
final class WidgetRegistry {
  const WidgetRegistry({
    this.types = const {},
    this.names = const {},
  });

  /// Registry that recognizes nothing.
  static const WidgetRegistry empty = WidgetRegistry();

  final Set<Type> types;
  final Set<String> names;

  bool isRegistered(Type type) =>
      types.contains(type) || names.contains(type.toString());

  WidgetRegistry copyWith({Set<Type>? types, Set<String>? names}) =>
      WidgetRegistry(types: types ?? this.types, names: names ?? this.names);
}
