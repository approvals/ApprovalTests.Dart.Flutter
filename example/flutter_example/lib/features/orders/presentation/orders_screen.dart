import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_example/features/orders/domain/orders_repository.dart';
import 'package:flutter_example/features/orders/presentation/orders_controller.dart';
import 'package:flutter_example/features/orders/presentation/orders_view.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({
    required this.repository,
    super.key,
  });

  final OrdersRepository repository;

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

final class _OrdersScreenState extends State<OrdersScreen> {
  late OrdersController _controller;

  @override
  void initState() {
    super.initState();
    _controller = _createController(widget.repository);
  }

  @override
  void didUpdateWidget(covariant OrdersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.repository, widget.repository)) return;

    _controller.dispose();
    _controller = _createController(widget.repository);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => OrdersView(controller: _controller);

  OrdersController _createController(OrdersRepository repository) {
    final controller = OrdersController(repository: repository);
    unawaited(controller.load());
    return controller;
  }
}
