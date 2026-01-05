/// Command processor for dispatching commands to appropriate handlers.
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

import 'package:markdown_widget_builder/src/utils/command_handlers.dart';
import 'package:markdown_widget_builder/src/utils/command_patterns.dart';
import 'package:markdown_widget_builder/src/utils/command_type_checker.dart';
import 'package:markdown_widget_builder/src/utils/group_processors.dart';
import 'package:markdown_widget_builder/src/utils/placeholder_extractor.dart';

/// Data class for command processing results.

class CommandResult {
  final List<Widget> widgets;
  final String? radioGroupName;
  final List<Map<String, String?>> radioOptions;
  final String? checkboxGroupName;
  final List<Map<String, String?>> checkboxOptions;
  final int? skipToIndex;
  final bool pageBreakOccurred;

  CommandResult({
    required this.widgets,
    required this.radioGroupName,
    required this.radioOptions,
    required this.checkboxGroupName,
    required this.checkboxOptions,
    this.skipToIndex,
    this.pageBreakOccurred = false,
  });
}

/// Dispatches commands to appropriate handlers and builds widgets.

class CommandProcessor {
  final CommandHandlers handlers;
  final GroupProcessors groupProcessors;
  final Map<String, String?> dropdownValues;
  final Map<String, List<String>> dropdownOptions;
  final Widget Function(String command) buildHiddenContent;
  final String Function(String name) getWidgetTypeByName;

  CommandProcessor({
    required this.handlers,
    required this.groupProcessors,
    required this.dropdownValues,
    required this.dropdownOptions,
    required this.buildHiddenContent,
    required this.getWidgetTypeByName,
  });

  /// Processes a single command and returns updated state.

  CommandResult processCommand({
    required String command,
    required String modifiedContent,
    required RegExpMatch match,
    required List<RegExpMatch> matches,
    required int index,
    required PlaceholderData placeholders,
    required String? currentRadioGroupName,
    required List<Map<String, String?>> currentRadioOptions,
    required String? currentCheckboxGroupName,
    required List<Map<String, String?>> currentCheckboxOptions,
    required VoidCallback flushRadioGroup,
    required VoidCallback flushCheckboxGroup,
    required VoidCallback startNewPage,
    required List<Widget> currentPageWidgets,
  }) {
    List<Widget> widgets = List.from(currentPageWidgets);
    String? radioName = currentRadioGroupName;
    List<Map<String, String?>> radioOpts = List.from(currentRadioOptions);
    String? checkboxName = currentCheckboxGroupName;
    List<Map<String, String?>> checkboxOpts = List.from(currentCheckboxOptions);
    int? skipToIndex;
    bool pageBreakOccurred = false;

    if (CommandTypeChecker.isMenuPlaceholder(command)) {
      widgets.add(
        handlers.buildMenuWidget(command, placeholders.menuPlaceholders),
      );
    } else if (CommandTypeChecker.isDescriptionPlaceholder(command)) {
      widgets.add(
        handlers.buildDescriptionWidget(
          command,
          placeholders.descriptionPlaceholders,
        ),
      );
    } else if (CommandTypeChecker.isHeadingPlaceholder(command)) {
      widgets.add(
        handlers.buildHeadingWidget(
          command,
          placeholders.headingPlaceholders,
        ),
      );
    } else if (CommandTypeChecker.isAlignPlaceholder(command)) {
      widgets.add(
        handlers.buildAlignWidget(command, placeholders.alignPlaceholders),
      );
    } else if (CommandTypeChecker.isImageCommand(command)) {
      widgets.add(handlers.buildImageWidget(command));
    } else if (CommandTypeChecker.isVideoCommand(command)) {
      widgets.add(handlers.buildVideoWidget(command));
    } else if (CommandTypeChecker.isAudioCommand(command)) {
      widgets.add(handlers.buildAudioWidget(command));
    } else if (CommandTypeChecker.isTimerCommand(command)) {
      flushRadioGroup();
      flushCheckboxGroup();
      widgets.add(handlers.buildTimerWidget(command));
    } else if (CommandTypeChecker.isEmptyLineCommand(command)) {
      flushRadioGroup();
      flushCheckboxGroup();
      widgets.add(handlers.buildEmptyLine());
    } else if (CommandTypeChecker.isSliderCommand(command)) {
      widgets.add(handlers.buildSliderWidget(command));
    } else if (CommandTypeChecker.isSimpleButtonCommand(command)) {
      flushRadioGroup();
      flushCheckboxGroup();
      widgets.add(handlers.buildSimpleButton(command));
    } else if (CommandTypeChecker.isButtonPlaceholder(command)) {
      flushRadioGroup();
      flushCheckboxGroup();
      widgets.add(
        handlers.buildButtonFromPlaceholder(
          command,
          placeholders.buttonPlaceholders,
          getWidgetTypeByName,
        ),
      );
    } else if (CommandTypeChecker.isHiddenPlaceholder(command)) {
      widgets.add(buildHiddenContent(command));
    } else if (CommandTypeChecker.isRadioCommand(command)) {
      flushCheckboxGroup();
      final result = groupProcessors.processRadioCommand(
        command,
        radioName,
        radioOpts,
        matches,
        index,
        widgets,
        flushRadioGroup,
      );
      radioName = result.groupName;
      radioOpts = result.options;
    } else if (CommandTypeChecker.isCheckboxCommand(command)) {
      flushRadioGroup();
      final result = groupProcessors.processCheckboxCommand(
        command,
        checkboxName,
        checkboxOpts,
        matches,
        index,
        widgets,
        flushCheckboxGroup,
      );
      checkboxName = result.groupName;
      checkboxOpts = result.options;
    } else if (CommandTypeChecker.isCalendarCommand(command)) {
      flushRadioGroup();
      flushCheckboxGroup();
      widgets.add(handlers.buildCalendarWidget(command));
    } else if (CommandTypeChecker.isDropdownCommand(command)) {
      flushRadioGroup();
      flushCheckboxGroup();
      final result = groupProcessors.buildDropdownWidget(
        command,
        modifiedContent,
        match,
        dropdownValues,
        dropdownOptions,
      );
      widgets.add(result.widget);
      skipToIndex = result.endIndex;
    } else if (CommandTypeChecker.isInputSLCommand(command)) {
      flushRadioGroup();
      flushCheckboxGroup();
      widgets.add(handlers.buildInputWidget(command, isMultiLine: false));
    } else if (CommandTypeChecker.isInputMLCommand(command)) {
      flushRadioGroup();
      flushCheckboxGroup();
      widgets.add(handlers.buildInputWidget(command, isMultiLine: true));
    } else if (CommandPatterns.pageBreak.hasMatch(command)) {
      flushRadioGroup();
      flushCheckboxGroup();
      startNewPage();
      widgets = [];
      pageBreakOccurred = true;
    }

    return CommandResult(
      widgets: widgets,
      radioGroupName: radioName,
      radioOptions: radioOpts,
      checkboxGroupName: checkboxName,
      checkboxOptions: checkboxOpts,
      skipToIndex: skipToIndex,
      pageBreakOccurred: pageBreakOccurred,
    );
  }
}
