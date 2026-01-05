/// Parsing utilities for command parsing.
///
/// Copyright (C) 2026, Software Innovation Institute, ANU.
///
/// Licensed under the MIT License (the "License").
///
/// License: https://choosealicense.com/licenses/mit/.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
///
/// Authors: Tony Chen

library;

import 'package:flutter/material.dart';

/// Data class for dropdown widget building results.

class DropdownResult {
  final Widget widget;
  final int? endIndex;

  DropdownResult({required this.widget, required this.endIndex});
}

/// Data class for radio/checkbox group processing results.

class GroupResult {
  final String? groupName;
  final List<Map<String, String?>> options;

  GroupResult({required this.groupName, required this.options});
}

/// Processes escape characters in labels.

String processLabel(String label) {
  return label
      .replaceAll(r'\"', '"')
      .replaceAll(r'\(', '(')
      .replaceAll(r'\)', ')')
      .replaceAll('\n', ' ')
      .trim();
}

/// Parse required widgets from content.

List<String> parseRequiredWidgets(String content) {
  final lines = content.split('\n');
  final widgetNames = <String>[];
  for (var line in lines) {
    final trimmedLine = line.trim();
    if (trimmedLine.startsWith('- ')) {
      widgetNames.add(trimmedLine.substring(2).trim());
    } else if (trimmedLine.isNotEmpty) {
      widgetNames.add(trimmedLine);
    }
  }
  return widgetNames;
}

/// Checks if current option is the last in its group.

bool isLastOptionInGroup(
  List<RegExpMatch> matches,
  int index,
  RegExp pattern,
  String name,
) {
  if (index + 1 < matches.length) {
    final nextMatch = matches[index + 1];
    final nextCommand = nextMatch.group(0)!;
    final nextPatternMatch = pattern.firstMatch(nextCommand);
    if (nextPatternMatch != null) {
      final nextName = nextPatternMatch.group(1)!.trim();
      if (nextName.toLowerCase() == name.toLowerCase()) {
        return false;
      }
    }
  }
  return true;
}
