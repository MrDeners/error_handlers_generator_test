import 'dart:async';

import 'package:analyzer/dart/constant/value.dart';
import 'package:error_handlers_generator/src/consts/annotations_names.dart';
import 'package:error_handlers_generator/src/consts/annotations_properties.dart';
import 'package:error_handlers_generator_annotations/error_handlers_generator_annotations.dart';
import 'package:source_gen/source_gen.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:collection/collection.dart';
import 'package:build/build.dart';

/// A builder class that generates error-handling methods for annotated methods in a class.
///
/// This class processes methods annotated with `GenerateErrorHandler` and generates
/// corresponding error-handling code. The generated code catches specified exceptions,
/// applies corresponding handlers, and logs errors if specified by the annotation.
class ErrorHandlersBuilder
    extends GeneratorForAnnotation<ErrorHandlersGenerator> {
  /// Generates code for methods annotated with `GenerateErrorHandler` in a class.
  ///
  /// This method examines the class for methods that have been annotated with
  /// `GenerateErrorHandler` and generates error-handling methods for each annotated method.
  /// The generated methods handle specific exceptions, log errors if requested, and rethrow errors.
  ///
  /// Parameters:
  /// - [element]: The class element to analyze.
  /// - [annotation]: The `GenerateErrorHandler` annotation attached to the class.
  /// - [buildStep]: The build step during the generation process.
  ///
  /// Returns a string containing the generated code or null if no annotated methods are found.
  @override
  FutureOr<String?> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is ClassElement) {
      final className = element.name;

      final annotatedMethods = _getAnnotatedMethods(element);
      if (annotatedMethods.isNotEmpty) {
        final methodHandlers = annotatedMethods.map((method) {
          final catchers = _extractCatchersFromAnnotation(method);

          return _generateMethodHandler(
              method, catchers, className, annotation);
        }).join('\n');

        return '''
            // ignore_for_file: avoid_print, unused_element, unused_local_variable
            
            extension ${className}ErrorHandlers on $className {
              $methodHandlers
            }
        ''';
      }
    }

    return null;
  }

  /// Retrieves methods in the class that are annotated with `GenerateErrorHandler`.
  ///
  /// This method filters the methods of a class to find those that are annotated with
  /// the `GenerateErrorHandler` annotation. Only methods with this annotation are processed.
  ///
  /// Parameters:
  /// - [element]: The class element from which to retrieve the annotated methods.
  ///
  /// Returns a list of methods that are annotated with `GenerateErrorHandler`.
  List<MethodElement> _getAnnotatedMethods(ClassElement element) {
    return element.methods
        .where(
          (method) => method.metadata.any(
            (annotation) =>
                annotation.element?.enclosingElement3?.name ==
                AnnotationsNames.generateErrorHandler,
          ),
        )
        .toList();
  }

  /// Extracts the `catchers` value from the `GenerateErrorHandler` annotation.
  ///
  /// This method retrieves the `catchers` parameter from the `GenerateErrorHandler` annotation,
  /// which is a map of exception types to handler functions. The `catchers` map defines which
  /// exceptions should be caught and how they should be handled.
  ///
  /// Parameters:
  /// - [method]: The method element annotated with `GenerateErrorHandler`.
  ///
  /// Returns a map of exception types and corresponding handler function names, or null if no
  /// `catchers` are specified.
  Map<String, String>? _extractCatchersFromAnnotation(MethodElement method) {
    final annotation = method.metadata.firstWhereOrNull((meta) {
      return meta.element?.enclosingElement3?.name ==
          AnnotationsNames.generateErrorHandler;
    });

    if (annotation == null) return null;

    final constantValue = annotation.computeConstantValue();
    if (constantValue == null) return null;

    final catchersField =
        constantValue.getField(AnnotationsProperties.catchers);
    if (catchersField == null || catchersField.isNull) return null;

    return _parseCatchers(catchersField.toMapValue());
  }

  /// Parses the `catchers` map from the annotation.
  ///
  /// This method processes the map in the `catchers` field of the `GenerateErrorHandler` annotation
  /// and converts it into a usable format. The map should associate exception types with handler
  /// function names. Each entry is checked for validity, and any errors in the map will result in
  /// an exception being thrown.
  ///
  /// Parameters:
  /// - [map]: The map to parse, containing exception types and handler function names.
  ///
  /// Returns a map of exception types and corresponding handler function names.
  ///
  /// Throws an error if the map is not valid.
  Map<String, String> _parseCatchers(Map<DartObject?, DartObject?>? map) {
    if (map == null) {
      throw InvalidGenerationSourceError(
          'Catchers must be a Map<Type, Function>.');
    }

    final parsedCatchers = <String, String>{};
    for (final entry in map.entries) {
      final exceptionType = entry.key?.toTypeValue()?.getDisplayString();
      final handlerFunction = entry.value?.toFunctionValue()?.displayName;

      if (exceptionType == null || handlerFunction == null) {
        throw InvalidGenerationSourceError('Invalid data in catchers: $map');
      }

      parsedCatchers[exceptionType] = handlerFunction;
    }

    return parsedCatchers;
  }

  /// Generates the error-handling method for a given annotated method.
  ///
  /// This method creates a new error-handling method that wraps the original method.
  /// It includes a `try-catch` block, where specific exceptions are caught, handled by
  /// specified handler functions, and logged if needed.
  ///
  /// Parameters:
  /// - [method]: The original method element to generate the error handler for.
  /// - [catchers]: A map of exception types to handler function names.
  /// - [className]: The name of the class containing the method.
  /// - [annotation]: The annotation applied to the method.
  ///
  /// Returns a string containing the generated error-handling method code.
  String _generateMethodHandler(
    MethodElement method,
    Map<String, String>? catchers,
    String className,
    ConstantReader annotation,
  ) {
    final methodName = method.name;

    final useLogging = _extractUseLoggingFromAnnotation(method);
    final parameters = _generateParameters(method);
    final arguments = _generateArguments(method);
    final errorHandlingBlock =
        catchers == null ? '' : _generateErrorHandlingBlock(catchers);

    return '''
        void ${methodName}ErrorCatching($parameters) {
          try {
            $methodName($arguments);
          } catch (error, stackTrace) {
            $errorHandlingBlock
    
            ${useLogging ? '''
              print('================================================================================================================');
              print('🔴 \${error.runtimeType} - $className.$methodName:');
              print('Message: \$error');
              print('StackTrace: \$stackTrace');
              print('================================================================================================================');
            ''' : ''}
            
            rethrow;
          }
        }
    ''';
  }

  /// Extracts the `useLogging` value from the `GenerateErrorHandler` annotation.
  ///
  /// This method retrieves the `useLogging` parameter from the annotation, which determines
  /// whether logging should be enabled in the generated error-handling method.
  ///
  /// Parameters:
  /// - [method]: The method element annotated with `GenerateErrorHandler`.
  ///
  /// Returns `true` if logging is enabled, or `false` if logging is disabled or not specified.
  ///
  /// Throws an error if the annotation is missing or invalid.
  bool _extractUseLoggingFromAnnotation(MethodElement method) {
    final annotation = method.metadata.firstWhereOrNull((meta) {
      return meta.element?.enclosingElement3?.name ==
          AnnotationsNames.generateErrorHandler;
    });

    if (annotation == null) {
      throw InvalidGenerationSourceError(
        'Method ${method.name} must contain the GenerateErrorHandler annotation with the useLogging parameter.',
        element: method,
      );
    }

    final constantValue = annotation.computeConstantValue();
    if (constantValue == null) {
      throw InvalidGenerationSourceError(
        'Unable to retrieve the GenerateErrorHandler annotation value in method ${method.name}.',
        element: method,
      );
    }

    final useLoggingField =
        constantValue.getField(AnnotationsProperties.useLogging);
    if (useLoggingField == null || useLoggingField.isNull) {
      return false;
    }

    return useLoggingField.toBoolValue() ?? false;
  }

  /// Generates the parameters for the method as a string.
  ///
  /// This method converts the parameters of the method into a formatted string that can be
  /// used in the generated error-handling method.
  ///
  /// Parameters:
  /// - [method]: The method element whose parameters are to be generated.
  ///
  /// Returns a string representation of the method's parameters.
  String _generateParameters(MethodElement method) {
    return method.parameters.map((param) {
      final paramType = param.type.getDisplayString();
      return '$paramType ${param.name}';
    }).join(', ');
  }

  /// Generates the arguments for the method as a string.
  ///
  /// This method converts the arguments of the method into a formatted string that can be
  /// used in the generated error-handling method.
  ///
  /// Parameters:
  /// - [method]: The method element whose arguments are to be generated.
  ///
  /// Returns a string representation of the method's arguments.
  String _generateArguments(MethodElement method) {
    return method.parameters.map((param) {
      return param.name;
    }).join(', ');
  }

  /// Generates the error handling block for catching exceptions.
  ///
  /// This method creates the necessary code block for catching and handling specific exceptions
  /// defined in the `catchers` map. The code block will include specific handlers for different
  /// exception types and rethrow the error after handling it.
  ///
  /// Parameters:
  /// - [catchers]: A map of exception types to handler function names.
  ///
  /// Returns a string containing the error handling block to be used in the `try-catch` block.
  String _generateErrorHandlingBlock(Map<String, String> catchers) {
    final catchBlocks = catchers.entries.map((entry) {
      final exceptionType = entry.key;
      final handlerFunction = entry.value;

      return '''
        if (error is $exceptionType) {
          $handlerFunction(error, stackTrace);
        }
      ''';
    }).join('\n');

    return catchBlocks;
  }
}
