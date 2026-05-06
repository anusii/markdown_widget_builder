/// Data handling utilities for the button widget.
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

import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;

import 'package:markdown_widget_builder/src/utils/command_patterns.dart';
import 'package:markdown_widget_builder/src/widgets/button_file_saver.dart'
    as file_saver;

/// Handles data collection from widget state.

class ButtonDataCollector {
  final Map<String, dynamic> state;

  const ButtonDataCollector(this.state);

  /// Collects all user responses from the state map.

  Map<String, dynamic> collectData() {
    final Map<String, dynamic> responses = {};

    final inputValues = state['_inputValues'] as Map<String, String>;
    final sliderValues = state['_sliderValues'] as Map<String, double>;
    final radioValues = state['_radioValues'] as Map<String, String?>;
    final checkboxValues = state['_checkboxValues'] as Map<String, Set<String>>;
    final dateValues = state['_dateValues'] as Map<String, DateTime?>;
    final dropdownValues = state['_dropdownValues'] as Map<String, String?>;

    // Compute the set of widget names that belong to hidden sections which
    // are not currently visible. Such widgets are dropped from the response
    // because the user never had a chance to interact with them.

    final excluded = _collectHiddenWidgetNames();

    // Add slider values.

    sliderValues.forEach((key, value) {
      if (excluded.contains(key)) return;
      responses[key] = value;
    });

    // Add radio values, skipping unanswered ones.

    radioValues.forEach((key, value) {
      if (excluded.contains(key)) return;
      if (value == null) return;
      responses[key] = value;
    });

    // Add checkbox values (convert Set to List).

    checkboxValues.forEach((key, value) {
      if (excluded.contains(key)) return;
      responses[key] = value.toList();
    });

    // Add date values, skipping unanswered ones.

    dateValues.forEach((key, value) {
      if (excluded.contains(key)) return;
      if (value == null) return;
      responses[key] =
          '${value.year}-${value.month.toString().padLeft(2, '0')}-'
          '${value.day.toString().padLeft(2, '0')}';
    });

    // Add dropdown values, skipping unanswered ones.

    dropdownValues.forEach((key, value) {
      if (excluded.contains(key)) return;
      if (value == null) return;
      responses[key] = value;
    });

    // Add text input values.

    inputValues.forEach((key, value) {
      if (excluded.contains(key)) return;
      responses[key] = value;
    });

    return responses;
  }

  /// Returns the set of widget names that should be omitted from the
  /// response because they sit inside hidden sections that are not
  /// currently visible.
  ///
  /// Hidden sections are identified by their id in the
  /// `_hiddenContentMap`. The corresponding visibility flag in
  /// `_hiddenContentVisibility` indicates whether the user has revealed
  /// the section. Nested hidden sections are followed transitively, so a
  /// widget inside a hidden section that is itself nested in another
  /// invisible section is still excluded.

  Set<String> _collectHiddenWidgetNames() {
    final hiddenContentMap =
        (state['_hiddenContentMap'] as Map<String, String>?) ?? const {};
    final hiddenContentVisibility =
        (state['_hiddenContentVisibility'] as Map<String, bool>?) ?? const {};

    if (hiddenContentMap.isEmpty) return const <String>{};

    final excluded = <String>{};

    hiddenContentMap.forEach((id, content) {
      final visible = hiddenContentVisibility[id] ?? false;
      if (visible) return;
      excluded.addAll(_extractWidgetNames(content, hiddenContentMap));
    });

    return excluded;
  }

  /// Extracts the names of every named widget defined in [content]. When
  /// [content] references other hidden sections via
  /// `%%HiddenPlaceholder(id)%%`, those sections are recursively expanded
  /// using [hiddenContentMap] so that nested widgets are captured too.

  Set<String> _extractWidgetNames(
    String content,
    Map<String, String> hiddenContentMap, {
    Set<String>? visited,
  }) {
    final seen = visited ?? <String>{};
    final names = <String>{};

    // Capture widget names defined directly inside this content.

    void addFirstGroup(RegExp pattern) {
      for (final m in pattern.allMatches(content)) {
        final name = m.group(1)?.trim();
        if (name != null && name.isNotEmpty) names.add(name);
      }
    }

    addFirstGroup(CommandPatterns.radio);
    addFirstGroup(CommandPatterns.checkbox);
    addFirstGroup(CommandPatterns.slider);
    addFirstGroup(CommandPatterns.inputSL);
    addFirstGroup(CommandPatterns.inputML);
    addFirstGroup(CommandPatterns.calendar);
    addFirstGroup(CommandPatterns.dropdown);

    // Recurse into any nested hidden sections referenced by placeholder.

    for (final m in CommandPatterns.hiddenPlaceholderExtract.allMatches(
      content,
    )) {
      final id = m.group(1)?.trim();
      if (id == null || id.isEmpty || seen.contains(id)) continue;
      seen.add(id);
      final nested = hiddenContentMap[id];
      if (nested == null) continue;
      names.addAll(
        _extractWidgetNames(nested, hiddenContentMap, visited: seen),
      );
    }

    return names;
  }
}

/// Handles saving and submitting data.

class ButtonDataSaver {
  final BuildContext context;
  final TextEditingController filenameController;

  const ButtonDataSaver({
    required this.context,
    required this.filenameController,
  });

  /// Saves data locally as a JSON file.

  Future<void> saveDataLocally(
    Map<String, dynamic> data,
    String surveyTitle,
  ) async {
    await file_saver.saveDataLocally(
      context,
      data,
      surveyTitle,
      filenameController,
    );
  }

  /// Submits data to a URL via HTTP POST.

  Future<void> submitDataToUrl(
    Map<String, dynamic> data,
    String url,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Submission successful')),
        );
      } else {
        debugPrint('Response body: ${response.body}');
        messenger.showSnackBar(
          SnackBar(
            content: Text('Submission failed: ${response.statusCode} '
                '${response.reasonPhrase}'),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Submission failed: $e');
      debugPrint('Stack trace: $stackTrace');
      messenger.showSnackBar(
        SnackBar(
          content: Text('Submission failed: $e. '
              'Did you set up the online submission correctly?'),
        ),
      );
    }
  }

  /// Generates a filename based on the survey title.

  static String generateFilename(String title) {
    return file_saver.generateFilename(title);
  }
}

/// Parses command arguments from a string.

List<String> parseButtonArguments(String argsString) {
  final args = <String>[];
  final buffer = StringBuffer();
  bool inQuotes = false;
  String quoteChar = '';

  for (int i = 0; i < argsString.length; i++) {
    final char = argsString[i];

    if (char == '\'' || char == '"') {
      if (inQuotes && char == quoteChar) {
        inQuotes = false;
      } else if (!inQuotes) {
        inQuotes = true;
        quoteChar = char;
      }
      continue;
    }

    if (char == ',' && !inQuotes) {
      args.add(buffer.toString().trim());
      buffer.clear();
    } else {
      buffer.write(char);
    }
  }
  if (buffer.isNotEmpty) {
    args.add(buffer.toString().trim());
  }

  return args;
}
