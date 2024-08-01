// Copyright (c) 2024. All rights reserved.
//
// @author: Hüseyin Küçükşahin
// @date: 17.05.2024

/// **Version:** 1.0.0
///
/// An interface for segregated Logger system
///
/// All the packages will use this.
///
/// ***dart_defines***
///
/// The configurations can be made by using environment variables.
///
/// - `log` (bool) : enables console logging. (default: `false`)
/// - `logFile` (bool) : enables file logging. (default: `false`)
/// - `logFileHidden` (bool) : uses a secure directory for the log file (default: `true`)
/// - `logFileName` : (String) the saved log file's name (default: `'log'`). Result will be: `log_20231124T15.ans`
/// - `logFileCount` : (int) the old log files to keep, the older ones will be removed. (default: `5`)
/// - `logLevel` : (String) the log level of logger. Use `trace` or `all` to log everything. (default: `info`)
///
/// ***IOS***
///
/// Dont forget to put `UIFileSharingEnabled` on `Info.plist` file if you are using visible file logging on IOS.
///
/// ```xml
/// <key>UIFileSharingEnabled</key>
/// <true/>
/// ```
///
library logger_interface;

import 'dart:io' show Directory;

import 'package:flutter/foundation.dart' show kDebugMode;

/// The main [Log] class to log anything to the console & file
abstract class Log {
  /// Will it log to console. Only true when [kDebugMode] is true. (Default is `false`)
  static const bool envConsoleLog = kDebugMode && bool.fromEnvironment('log', defaultValue: true);

  /// Will it log to file. (Default is `false`)
  static const bool envFileLog = bool.fromEnvironment('logFile', defaultValue: false);

  /// Log level as text. (Default is `'info'`)
  static const String envLogLevel = String.fromEnvironment('logLevel', defaultValue: 'trace');

  /// The base name of the log files. There will be a date extension with `'yyyyMMddTHH'` format
  static const String envFileBaseName = String.fromEnvironment('logFileName', defaultValue: 'log');

  /// Amount of files will not be removed. The max amount of files in the directory will be `_fileCount + 1`
  static const int envFileCount = int.fromEnvironment('logFileCount', defaultValue: 5);

  /// If true the log file will be hidden from users
  static const bool envFileHidden = bool.fromEnvironment('logFileHidden', defaultValue: true);

  /// Actual logger's interface
  ///
  /// Do NOT use this directly. Use the static functions of [Log] instead.
  static ILogger? logger;

  /// Current log file directory
  static Directory? directory;

  /// Current log file's path
  static String? filePath;

  /// TRACE (1000)
  ///
  /// Lowest level of logging. The most HIDDEN log type.
  /// For this function to work [envLogLevel] needs to be set `'trace'` trough env variables.
  ///
  /// Use it to log something that only should be seen on console
  ///
  static void trace(
    dynamic message, {
    Object? error,
    StackTrace? stackTrace = StackTrace.empty,
    DateTime? time,
  }) =>
      logger?.trace(
        message,
        error: error,
        stackTrace: stackTrace,
        time: time ?? DateTime.now(),
      );

  /// DEBUG (2000)
  ///
  /// low level of logging.
  /// For this function to work [envLogLevel] needs to be set `'debug'` (or lower) trough env variables.
  ///
  /// Use it to log something that is not secret but only logged to see if things working.
  ///
  static void debug(
    dynamic message, {
    Object? error,
    StackTrace? stackTrace = StackTrace.empty,
    DateTime? time,
  }) =>
      logger?.debug(
        message,
        error: error,
        stackTrace: stackTrace,
        time: time ?? DateTime.now(),
      );

  /// INFO (3000)
  ///
  /// Common level of logging.
  /// As default this function always working since [envLogLevel] is `'info'` as default.
  ///
  /// Use it to information that is not secret but important.
  ///
  static void info(
    dynamic message, {
    Object? error,
    StackTrace? stackTrace = StackTrace.empty,
    DateTime? time,
  }) =>
      logger?.info(
        message,
        error: error,
        stackTrace: stackTrace,
        time: time ?? DateTime.now(),
      );

  /// WARNING (4000)
  ///
  /// High level of logging.
  /// As default this function always working since [envLogLevel] is `'info'` (lower than `'warning'`) as default.
  ///
  /// Use it to log something that is not right but its not a big problem.
  ///
  static void warning(
    dynamic message, {
    Object? error,
    StackTrace? stackTrace = StackTrace.empty,
    DateTime? time,
  }) =>
      logger?.warning(
        message,
        error: error,
        stackTrace: stackTrace,
        time: time ?? DateTime.now(),
      );

  /// ERROR (5000)
  ///
  /// High level of logging.
  /// As default this function always working since [envLogLevel] is `'info'` (lower than `'error'`) as default.
  ///
  /// Use it to log errors that did not caused great problems.
  ///
  /// It will send the error to the Crashlytics manager if [upload] is set true as non-fatal error.
  ///
  static void error(
    dynamic message, {
    Object? error,
    required StackTrace? stackTrace,
    DateTime? time,
    bool upload = false,
  }) =>
      logger?.error(
        message,
        error: error,
        stackTrace: stackTrace ?? StackTrace.current,
        time: time ?? DateTime.now(),
        upload: upload,
      );

  /// FATAL (6000)
  ///
  /// Highest level of logging.
  /// As default this function always working since [envLogLevel] is `'info'` (lower than `'fatal'`) as default.
  ///
  /// Use it to log errors that did caused very big problems.
  ///
  /// It will send the error as fatal error (if [sendFatal]) to the Crashlytics manager if possible.
  ///
  static void fatal(
    dynamic message, {
    Object? error,
    required StackTrace? stackTrace,
    DateTime? time,
    bool sendFatal = true,
  }) =>
      logger?.fatal(
        message,
        error: error,
        stackTrace: stackTrace ?? StackTrace.current,
        time: time ?? DateTime.now(),
      );
}

/// The Interface of [Log] class
/// that should be implemented to the new Log concrete classes
/// in order to be used at [Log] interface
abstract class ILogger {
  void trace(
    dynamic message, {
    Object? error,
    StackTrace? stackTrace,
    DateTime? time,
  });

  void debug(
    dynamic message, {
    Object? error,
    StackTrace? stackTrace,
    DateTime? time,
  });

  void info(
    dynamic message, {
    Object? error,
    StackTrace? stackTrace,
    DateTime? time,
  });

  void warning(
    dynamic message, {
    Object? error,
    StackTrace? stackTrace,
    DateTime? time,
  });

  void error(
    dynamic message, {
    Object? error,
    required StackTrace? stackTrace,
    DateTime? time,
    bool upload = false,
  });

  void fatal(
    dynamic message, {
    Object? error,
    required StackTrace? stackTrace,
    DateTime? time,
    bool sendFatal = true,
  });
}
