// Copyright (c) 2024. All rights reserved.
//
// @author: Hüseyin Küçükşahin
// @last_update: 17.05.2024

/// **Version:** 1.0.0
///
/// This library is a complete logger system that can log both console & file.
///
/// ***ANSI***
///
/// The log files are in `.ans` format. That can support ans commands & colors.
/// to read the ansi logs effectively use VS Code Extension `ANSI Colors`
/// (Link: https://marketplace.visualstudio.com/items?itemName=iliazeus.vscode-ansi)
///
/// ---
/// ***Package***
///
/// **Name:** logger
///
/// **Version:** 2.2.0
///
/// **Link:** <https://pub.dev/packages/logger>
library zz_logger;

import 'dart:io' show Directory, File;

import 'package:flutter/foundation.dart' show FlutterError, kDebugMode, protected;
import 'package:intl/intl.dart' show DateFormat;
import 'package:logger/logger.dart'
    show AnsiColor, DateTimeFormat, FileOutput, Level, LogOutput, Logger, MultiOutput, PrettyPrinter, ProductionFilter;
import 'package:stack_trace/stack_trace.dart' show Trace;

import '../directory/directory.dart' show Directories;
import '../error/flutter_error_extensions.dart';
import '../error/platform_dispatcher_extensions.dart';
import '../log.dart' show ILogger, Log;
import 'developer_console_output.dart' show DeveloperConsoleOutput;

class ZZLogger implements ILogger {
  /// Logs will queue up here before logger initialized.
  ///
  /// After initializing they will me logged at once.
  static final StringBuffer _historyBuffer = StringBuffer();
  static bool _bufferHasErrors = false;

  static Future<Directory> get directory async {
    if (Log.directory != null) return Log.directory!;

    var directory = await Directories.get(secure: Log.envFileHidden);

    var dir = Directory('${directory.path}/logs');

    _historyBuffer.writeln('-> Log file will be ${Log.envFileHidden ? 'hidden' : 'visible'}.'
        'Directory:\n`${dir.path}`');

    if (!await dir.exists()) {
      // ? Create dir if not exists
      await dir.create(recursive: true);

      _historyBuffer.writeln('-> Created directory');
    } else {
      // ? Delete older files. (Keep last [_fileCount](5) of them)
      try {
        var list = await dir.list().where((element) => element.path.contains(Log.envFileBaseName)).toList();
        if (list.length > Log.envFileCount) {
          _historyBuffer.writeln(
              '-> Deleting ${list.length - Log.envFileCount} older files because there is ${list.length} log files');

          list.sort((a, b) => b.path.compareTo(a.path));

          for (var index = Log.envFileCount; index < list.length; index++) {
            if (await list.elementAt(index).exists()) {
              await list.elementAt(index).delete();
              _historyBuffer.writeln('Deleted ${list.elementAt(index).path}');
            }
          }
        }
      } catch (error) {
        _historyBuffer.writeln('-> Something went wrong while deleting old log files\n${error.toString()}');
        _bufferHasErrors = true;
      }
    }

    Log.directory = dir;
    return dir;
  }

  static String? _fileName;
  static String _getFileName() =>
      _fileName ??= '${Log.envFileBaseName}_${DateFormat('yyyyMMddTHH').format(DateTime.now())}.ans';

  static Future<String?> _thisPackage() async {
    try {
      var trace = Trace.current();
      var thisTrace = trace.frames.firstOrNull;
      var package = thisTrace?.library;

      _historyBuffer.writeln('-> Package name parsed:\n`$package`');
      return package;
    } catch (error) {
      _historyBuffer.writeln('-> Package name parsing failed.');
      _bufferHasErrors = true;
    }
    return null;
  }

  @protected
  const ZZLogger(
    Logger logger, {
    this.onUpload,
  }) : _logger = logger;
  final Logger _logger;

  final void Function(
    dynamic exception,
    StackTrace? stack, {
    dynamic reason,
    bool fatal,
  })? onUpload;

  /// Needs to be initialized. Afterwards just use [Log].
  static Future<void> initialize({
    required void Function(
      dynamic exception,
      StackTrace? stack, {
      dynamic reason,
      bool fatal,
    })? onUpload,
  }) async {
    _historyBuffer.clear();
    _historyBuffer.writeln('[Logger] Initializing history');
    _bufferHasErrors = false;

    LogOutput? fileOutput;

    if (Log.envFileLog) {
      try {
        var fileDir = '${(await directory).path}/${_getFileName()}';

        Log.filePath = fileDir;

        var file = File(fileDir);
        if (!await file.exists()) {
          await file.create(recursive: true);
        }

        fileOutput = FileOutput(file: file);
      } catch (e) {
        _historyBuffer.writeln('-> Something went wrong while creating log file directory:\n${e.toString()}');
        _bufferHasErrors = true;
      }
    }

    try {
      var package = await _thisPackage();
      if (fileOutput != null || Log.envConsoleLog) {
        Log.logger = ZZLogger(
          Logger(
            printer: PrettyPrinter(
              stackTraceBeginIndex: 0,
              methodCount: kDebugMode ? 5 : 0,
              errorMethodCount: null,
              excludePaths: [
                if (package != null) package,
              ],
              lineLength: 120,
              colors: true,
              printEmojis: true,
              dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
              levelColors: {
                /*
                0:  Black,      8:  Grey
                1:  Red,        9:  Red Ascend
                2:  Green,      10: Green Ascend
                3:  Yellow      11: Yellow Ascend
                4:  Blue        12: Blue Ascend
                5:  Purple      13: Purple Ascend
                6:  Turquoise   14: Turquoise Ascend
                7:  White       15: Bright White
              */
                Level.trace: const AnsiColor.fg(8), // Log something secret
                Level.debug: const AnsiColor.fg(6), // Log something not very important somehow secret
                Level.info: const AnsiColor.fg(10), // Log visible information
                Level.warning: const AnsiColor.fg(5),
                Level.error: const AnsiColor.fg(9),
                Level.fatal: const AnsiColor.fg(1),
              },
            ),
            output: MultiOutput([
              if (fileOutput != null) fileOutput,
              if (Log.envConsoleLog) DeveloperConsoleOutput(),
            ]),
            filter: ProductionFilter(),
            level: Level.values.any((element) => element.name == Log.envLogLevel)
                ? Level.values.firstWhere((element) => element.name == Log.envLogLevel)
                : Level.info,
          ),
          onUpload: onUpload,
        );

        Log.info('[Logger] Initialized');

        if (fileOutput != null) {
          _historyBuffer.writeln('-> ${'Output file name:\n`${_getFileName()}`'}');
        }

        FlutterErrorExtensions.addHandler((details) {
          if (Log.envConsoleLog) {
            FlutterError.presentError(details);
          }

          Log.error(
            '[FlutterError] ${details.exceptionAsString()}',
            error: (kDebugMode ? details.toDiagnosticsNode().toStringDeep() : details.exception.toString()),
            stackTrace: details.stack,
            upload: true,
          );
        });
        _historyBuffer.writeln('-> FlutterError logger added');

        PlatformDispatcherExtensions.addHandler((exception, stackTrace) {
          Log.error(
            '[PlatformDispatcherError] Unhandled Exception',
            error: exception,
            stackTrace: stackTrace,
            upload: true,
          );
          return !kDebugMode;
        });
        _historyBuffer.writeln('-> PlatformDispatcher logger added');

        if (_historyBuffer.isNotEmpty) {
          var message = _historyBuffer.toString().trim();

          (_bufferHasErrors == true)
              ? Log.fatal(
                  message,
                  stackTrace: StackTrace.current,
                  sendFatal: false,
                )
              : Log.trace(message);
        }
      }
    } catch (error, stack) {
      onUpload?.call(
        '[Logger] An exception occurred while initializing',
        stack,
        reason: error,
        fatal: true,
      );
    }
  }

  /// DO NOT USE DIRECTLY. Use [Log.trace] instead
  @Deprecated('DO NOT USE DIRECTLY')
  @override
  void trace(
    dynamic message, {
    Object? error,
    StackTrace? stackTrace = StackTrace.empty,
    DateTime? time,
  }) =>
      _logger.t(
        message,
        error: error,
        stackTrace: stackTrace,
        time: time,
      );

  /// DO NOT USE DIRECTLY. Use [Log.debug] instead
  @Deprecated('DO NOT USE DIRECTLY')
  @override
  void debug(
    dynamic message, {
    Object? error,
    StackTrace? stackTrace = StackTrace.empty,
    DateTime? time,
  }) =>
      _logger.d(
        message,
        error: error,
        stackTrace: stackTrace,
        time: time,
      );

  /// DO NOT USE DIRECTLY. Use [Log.info] instead
  @Deprecated('DO NOT USE DIRECTLY')
  @override
  void info(
    dynamic message, {
    Object? error,
    StackTrace? stackTrace = StackTrace.empty,
    DateTime? time,
  }) =>
      _logger.i(
        message,
        error: error,
        stackTrace: stackTrace,
        time: time,
      );

  /// DO NOT USE DIRECTLY. Use [Log.warning] instead
  @Deprecated('DO NOT USE DIRECTLY')
  @override
  void warning(
    dynamic message, {
    Object? error,
    StackTrace? stackTrace = StackTrace.empty,
    DateTime? time,
  }) =>
      _logger.w(
        message,
        error: error,
        stackTrace: stackTrace,
        time: time,
      );

  /// DO NOT USE DIRECTLY. Use [Log.error] instead
  @Deprecated('DO NOT USE DIRECTLY')
  @override
  void error(
    dynamic message, {
    Object? error,
    required StackTrace? stackTrace,
    DateTime? time,
    bool upload = false,
  }) {
    var stack = stackTrace ?? Trace.current(2);
    if (upload) {
      onUpload?.call(
        message,
        stack,
        fatal: false,
        reason: error,
      );
    }

    _logger.e(
      message,
      error: error,
      stackTrace: stack,
      time: time,
    );
  }

  /// DO NOT USE DIRECTLY. Use [Log.fatal] instead
  @Deprecated('DO NOT USE DIRECTLY')
  @override
  void fatal(
    dynamic message, {
    Object? error,
    required StackTrace? stackTrace,
    DateTime? time,
    bool sendFatal = true,
  }) {
    var stack = stackTrace ?? Trace.current(2);

    onUpload?.call(
      message,
      stack,
      fatal: sendFatal,
      reason: error,
    );

    _logger.f(
      message,
      error: error,
      stackTrace: stack,
      time: time,
    );
  }
}
