import 'package:flutter/material.dart';
import 'package:flutter_example/features/orders/domain/order.dart';
import 'package:flutter_example/features/orders/presentation/orders_controller.dart';
import 'package:flutter_example/features/orders/presentation/orders_state.dart';

class OrdersView extends StatelessWidget {
  const OrdersView({
    required this.controller,
    super.key,
  });

  final OrdersController controller;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Orders'),
        ),
        body: ValueListenableBuilder<OrdersState>(
          valueListenable: controller,
          builder: (context, state, child) => switch (state) {
            OrdersInitial() || OrdersLoading() => const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading orders'),
                  ],
                ),
              ),
            OrdersLoaded(:final orders) when orders.isEmpty => const Center(
                child: Text('No orders yet'),
              ),
            OrdersLoaded(:final orders) => ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return ListTile(
                    title: Text(order.productName),
                    subtitle: Text(
                      'Order #${order.id} · ${_statusLabel(order.status)}',
                    ),
                  );
                },
              ),
            OrdersFailure(:final message) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(message),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: controller.load,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
          },
        ),
      );

  static String _statusLabel(OrderStatus status) => switch (status) {
        OrderStatus.processing => 'Processing',
        OrderStatus.ready => 'Ready',
      };
}
