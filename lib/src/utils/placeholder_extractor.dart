/// Placeholder extraction utilities for command parsing.
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

import 'package:markdown_widget_builder/src/utils/command_handlers.dart';
import 'package:markdown_widget_builder/src/utils/command_patterns.dart';

/// Data class for placeholder extraction results.

class PlaceholderData {
  final String modifiedContent;
  final Map<String, String> menuPlaceholders;
  final Map<String, Map<String, String>> buttonPlaceholders;
  final Map<String, String> descriptionPlaceholders;
  final Map<String, Map<String, String>> headingPlaceholders;
  final Map<String, Map<String, String>> alignPlaceholders;

  PlaceholderData({
    required this.modifiedContent,
    required this.menuPlaceholders,
    required this.buttonPlaceholders,
    required this.descriptionPlaceholders,
    required this.headingPlaceholders,
    required this.alignPlaceholders,
  });
}

/// Extracts and manages placeholders from markdown content.

class PlaceholderExtractor {
  final Map<String, dynamic> state;
  final Map<String, String> hiddenContentMap;
  final Set<String> requiredWidgets;

  PlaceholderExtractor({
    required this.state,
    required this.hiddenContentMap,
    required this.requiredWidgets,
  });

  /// Extracts all placeholders from the content.

  PlaceholderData extractPlaceholders(String content) {
    String modified = content;
    final menuPlaceholders = <String, String>{};
    final buttonPlaceholders = <String, Map<String, String>>{};
    final descriptionPlaceholders = <String, String>{};
    final headingPlaceholders = <String, Map<String, String>>{};
    final alignPlaceholders = <String, Map<String, String>>{};

    // Extract hidden blocks.

    modified = _extractHiddenBlocks(modified);

    // Extract menu blocks.

    int menuIndex = 0;
    modified = modified.replaceAllMapped(CommandPatterns.menuBlock, (match) {
      String placeholder = '%%MenuPlaceholder$menuIndex%%';
      menuPlaceholders[placeholder] = match.group(1)!;
      menuIndex++;
      return placeholder;
    });

    // Extract button blocks.

    int buttonIndex = 0;
    modified = modified.replaceAllMapped(CommandPatterns.buttonBlock, (match) {
      String placeholder = '%%ButtonPlaceholder$buttonIndex%%';
      buttonPlaceholders[placeholder] = {
        'command': match.group(1)!,
        'requiredWidgets': match.group(2)!,
      };
      List<String> reqWidgets = parseRequiredWidgets(match.group(2)!);
      requiredWidgets.addAll(reqWidgets);
      state['_requiredWidgets'] = requiredWidgets;
      buttonIndex++;
      return placeholder;
    });

    // Extract description blocks.

    int descriptionIndex = 0;
    modified =
        modified.replaceAllMapped(CommandPatterns.descriptionBlock, (match) {
      String placeholder = '%%DescriptionPlaceholder$descriptionIndex%%';
      descriptionPlaceholders[placeholder] = match.group(1)!;
      descriptionIndex++;
      return placeholder;
    });

    // Extract heading blocks.

    int headingIndex = 0;
    modified =
        modified.replaceAllMapped(CommandPatterns.headingAlignBlock, (match) {
      String placeholder = '%%HeadingPlaceholder$headingIndex%%';
      headingPlaceholders[placeholder] = {
        'level': match.group(1)!,
        'align': match.group(2) ?? 'Left',
        'content': match.group(3)!,
      };
      headingIndex++;
      return placeholder;
    });

    // Extract align blocks.

    int alignIndex = 0;
    modified = modified.replaceAllMapped(CommandPatterns.alignBlock, (match) {
      String placeholder = '%%AlignPlaceholder$alignIndex%%';
      alignPlaceholders[placeholder] = {
        'align': match.group(1)!,
        'content': match.group(2)!,
      };
      alignIndex++;
      return placeholder;
    });

    return PlaceholderData(
      modifiedContent: modified,
      menuPlaceholders: menuPlaceholders,
      buttonPlaceholders: buttonPlaceholders,
      descriptionPlaceholders: descriptionPlaceholders,
      headingPlaceholders: headingPlaceholders,
      alignPlaceholders: alignPlaceholders,
    );
  }

  /// Extracts hidden blocks and replaces them with placeholders.

  String _extractHiddenBlocks(String content) {
    String modified = content;

    modified = modified.replaceAllMapped(CommandPatterns.hiddenBlock, (match) {
      String id = match.group(1)!.trim();
      String c = match.group(2)!;
      hiddenContentMap[id] = c;
      state['_hiddenContentMap'] = hiddenContentMap;
      return '%%HiddenPlaceholder($id)%%';
    });

    modified =
        modified.replaceAllMapped(CommandPatterns.hiddenPlaceholder, (match) {
      String id = match.group(1)!.trim();
      return '%%HiddenPlaceholder($id)%%';
    });

    return modified;
  }

  /// Truncates content after the first menu placeholder.

  static String truncateAfterMenu(String content) {
    final menuMatch = CommandPatterns.menuPlaceholder.firstMatch(content);
    if (menuMatch != null) {
      return content.substring(0, menuMatch.end);
    }
    return content;
  }
}
