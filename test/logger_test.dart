// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger_module/log.dart';
import 'package:logger_module/logger/logger.dart';

void main() {
  testWidgets('Logger test', (WidgetTester tester) async {
    await ZZLogger.initialize(
      onUpload: (
        exception,
        stack, {
        fatal = false,
        reason,
      }) =>
          Log.trace('Uploads exception: $exception'),
    ); // Logs upload as an other log in this example

    expect(
      SynchronousFuture(Log.trace('TRACE')),
      completes,
    );

    expect(
      SynchronousFuture(Log.debug('DEBUG')),
      completes,
    );

    expect(
      SynchronousFuture(Log.info('INFORMATION')),
      completes,
    );

    expect(
      SynchronousFuture(Log.warning('WARNING')),
      completes,
    );

    expect(
      SynchronousFuture(Log.error('ERROR', stackTrace: StackTrace.empty, upload: true)),
      completes,
    );

    expect(
      SynchronousFuture(Log.fatal('FATAL', stackTrace: StackTrace.empty)),
      completes,
    );
  });
}
