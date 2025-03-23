import 'package:error_handlers_generator_annotations/error_handlers_generator_annotations.dart';
import 'package:flutter/material.dart';

part 'test_class.g.dart';

@ErrorHandlersGenerator()
class TestClass {
  @GenerateErrorHandler(catchers: {
    ///We can't use anonymous functions in const constructor,
    ///but we can create class with static const named functions, that can provide some error handling variants
    Exception: logError,
  })
  void showAlert(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Alert with error catching"),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.black.withAlpha(230),
      ),
    );
  }
}

void logError(dynamic error, StackTrace stackTrace) {
  print('Error: $error');
  print('StackTrace: $stackTrace');
}
