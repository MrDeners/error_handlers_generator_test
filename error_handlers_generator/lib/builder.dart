import 'package:build/build.dart';
import 'package:error_handlers_generator/src/generators/error_handlers_generator.dart';
import 'package:source_gen/source_gen.dart';

Builder errorHandlersBuilder(BuilderOptions options) {
  return SharedPartBuilder(
    [ErrorHandlersBuilder()],
    'error_handlers_generator',
  );
}
