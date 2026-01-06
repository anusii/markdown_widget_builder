/// Button widget.
///
// Time-stamp: <Tuesday 2024-12-03 07:28:21 +1100 Graham Williams>
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

import 'package:markdown_widget_builder/src/constants/pkg.dart';
import 'package:markdown_widget_builder/src/widgets/button_data_handler.dart';
import 'package:markdown_widget_builder/src/widgets/button_validator.dart';

/// A button widget that handles form submission and data saving.

class ButtonWidget extends StatefulWidget {
  final String command;
  final List<String> requiredWidgets;
  final Map<String, dynamic> state;
  final String surveyTitle;
  final Function? onSubmit;

  const ButtonWidget({
    super.key,
    required this.command,
    required this.requiredWidgets,
    required this.state,
    required this.surveyTitle,
    this.onSubmit,
  });

  @override
  State<ButtonWidget> createState() => _ButtonWidgetState();
}

class _ButtonWidgetState extends State<ButtonWidget> {
  late final String buttonText;
  late final int actionType;
  late final String actionParameter;
  late TextEditingController _filenameController;

  late final ButtonDataCollector _dataCollector;
  late ButtonValidator _validator;
  late ButtonDataSaver _dataSaver;

  @override
  void initState() {
    super.initState();
    _parseCommand();
    _filenameController = TextEditingController(
      text: ButtonDataSaver.generateFilename(widget.surveyTitle),
    );
    _dataCollector = ButtonDataCollector(widget.state);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _validator = ButtonValidator(
      state: widget.state,
      requiredWidgets: widget.requiredWidgets,
      context: context,
    );
    _dataSaver = ButtonDataSaver(
      context: context,
      filenameController: _filenameController,
    );
  }

  void _parseCommand() {
    final buttonExp = RegExp(r'%% Button\((.+)\)', caseSensitive: false);
    final buttonMatch = buttonExp.firstMatch(widget.command);

    if (buttonMatch != null) {
      final argsString = buttonMatch.group(1)!;
      final args = parseButtonArguments(argsString);

      if (args.isNotEmpty) {
        buttonText = args.isNotEmpty ? args[0] : defaultButtonText;
        actionType = args.length > 1 ? int.tryParse(args[1]) ?? 0 : 0;
        actionParameter = args.length > 2 ? args[2] : defaultFileName;
      } else {
        buttonText = defaultButtonText;
        actionType = 0;
        actionParameter = defaultFileName;
      }
    } else {
      buttonText = defaultButtonText;
      actionType = 0;
      actionParameter = defaultFileName;
    }
  }

  Future<void> _handleButtonPress() async {
    if (!_validator.validateRequiredWidgets()) {
      return;
    }

    final data = _dataCollector.collectData();

    if (actionType == 0) {
      // Save the data locally as a JSON file.

      await _dataSaver.saveDataLocally(data, widget.surveyTitle);
    } else if (actionType == 1) {
      // Submit the data to a URL.

      await _dataSaver.submitDataToUrl(data, actionParameter);
    } else if (actionType == 2) {
      // Call the custom onSubmit function.

      widget.onSubmit!(data);
    } else {
      // Invalid action type.

      _showInvalidActionTypeMessage();
    }
  }

  void _showInvalidActionTypeMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invalid action type')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: _handleButtonPress,
        child: Text(buttonText),
      ),
    );
  }
}
