import 'package:error_handlers_generator/error_handlers_generator.dart';

part 'test_class.g.dart';

@ErrorHandlersGenerator()
class TestClass {
  @GenerateErrorHandler(catchers: {
    ///We can't use anonymous functions in const constructor,
    ///but we can create class with static const named functions, that can provide some error handling variants
    Exception: logError,
  })
  void test() {}
}

void logError(dynamic error, StackTrace stackTrace) {
  print('Error: $error');
  print('StackTrace: $stackTrace');
}
