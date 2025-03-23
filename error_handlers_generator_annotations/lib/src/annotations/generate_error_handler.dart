typedef ErrorHandlers = Map<Type, Function(dynamic, StackTrace)>;

class GenerateErrorHandler {
  final bool useLogging;
  final ErrorHandlers? catchers;

  const GenerateErrorHandler({
    this.useLogging = true,
    this.catchers,
  });
}
