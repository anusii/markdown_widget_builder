/// Group processors for radio and checkbox commands.
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

import 'package:markdown_widget_builder/src/utils/command_patterns.dart';
import 'package:markdown_widget_builder/src/utils/helpers.dart';
import 'package:markdown_widget_builder/src/utils/parsing_utils.dart';

/// Processor for radio and checkbox group commands.

class GroupProcessors {
  final Map<String, String?> radioValues;
  final Map<String, Set<String>> checkboxValues;
  final Map<String, String> widgetTypeByName;
  final Helpers helpers;
  final bool Function(String type, String name) isWidgetRequired;

  GroupProcessors({
    required this.radioValues,
    required this.checkboxValues,
    required this.widgetTypeByName,
    required this.helpers,
    required this.isWidgetRequired,
  });

  /// Processes a radio command and updates group state.

  GroupResult processRadioCommand(
    String command,
    String? currentGroupName,
    List<Map<String, String?>> currentOptions,
    List<RegExpMatch> matches,
    int index,
    List<Widget> widgets,
    VoidCallback flushGroup,
  ) {
    final radioMatch = CommandPatterns.radio.firstMatch(command);
    if (radioMatch != null) {
      final name = radioMatch.group(1)!.trim();
      final value = radioMatch.group(2)!.trim();
      String label = processLabel(radioMatch.group(3)!);
      String? hiddenContentId = radioMatch.group(4)?.trim();

      String? groupName = currentGroupName;
      List<Map<String, String?>> options = List.from(currentOptions);

      if (groupName == null || groupName != name) {
        if (groupName != null) flushGroup();
        groupName = name;
        options = [];
        if (!radioValues.containsKey(name)) {
          radioValues[name] = null;
        }
        widgetTypeByName[name] = 'Radio';
      }

      options.add({
        'value': value,
        'label': label,
        'hiddenContentId': hiddenContentId,
      });

      if (isLastOptionInGroup(matches, index, CommandPatterns.radio, name)) {
        bool isRequired = isWidgetRequired('Radio', name);
        widgets.add(
          helpers.buildRadioGroup(name, options, isRequired: isRequired),
        );
        return GroupResult(groupName: null, options: []);
      }

      return GroupResult(groupName: groupName, options: options);
    }
    return GroupResult(groupName: currentGroupName, options: currentOptions);
  }

  /// Processes a checkbox command and updates group state.

  GroupResult processCheckboxCommand(
    String command,
    String? currentGroupName,
    List<Map<String, String?>> currentOptions,
    List<RegExpMatch> matches,
    int index,
    List<Widget> widgets,
    VoidCallback flushGroup,
  ) {
    final checkboxMatch = CommandPatterns.checkbox.firstMatch(command);
    if (checkboxMatch != null) {
      final name = checkboxMatch.group(1)!.trim();
      final value = checkboxMatch.group(2)!.trim();
      String label = processLabel(checkboxMatch.group(3)!);
      String? hiddenContentId = checkboxMatch.group(4)?.trim();

      String? groupName = currentGroupName;
      List<Map<String, String?>> options = List.from(currentOptions);

      if (groupName == null || groupName != name) {
        if (groupName != null) flushGroup();
        groupName = name;
        options = [];
        if (!checkboxValues.containsKey(name)) {
          checkboxValues[name] = {};
        }
        widgetTypeByName[name] = 'Checkbox';
      }

      options.add({
        'value': value,
        'label': label,
        'hiddenContentId': hiddenContentId,
      });

      if (isLastOptionInGroup(matches, index, CommandPatterns.checkbox, name)) {
        bool isRequired = isWidgetRequired('Checkbox', name);
        widgets.add(
          helpers.buildCheckboxGroup(name, options, isRequired: isRequired),
        );
        return GroupResult(groupName: null, options: []);
      }

      return GroupResult(groupName: groupName, options: options);
    }
    return GroupResult(groupName: currentGroupName, options: currentOptions);
  }

  /// Builds a dropdown widget and returns the end index for skipping content.

  DropdownResult buildDropdownWidget(
    String command,
    String modifiedContent,
    RegExpMatch match,
    Map<String, String?> dropdownValues,
    Map<String, List<String>> dropdownOptions,
  ) {
    final dropdownMatch = CommandPatterns.dropdown.firstMatch(command);
    if (dropdownMatch != null) {
      final name = dropdownMatch.group(1)!.trim();
      if (!dropdownValues.containsKey(name)) {
        dropdownValues[name] = null;
      }
      if (!dropdownOptions.containsKey(name)) {
        dropdownOptions[name] = [];
      }

      int optionsStartIndex = match.end;
      final lines = modifiedContent.substring(optionsStartIndex).split('\n');
      final List<String> options = [];
      int lineOffset = 0;

      for (var line in lines) {
        final trimmedLine = line.trim();
        if (trimmedLine.startsWith('- ')) {
          options.add(trimmedLine.substring(2).trim());
          lineOffset += line.length + 1;
        } else if (trimmedLine.isEmpty) {
          lineOffset += line.length + 1;
        } else {
          break;
        }
      }

      dropdownOptions[name] = options;
      bool isRequired = isWidgetRequired('Dropdown', name);
      widgetTypeByName[name] = 'Dropdown';

      return DropdownResult(
        widget: helpers.buildDropdown(name, options, isRequired: isRequired),
        endIndex: optionsStartIndex + lineOffset,
      );
    }
    return DropdownResult(widget: const SizedBox.shrink(), endIndex: null);
  }
}
