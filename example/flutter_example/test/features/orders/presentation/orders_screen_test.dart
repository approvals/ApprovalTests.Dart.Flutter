import 'dart:async';

import 'package:approval_tests_flutter/approval_tests_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_example/app.dart';
import 'package:flutter_example/features/orders/domain/order.dart';
import 'package:flutter_example/features/orders/domain/orders_load_exception.dart';
import 'package:flutter_example/features/orders/presentation/orders_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_orders_repository.dart';
import '../../../support/order_fixtures.dart';

void main() {
  setUpAll(ApprovalWidgets.setUpAll);
  tearDownAll(ApprovalWidgets.tearDownAll);

  group('OrdersScreen', () {
    testWidgets('approves the loading state', (tester) async {
      final result = Completer<List<Order>>();

      await tester.pumpWidget(
        ExampleApp(
          home: OrdersScreen(
            repository: FakeOrdersRepository(() => result.future),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Loading orders'), findsOneWidget);
      await tester.approvalTest();

      result.complete(const []);
      await tester.pumpAndSettle();
    });

    testWidgets('approves orders returned by the repository', (tester) async {
      await tester.pumpWidget(
        ExampleApp(
          home: OrdersScreen(
            repository: FakeOrdersRepository(() async => ordersFixture),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mechanical keyboard'), findsOneWidget);
      expect(find.text('USB-C dock'), findsOneWidget);
      await tester.approvalTest();
    });

    testWidgets('approves a typed repository failure', (tester) async {
      await tester.pumpWidget(
        ExampleApp(
          home: OrdersScreen(
            repository: FakeOrdersRepository(
              () async => throw const OrdersLoadException(
                'Service unavailable',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Service unavailable'), findsOneWidget);
      await tester.approvalTest();
    });

    testWidgets('renders an empty result without a snapshot', (tester) async {
      await tester.pumpWidget(
        ExampleApp(
          home: OrdersScreen(
            repository: FakeOrdersRepository(() async => const []),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No orders yet'), findsOneWidget);
    });

    testWidgets('retries after a failure', (tester) async {
      var fetchCount = 0;
      final repository = FakeOrdersRepository(() async {
        fetchCount++;
        if (fetchCount == 1) {
          throw const OrdersLoadException('Service unavailable');
        }
        return const [readyOrderFixture];
      });

      await tester.pumpWidget(
        ExampleApp(home: OrdersScreen(repository: repository)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
      await tester.pumpAndSettle();

      expect(fetchCount, 2);
      expect(find.text('Mechanical keyboard'), findsOneWidget);
    });

    testWidgets('loads orders from a replacement repository', (tester) async {
      await tester.pumpWidget(
        ExampleApp(
          home: OrdersScreen(
            repository: FakeOrdersRepository(
              () async => const [readyOrderFixture],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Mechanical keyboard'), findsOneWidget);

      await tester.pumpWidget(
        ExampleApp(
          home: OrdersScreen(
            repository: FakeOrdersRepository(
              () async => const [processingOrderFixture],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mechanical keyboard'), findsNothing);
      expect(find.text('USB-C dock'), findsOneWidget);
    });
  });
}
