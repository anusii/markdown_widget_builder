/// Validation utilities for the button widget.
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

/// Handles validation of required widgets.

class ButtonValidator {
  final Map<String, dynamic> state;
  final List<String> requiredWidgets;
  final BuildContext context;

  const ButtonValidator({
    required this.state,
    required this.requiredWidgets,
    required this.context,
  });

  /// Validates that all required widgets have values.
  ///
  /// Returns true if all required widgets are filled, false otherwise.

  bool validateRequiredWidgets() {
    bool isValid = true;
    List<String> invalidWidgets = [];

    for (String widgetName in requiredWidgets) {
      bool widgetHasValue = _checkWidgetHasValue(widgetName);

      if (!widgetHasValue) {
        isValid = false;
        invalidWidgets.add(widgetName);
        _setValidationError(widgetName, true);
      } else {
        _setValidationError(widgetName, false);
      }
    }

    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all required fields: '
              '${invalidWidgets.join(', ')}'),
        ),
      );
    }

    return isValid;
  }

  /// Checks if a widget has a valid value.

  bool _checkWidgetHasValue(String widgetName) {
    // Check in _inputValues.

    if (state['_inputValues'][widgetName]?.trim().isNotEmpty ?? false) {
      return true;
    }

    // Check in _sliderValues.

    if (state['_sliderValues'][widgetName] != null) {
      return true;
    }

    // Check in _radioValues.

    if (state['_radioValues'][widgetName]?.trim().isNotEmpty ?? false) {
      return true;
    }

    // Check in _checkboxValues.

    if (state['_checkboxValues'][widgetName]?.isNotEmpty ?? false) {
      return true;
    }

    // Check in _dateValues.

    if (state['_dateValues'][widgetName] != null) {
      return true;
    }

    // Check in _dropdownValues.

    if (state['_dropdownValues'][widgetName]?.trim().isNotEmpty ?? false) {
      return true;
    }
    return false;
  }

  /// Sets the validation error state for a widget.

  void _setValidationError(String widgetName, bool hasError) {
    _setErrorForKey('_inputFieldKeys', widgetName, hasError);
    _setErrorForKey('_radioGroupKeys', widgetName, hasError);
    _setErrorForKey('_checkboxGroupKeys', widgetName, hasError);
    _setErrorForKey('_calendarFieldKeys', widgetName, hasError);
    _setErrorForKey('_dropdownKeys', widgetName, hasError);
    _setErrorForKey('_sliderKeys', widgetName, hasError);
  }

  /// Helper to set error on a specific widget key.

  void _setErrorForKey(String keyMapName, String widgetName, bool hasError) {
    if (state[keyMapName] != null && state[keyMapName][widgetName] != null) {
      final key = state[keyMapName][widgetName];
      key.currentState?.setValidationError(hasError);
    }
  }
}
