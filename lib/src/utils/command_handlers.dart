/// Command handlers for markdown widget parsing.
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
import 'package:markdown_widget_builder/src/utils/media_widget_builders.dart';
import 'package:markdown_widget_builder/src/utils/parsing_utils.dart';
import 'package:markdown_widget_builder/src/widgets/button_widget.dart';
import 'package:markdown_widget_builder/src/widgets/menu_widget.dart';

// Re-export parsing utilities for backwards compatibility.

export 'package:markdown_widget_builder/src/utils/parsing_utils.dart';

/// Handles building individual widgets from parsed commands.

class CommandHandlers {
  final BuildContext context;
  final String fullContent;
  final void Function(String title, String content)? onMenuItemSelected;
  final Function? onSubmit;
  final Map<String, dynamic> state;
  final VoidCallback setStateCallback;
  final String surveyTitle;
  final Helpers helpers;

  // State maps.

  final Map<String, double> sliderValues;
  final Map<String, Map<String, dynamic>> sliders;
  final Map<String, String?> radioValues;
  final Map<String, Set<String>> checkboxValues;
  final Map<String, DateTime?> dateValues;
  final Map<String, String?> dropdownValues;
  final Map<String, List<String>> dropdownOptions;
  final Map<String, bool> hiddenContentVisibility;
  final Map<String, String> hiddenContentMap;
  final Set<String> requiredWidgets;
  final Map<String, String> widgetTypeByName;
  final Map<String, String> inputValues;

  late final MediaWidgetBuilders _mediaBuilders;

  CommandHandlers({
    required this.context,
    required this.fullContent,
    this.onMenuItemSelected,
    this.onSubmit,
    required this.state,
    required this.setStateCallback,
    required this.surveyTitle,
    required this.helpers,
    required this.sliderValues,
    required this.sliders,
    required this.radioValues,
    required this.checkboxValues,
    required this.dateValues,
    required this.dropdownValues,
    required this.dropdownOptions,
    required this.hiddenContentVisibility,
    required this.hiddenContentMap,
    required this.requiredWidgets,
    required this.widgetTypeByName,
    required this.inputValues,
  }) {
    _mediaBuilders = MediaWidgetBuilders(context: context, helpers: helpers);
  }

  /// Builds a menu widget from placeholder.

  Widget buildMenuWidget(String cmd, Map<String, String> placeholders) {
    String menuContent = placeholders[cmd]!;
    return MenuWidget(
      menuContent: menuContent,
      fullContent: fullContent,
      onMenuItemSelected: (title, surveyContent) {
        onMenuItemSelected?.call(title, surveyContent);
      },
    );
  }

  /// Builds a description widget from placeholder.

  Widget buildDescriptionWidget(String cmd, Map<String, String> placeholders) {
    String descriptionContent = placeholders[cmd]!;
    return helpers.buildDescriptionBox(descriptionContent, isRequired: false);
  }

  /// Builds a heading widget from placeholder.

  Widget buildHeadingWidget(
    String cmd,
    Map<String, Map<String, String>> placeholders,
  ) {
    final info = placeholders[cmd]!;
    final level = int.parse(info['level']!);
    final align = info['align']!;
    final content = info['content']!;
    return helpers.buildHeading(level, content, align, isRequired: false);
  }

  /// Builds an aligned text widget from placeholder.

  Widget buildAlignWidget(
    String cmd,
    Map<String, Map<String, String>> placeholders,
  ) {
    final info = placeholders[cmd]!;
    return helpers.buildAlignedText(
      info['align']!,
      info['content']!,
      isRequired: false,
    );
  }

  /// Builds an image widget from command.

  Widget buildImageWidget(String command) =>
      _mediaBuilders.buildImageWidget(command);

  /// Builds a video widget from command.

  Widget buildVideoWidget(String command) =>
      _mediaBuilders.buildVideoWidget(command);

  /// Builds an audio widget from command.

  Widget buildAudioWidget(String command) =>
      _mediaBuilders.buildAudioWidget(command);

  /// Builds a timer widget from command.

  Widget buildTimerWidget(String command) =>
      _mediaBuilders.buildTimerWidget(command);

  /// Builds an empty line widget.

  Widget buildEmptyLine() => _mediaBuilders.buildEmptyLine();

  /// Builds a slider widget from command.

  Widget buildSliderWidget(String command) {
    final sliderMatch = CommandPatterns.slider.firstMatch(command);
    if (sliderMatch != null) {
      final name = sliderMatch.group(1)!.trim();
      final min = double.parse(sliderMatch.group(2)!);
      final max = double.parse(sliderMatch.group(3)!);
      final defaultValue = double.parse(sliderMatch.group(4)!);
      final step = double.parse(sliderMatch.group(5)!);

      sliders[name] = {
        'min': min,
        'max': max,
        'defaultValue': defaultValue,
        'step': step,
      };

      if (!sliderValues.containsKey(name)) {
        sliderValues[name] = defaultValue;
      }

      bool isRequired = isWidgetRequired('Slider', name);
      widgetTypeByName[name] = 'Slider';
      return helpers.buildSlider(name, isRequired: isRequired);
    }
    return const SizedBox.shrink();
  }

  /// Builds a simple button widget from command.

  Widget buildSimpleButton(String command) {
    return ButtonWidget(
      command: command,
      requiredWidgets: const [],
      state: state,
      surveyTitle: surveyTitle,
      onSubmit: onSubmit,
    );
  }

  /// Builds a button widget from placeholder.

  Widget buildButtonFromPlaceholder(
    String cmd,
    Map<String, Map<String, String>> placeholders,
    String Function(String) getWidgetTypeByName,
  ) {
    final buttonInfo = placeholders[cmd]!;
    final commandStr = buttonInfo['command']!;
    final requiredWidgetsStr = buttonInfo['requiredWidgets']!;
    List<String> reqWidgets = parseRequiredWidgets(requiredWidgetsStr);

    reqWidgets = reqWidgets
        .where(
          (name) => allowedRequiredTypes.contains(getWidgetTypeByName(name)),
        )
        .toList();

    return ButtonWidget(
      command: '%% Button($commandStr)',
      requiredWidgets: reqWidgets,
      state: state,
      surveyTitle: surveyTitle,
      onSubmit: onSubmit,
    );
  }

  /// Builds a calendar widget from command.

  Widget buildCalendarWidget(String command) {
    final calendarMatch = CommandPatterns.calendar.firstMatch(command);
    if (calendarMatch != null) {
      final name = calendarMatch.group(1)!.trim();
      if (!dateValues.containsKey(name)) {
        dateValues[name] = null;
      }
      bool isRequired = isWidgetRequired('Calendar', name);
      widgetTypeByName[name] = 'Calendar';
      return helpers.buildCalendarField(name, isRequired: isRequired);
    }
    return const SizedBox.shrink();
  }

  /// Builds an input widget from command.

  Widget buildInputWidget(String command, {required bool isMultiLine}) {
    final pattern =
        isMultiLine ? CommandPatterns.inputML : CommandPatterns.inputSL;
    final inputMatch = pattern.firstMatch(command);
    if (inputMatch != null) {
      final name = inputMatch.group(1)!.trim();
      if (!inputValues.containsKey(name)) {
        inputValues[name] = '';
      }
      final type = isMultiLine ? 'InputML' : 'InputSL';
      bool isRequired = isWidgetRequired(type, name);
      widgetTypeByName[name] = type;
      return helpers.buildInputField(
        name,
        isMultiLine: isMultiLine,
        isRequired: isRequired,
      );
    }
    return const SizedBox.shrink();
  }

  /// Check if a widget is required.

  bool isWidgetRequired(String type, String name) {
    return allowedRequiredTypes.contains(type) &&
        requiredWidgets.contains(name);
  }
}
