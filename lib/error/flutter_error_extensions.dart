// Copyright (c) 2024. All rights reserved.
//
// @author: Hüseyin Küçükşahin
// @last_update: 17.05.2024

/// **Version:** 1.0.0
///
/// Functionality override for [FlutterError]
///
/// Changes functionality to call multiple registered functions instead of one function.
///
library flutter_error_extensions;

import 'package:flutter/material.dart' show FlutterError, FlutterErrorDetails;

extension FlutterErrorExtensions on FlutterError {
  static const defaultPresent = bool.fromEnvironment('errorDefaultPresent', defaultValue: true);

  static bool _set = false;
  static final List<void Function(FlutterErrorDetails)> _handlers = [];

  /// Registers a new function to handle Flutter Errors.
  ///
  /// Initializes the extension only on first call.
  ///
  /// Caution: Call once per function to prevent duplications. Every function will be called per error.
  static void addHandler(void Function(FlutterErrorDetails details) onError) {
    _handlers.add(onError);
    if (!_set) {
      if (defaultPresent) {
        FlutterError.onError = (details) {
          FlutterError.dumpErrorToConsole(details);
          for (var handler in _handlers) {
            handler.call(details);
          }
        };
      } else {
        FlutterError.onError = (details) {
          for (var handler in _handlers) {
            handler.call(details);
          }
        };
      }
      _set = true;
    }
  }
}
