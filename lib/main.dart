import 'package:error_handlers_generator_test/test_class.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final TestClass testClass = TestClass();

    return MaterialApp(
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => testClass.showAlertErrorCatching(context),
                child: Icon(Icons.add_alert),
              ),
            ),
          );
        }
      ),
    );
  }
}
