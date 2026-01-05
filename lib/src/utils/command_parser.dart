/// Command parser for markdown widgets.
///
// Time-stamp: <Sunday 2024-11-17 21:00:21 +1100 Graham Williams>
///
/// Copyright (C) 2024, Software Innovation Institute, ANU.
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
import 'package:markdown_widget_builder/src/utils/command_processor.dart';
import 'package:markdown_widget_builder/src/utils/group_processors.dart';
import 'package:markdown_widget_builder/src/utils/helpers.dart';
import 'package:markdown_widget_builder/src/utils/parser_state.dart';
import 'package:markdown_widget_builder/src/utils/placeholder_extractor.dart';
import 'package:markdown_widget_builder/src/widgets/markdown_text.dart';

/// The CommandParser class is responsible for parsing markdown-like content and
/// extracting custom commands that build various Flutter widgets.

class CommandParser {
  final BuildContext context;
  final String content;
  final String fullContent;
  final void Function(String title, String content)? onMenuItemSelected;
  final Function? onSubmit;
  final Map<String, dynamic> state;
  final VoidCallback setStateCallback;
  final String surveyTitle;
  final bool isParsingHiddenContent;

  late final Helpers helpers;
  late final ParserState _parserState;
  late final CommandHandlers _handlers;
  late final PlaceholderExtractor _extractor;
  late final GroupProcessors _groupProcessors;
  late final CommandProcessor _processor;

  bool _hasMenu = false;

  /// Constructor for the CommandParser.

  CommandParser({
    required this.context,
    required this.content,
    required this.fullContent,
    this.onMenuItemSelected,
    this.onSubmit,
    required this.state,
    required this.setStateCallback,
    required this.surveyTitle,
    this.isParsingHiddenContent = false,
  }) {
    helpers = Helpers(
      context: context,
      state: state,
      setStateCallback: setStateCallback,
    );
    _parserState = ParserState(state);
    _initHandlers();
  }

  /// Initialises command handlers and placeholder extractor.

  void _initHandlers() {
    _handlers = CommandHandlers(
      context: context,
      fullContent: fullContent,
      onMenuItemSelected: onMenuItemSelected,
      onSubmit: onSubmit,
      state: state,
      setStateCallback: setStateCallback,
      surveyTitle: surveyTitle,
      helpers: helpers,
      sliderValues: _parserState.sliderValues,
      sliders: _parserState.sliders,
      radioValues: _parserState.radioValues,
      checkboxValues: _parserState.checkboxValues,
      dateValues: _parserState.dateValues,
      dropdownValues: _parserState.dropdownValues,
      dropdownOptions: _parserState.dropdownOptions,
      hiddenContentVisibility: _parserState.hiddenContentVisibility,
      hiddenContentMap: _parserState.hiddenContentMap,
      requiredWidgets: _parserState.requiredWidgets,
      widgetTypeByName: _parserState.widgetTypeByName,
      inputValues: _parserState.inputValues,
    );

    _extractor = PlaceholderExtractor(
      state: state,
      hiddenContentMap: _parserState.hiddenContentMap,
      requiredWidgets: _parserState.requiredWidgets,
    );

    _groupProcessors = GroupProcessors(
      radioValues: _parserState.radioValues,
      checkboxValues: _parserState.checkboxValues,
      widgetTypeByName: _parserState.widgetTypeByName,
      helpers: helpers,
      isWidgetRequired: _handlers.isWidgetRequired,
    );

    _processor = CommandProcessor(
      handlers: _handlers,
      groupProcessors: _groupProcessors,
      dropdownValues: _parserState.dropdownValues,
      dropdownOptions: _parserState.dropdownOptions,
      buildHiddenContent: _buildHiddenContent,
      getWidgetTypeByName: _parserState.getWidgetTypeByName,
    );
  }

  /// Parse the markdown content and return pages of widgets.

  List<List<Widget>> parse() {
    List<List<Widget>> pages = [];
    List<Widget> currentPageWidgets = [];

    final placeholders = _extractor.extractPlaceholders(content);
    String modifiedContent = placeholders.modifiedContent;

    _hasMenu = placeholders.menuPlaceholders.isNotEmpty;

    if (_hasMenu && !isParsingHiddenContent) {
      modifiedContent = PlaceholderExtractor.truncateAfterMenu(modifiedContent);
    }

    final matches =
        CommandPatterns.customCommand.allMatches(modifiedContent).toList();
    int lastIndex = 0;

    String? currentRadioGroupName;
    List<Map<String, String?>> currentRadioOptions = [];
    String? currentCheckboxGroupName;
    List<Map<String, String?>> currentCheckboxOptions = [];

    void flushRadioGroup() {
      if (currentRadioGroupName != null) {
        bool isRequired =
            _handlers.isWidgetRequired('Radio', currentRadioGroupName!);
        currentPageWidgets.add(
          helpers.buildRadioGroup(
            currentRadioGroupName!,
            currentRadioOptions,
            isRequired: isRequired,
          ),
        );
        currentRadioGroupName = null;
        currentRadioOptions = [];
      }
    }

    void flushCheckboxGroup() {
      if (currentCheckboxGroupName != null) {
        bool isRequired =
            _handlers.isWidgetRequired('Checkbox', currentCheckboxGroupName!);
        currentPageWidgets.add(
          helpers.buildCheckboxGroup(
            currentCheckboxGroupName!,
            currentCheckboxOptions,
            isRequired: isRequired,
          ),
        );
        currentCheckboxGroupName = null;
        currentCheckboxOptions = [];
      }
    }

    void startNewPage() {
      if (currentPageWidgets.isNotEmpty) {
        pages.add(currentPageWidgets);
      }
      currentPageWidgets = [];
    }

    for (int i = 0; i < matches.length; i++) {
      final match = matches[i];

      if (match.start > lastIndex) {
        String markdownContent =
            modifiedContent.substring(lastIndex, match.start);
        if (markdownContent.trim().isNotEmpty) {
          flushRadioGroup();
          flushCheckboxGroup();
          currentPageWidgets.add(MarkdownText(data: markdownContent));
        }
      }

      String command = match.group(0)!;

      final result = _processor.processCommand(
        command: command,
        modifiedContent: modifiedContent,
        match: match,
        matches: matches,
        index: i,
        placeholders: placeholders,
        currentRadioGroupName: currentRadioGroupName,
        currentRadioOptions: currentRadioOptions,
        currentCheckboxGroupName: currentCheckboxGroupName,
        currentCheckboxOptions: currentCheckboxOptions,
        flushRadioGroup: flushRadioGroup,
        flushCheckboxGroup: flushCheckboxGroup,
        startNewPage: startNewPage,
        currentPageWidgets: currentPageWidgets,
      );

      currentRadioGroupName = result.radioGroupName;
      currentRadioOptions = result.radioOptions;
      currentCheckboxGroupName = result.checkboxGroupName;
      currentCheckboxOptions = result.checkboxOptions;
      currentPageWidgets = result.widgets;

      if (result.skipToIndex != null) {
        lastIndex = result.skipToIndex!;
        continue;
      }

      lastIndex = match.end;
    }

    if (lastIndex < modifiedContent.length) {
      String markdownContent = modifiedContent.substring(lastIndex);
      if (markdownContent.trim().isNotEmpty) {
        flushRadioGroup();
        flushCheckboxGroup();
        if (!_hasMenu || isParsingHiddenContent) {
          currentPageWidgets.add(MarkdownText(data: markdownContent));
        }
      }
    }

    flushRadioGroup();
    flushCheckboxGroup();

    if (currentPageWidgets.isNotEmpty) {
      pages.add(currentPageWidgets);
    }

    return pages;
  }

  Widget _buildHiddenContent(String command) {
    final placeholderMatch =
        CommandPatterns.hiddenPlaceholderExtract.firstMatch(command);
    if (placeholderMatch != null) {
      final id = placeholderMatch.group(1)!.trim();
      final hiddenContent = _parserState.hiddenContentMap[id] ?? '';

      if (!_parserState.hiddenContentVisibility.containsKey(id)) {
        _parserState.hiddenContentVisibility[id] = false;
      }

      final hiddenWidgets = CommandParser(
        context: context,
        content: hiddenContent,
        fullContent: fullContent,
        onMenuItemSelected: onMenuItemSelected,
        onSubmit: onSubmit,
        state: state,
        setStateCallback: setStateCallback,
        surveyTitle: surveyTitle,
        isParsingHiddenContent: true,
      ).parse();

      List<Widget> flattenedHidden = [];
      for (var p in hiddenWidgets) {
        flattenedHidden.addAll(p);
      }

      return Visibility(
        visible: _parserState.hiddenContentVisibility[id] ?? false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: flattenedHidden,
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
