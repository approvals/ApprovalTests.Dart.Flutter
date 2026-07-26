import 'package:approval_tests_flutter/src/widget_meta/widget_registry.dart';
import 'package:flutter_test/flutter_test.dart';

final class _Marker {}

final class _Other {}

void main() {
  group('WidgetRegistry', () {
    test('recognizes nothing when empty', () {
      expect(WidgetRegistry.empty.isRegistered(_Marker), isFalse);
    });

    test('recognizes a registered type', () {
      const registry = WidgetRegistry(types: {_Marker});

      expect(registry.isRegistered(_Marker), isTrue);
      expect(registry.isRegistered(_Other), isFalse);
    });

    test('recognizes a type by its name', () {
      const registry = WidgetRegistry(names: {'_Marker'});

      expect(registry.isRegistered(_Marker), isTrue);
      expect(registry.isRegistered(_Other), isFalse);
    });

    test('copyWith replaces only what it is given', () {
      const registry = WidgetRegistry(types: {_Marker}, names: {'A'});

      expect(registry.copyWith(names: {'B'}).types, equals({_Marker}));
      expect(registry.copyWith(names: {'B'}).names, equals({'B'}));
      expect(registry.copyWith(types: {_Other}).names, equals({'A'}));
    });
  });
}
