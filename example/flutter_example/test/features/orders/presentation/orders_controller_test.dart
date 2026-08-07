import 'dart:async';

import 'package:flutter_example/features/orders/domain/order.dart';
import 'package:flutter_example/features/orders/domain/orders_load_exception.dart';
import 'package:flutter_example/features/orders/presentation/orders_controller.dart';
import 'package:flutter_example/features/orders/presentation/orders_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_orders_repository.dart';
import '../../../support/order_fixtures.dart';

void main() {
  group('OrdersController', () {
    test('emits loading then loaded with repository orders', () async {
      const orders = [readyOrderFixture];
      final controller = OrdersController(
        repository: FakeOrdersRepository(() async => orders),
      );
      addTearDown(controller.dispose);
      final states = <OrdersState>[];
      controller.addListener(() => states.add(controller.value));

      await controller.load();

      expect(states, [isA<OrdersLoading>(), isA<OrdersLoaded>()]);
      expect((states.last as OrdersLoaded).orders, orders);
    });

    test('emits loading then failure for a typed load exception', () async {
      final controller = OrdersController(
        repository: FakeOrdersRepository(
          () async => throw const OrdersLoadException('Service unavailable'),
        ),
      );
      addTearDown(controller.dispose);
      final states = <OrdersState>[];
      controller.addListener(() => states.add(controller.value));

      await controller.load();

      expect(states, [isA<OrdersLoading>(), isA<OrdersFailure>()]);
      expect(
        (states.last as OrdersFailure).message,
        'Service unavailable',
      );
    });

    test('ignores a repository result after disposal', () async {
      final result = Completer<List<Order>>();
      final controller = OrdersController(
        repository: FakeOrdersRepository(() => result.future),
      );

      final load = controller.load();
      controller.dispose();
      result.complete(const []);

      await expectLater(load, completes);
    });
  });
}
