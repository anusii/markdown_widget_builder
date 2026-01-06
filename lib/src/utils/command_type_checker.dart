/// Command type checking utilities for markdown widget parsing.
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

/// Utility class for checking command types in markdown parsing.

class CommandTypeChecker {
  /// Checks if the command is a menu placeholder.

  static bool isMenuPlaceholder(String cmd) =>
      cmd.startsWith(RegExp(r'%%MenuPlaceholder', caseSensitive: false));

  /// Checks if the command is a description placeholder.

  static bool isDescriptionPlaceholder(String cmd) =>
      cmd.startsWith(RegExp(r'%%DescriptionPlaceholder', caseSensitive: false));

  /// Checks if the command is a heading placeholder.

  static bool isHeadingPlaceholder(String cmd) =>
      cmd.startsWith(RegExp(r'%%HeadingPlaceholder', caseSensitive: false));

  /// Checks if the command is an align placeholder.

  static bool isAlignPlaceholder(String cmd) =>
      cmd.startsWith(RegExp(r'%%AlignPlaceholder', caseSensitive: false));

  /// Checks if the command is an image command.

  static bool isImageCommand(String cmd) =>
      cmd.startsWith(RegExp(r'%% Image', caseSensitive: false));

  /// Checks if the command is a video command.

  static bool isVideoCommand(String cmd) =>
      cmd.startsWith(RegExp(r'%% Video', caseSensitive: false));

  /// Checks if the command is an audio command.

  static bool isAudioCommand(String cmd) =>
      cmd.startsWith(RegExp(r'%% Audio', caseSensitive: false));

  /// Checks if the command is a timer command.

  static bool isTimerCommand(String cmd) =>
      cmd.startsWith(RegExp(r'%% Timer', caseSensitive: false));

  /// Checks if the command is an empty line command.

  static bool isEmptyLineCommand(String cmd) =>
      cmd.startsWith(RegExp(r'%% EmptyLine', caseSensitive: false));

  /// Checks if the command is a slider command.

  static bool isSliderCommand(String cmd) =>
      cmd.startsWith(RegExp(r'%% Slider', caseSensitive: false));

  /// Checks if the command is a simple button command.

  static bool isSimpleButtonCommand(String cmd) => cmd.startsWith('%% Button');

  /// Checks if the command is a button placeholder.

  static bool isButtonPlaceholder(String cmd) =>
      cmd.startsWith(RegExp(r'%%ButtonPlaceholder', caseSensitive: false));

  /// Checks if the command is a hidden placeholder.

  static bool isHiddenPlaceholder(String cmd) =>
      cmd.startsWith(RegExp(r'%%HiddenPlaceholder', caseSensitive: false));

  /// Checks if the command is a radio command.

  static bool isRadioCommand(String cmd) =>
      cmd.startsWith(RegExp(r'%% Radio', caseSensitive: false));

  /// Checks if the command is a checkbox command.

  static bool isCheckboxCommand(String cmd) =>
      cmd.startsWith(RegExp(r'%% Checkbox', caseSensitive: false));

  /// Checks if the command is a calendar command.

  static bool isCalendarCommand(String cmd) =>
      cmd.startsWith(RegExp(r'%% Calendar', caseSensitive: false));

  /// Checks if the command is a dropdown command.

  static bool isDropdownCommand(String cmd) =>
      cmd.startsWith(RegExp(r'%% Dropdown', caseSensitive: false));

  /// Checks if the command is a single-line input command.

  static bool isInputSLCommand(String cmd) =>
      cmd.startsWith(RegExp(r'%% InputSL', caseSensitive: false));

  /// Checks if the command is a multi-line input command.

  static bool isInputMLCommand(String cmd) =>
      cmd.startsWith(RegExp(r'%% InputML', caseSensitive: false));
}
