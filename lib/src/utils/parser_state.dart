/// Parser state management for command parsing.
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

/// Manages parser state variables extracted from the shared state map.

class ParserState {
  final Map<String, dynamic> state;

  late final Map<String, String> inputValues;
  late final Map<String, double> sliderValues;
  late final Map<String, Map<String, dynamic>> sliders;
  late final Map<String, String?> radioValues;
  late final Map<String, Set<String>> checkboxValues;
  late final Map<String, DateTime?> dateValues;
  late final Map<String, String?> dropdownValues;
  late final Map<String, List<String>> dropdownOptions;
  late final Map<String, bool> hiddenContentVisibility;
  late final Map<String, String> hiddenContentMap;
  late final Set<String> requiredWidgets;
  late final Map<String, String> widgetTypeByName;

  ParserState(this.state) {
    _initStateVariables();
  }

  /// Initialises state variables from the shared state map.

  void _initStateVariables() {
    inputValues = state['_inputValues'] as Map<String, String>;
    sliderValues = state['_sliderValues'] as Map<String, double>;
    sliders = state['_sliders'] as Map<String, Map<String, dynamic>>;
    radioValues = state['_radioValues'] as Map<String, String?>;
    checkboxValues = state['_checkboxValues'] as Map<String, Set<String>>;
    dateValues = state['_dateValues'] as Map<String, DateTime?>;
    dropdownValues = state['_dropdownValues'] as Map<String, String?>;
    dropdownOptions = state['_dropdownOptions'] as Map<String, List<String>>;
    hiddenContentVisibility =
        state['_hiddenContentVisibility'] as Map<String, bool>? ?? {};
    hiddenContentMap = state['_hiddenContentMap'] as Map<String, String>? ?? {};
    state['_hiddenContentMap'] = hiddenContentMap;

    requiredWidgets = state['_requiredWidgets'] as Set<String>? ?? {};
    state['_requiredWidgets'] = requiredWidgets;

    widgetTypeByName = {};
  }

  /// Retrieve the widget type name by its identifier.

  String getWidgetTypeByName(String name) {
    return widgetTypeByName[name] ?? '';
  }
}
