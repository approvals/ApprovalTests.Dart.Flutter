import 'package:flutter/material.dart';
import 'package:flutter_example/app.dart';
import 'package:flutter_example/features/orders/data/demo_orders_repository.dart';
import 'package:flutter_example/features/orders/presentation/orders_screen.dart';

void main() {
  runApp(
    ExampleApp(
      home: OrdersScreen(
        repository: DemoOrdersRepository(),
      ),
    ),
  );
}
