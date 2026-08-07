import 'package:flutter/material.dart';

class ExampleApp extends StatelessWidget {
  const ExampleApp({
    required this.home,
    super.key,
  });

  final Widget home;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Approval Tests example',
        home: home,
      );
}
