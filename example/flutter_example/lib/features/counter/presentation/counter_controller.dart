import 'package:flutter/foundation.dart';

final class CounterController extends ValueNotifier<int> {
  CounterController() : super(0);

  void increment() => value++;
}
