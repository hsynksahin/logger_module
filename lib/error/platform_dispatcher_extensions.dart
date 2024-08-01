// Copyright (c) 2024. All rights reserved.
//
// @author: Hüseyin Küçükşahin
// @last_update: 17.05.2024

/// **Version:** 1.0.0
///
/// Functionality override for [PlatformDispatcher]
///
/// Changes functionality to call multiple registered functions instead of one function.
///
library platform_dispatcher_extensions;

import 'dart:ui' show PlatformDispatcher;

extension PlatformDispatcherExtensions on PlatformDispatcher {
  static bool _set = false;

  // MAYBE (error): Use Map for preventing duplication
  static final List<bool Function(Object, StackTrace)> _handlers = [];

  /// Registers a new function to handle [PlatformDispatcher] Errors.
  ///
  /// Initializes the extension only on first call.
  ///
  /// Caution: Call once per function to prevent duplications. Every function will be called per error.
  static void addHandler(bool Function(Object exception, StackTrace stackTrace) onError) {
    _handlers.add(onError);

    if (_set) {
      PlatformDispatcher.instance.onError = (exception, stackTrace) {
        var flag = false;
        for (var handler in _handlers) {
          if (handler.call(exception, stackTrace)) {
            flag = true;
          }
        }
        return !flag;
      };
      _set = true;
    }
  }
}
