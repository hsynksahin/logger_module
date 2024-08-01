// Copyright (c) 2024. All rights reserved.
//
// @author: Hüseyin Küçükşahin
// @last_update: 17.05.2024

/// **Version:** 1.0.0
///
/// New type of Console Output for `logger` library.
///
/// Made for ANSI character compatibility for both ios & android
///
/// Changes printing function to 'dart:developer' log function
/// and buffering lines to prevent mixing each other.
///
library developer_console_output;

import 'dart:developer' show log;

import 'package:logger/logger.dart' show LogOutput, OutputEvent;

class DeveloperConsoleOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    final StringBuffer buffer = StringBuffer();
    event.lines.forEach(buffer.writeln);
    log(buffer.toString());
  }
}
