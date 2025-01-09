// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_class.dart';

// **************************************************************************
// Generator: ErrorHandlersBuilder
// **************************************************************************

// ignore_for_file: avoid_print, unused_element, unused_local_variable

extension TestClassErrorHandlers on TestClass {
  void testErrorCatching() {
    try {
      test();
    } catch (error, stackTrace) {
      if (error is Exception) {
        logError(error, stackTrace);
      }

      print(
          '================================================================================================================');
      print('🔴 ${error.runtimeType} - TestClass.test:');
      print('Message: $error');
      print('StackTrace: $stackTrace');
      print(
          '================================================================================================================');

      rethrow;
    }
  }
}
