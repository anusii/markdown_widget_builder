/// Command patterns for markdown widget parsing.
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

/// Regular expression patterns used for parsing markdown commands.
///
/// These patterns are used by [CommandParser] to identify and extract
/// various custom command blocks and inline commands from markdown content.

class CommandPatterns {
  /// Pattern for description blocks.

  static final RegExp descriptionBlock = RegExp(
    r'%% Description-Begin([\s\S]*?)%% Description-End',
    caseSensitive: false,
  );

  /// Pattern for heading blocks with optional alignment.

  static final RegExp headingAlignBlock = RegExp(
    r'%% H([1-6])(Left|Right|Center|Justify)?'
    r'-Begin([\s\S]*?)%% H\1(?:\2)?-End',
    caseSensitive: false,
  );

  /// Pattern for aligned text blocks.

  static final RegExp alignBlock = RegExp(
    r'%% Align(Left|Right|Center|Justify)-Begin([\s\S]*?)%% Align\1-End',
    caseSensitive: false,
  );

  /// Pattern for image commands with optional dimensions.

  static final RegExp image = RegExp(
    r'%% Image'
    r'\(\s*([^,\)]+)\s*(?:,\s*([\d\.]+)\s*)?(?:,\s*([\d\.]+)\s*)?\)',
    caseSensitive: false,
  );

  /// Pattern for video commands.

  static final RegExp video = RegExp(
    r'%% Video\(([^)]+)\)',
    caseSensitive: false,
  );

  /// Pattern for audio commands.

  static final RegExp audio = RegExp(
    r'%% Audio\(([^)]+)\)',
    caseSensitive: false,
  );

  /// Pattern for menu blocks.

  static final RegExp menuBlock = RegExp(
    r'%% Menu-Begin([\s\S]*?)%% Menu-End',
    caseSensitive: false,
  );

  /// Pattern for button blocks with required widgets.

  static final RegExp buttonBlock = RegExp(
    r'%% Button-Begin\((.*?)\)([\s\S]*?)%% Button-End',
    caseSensitive: false,
  );

  /// Pattern for hidden content blocks.

  static final RegExp hiddenBlock = RegExp(
    r'%% Hidden-Begin\(([^)]+)\)([\s\S]*?)%% Hidden-End',
    caseSensitive: false,
  );

  /// Pattern for hidden content placeholders.

  static final RegExp hiddenPlaceholder = RegExp(
    r'%% Hidden\(([^)]+)\)',
    caseSensitive: false,
  );

  /// Pattern for page breaks.

  static final RegExp pageBreak = RegExp(
    r'%% PageBreak',
    caseSensitive: false,
  );

  /// Pattern for timer commands.

  static final RegExp timer = RegExp(
    r'%% Timer\(([^)]+)\)',
    caseSensitive: false,
  );

  /// Pattern for slider commands.

  static final RegExp slider = RegExp(
    r'%% Slider\(([^,]+),\s*([\d\.]+),'
    r'\s*([\d\.]+),\s*([\d\.]+),\s*([\d\.]+)\)',
    caseSensitive: false,
  );

  /// Pattern for radio button commands.

  static final RegExp radio = RegExp(
    r'%% Radio'
    r'\(([^,]+),\s*([^,]+),\s*"((?:[^"\\]|\\.)*)"(?:,\s*([^)]+))?\)',
    caseSensitive: false,
  );

  /// Pattern for checkbox commands.

  static final RegExp checkbox = RegExp(
    r'%% Checkbox'
    r'\(([^,]+),\s*([^,]+),\s*"((?:[^"\\]|\\.)*)"(?:,\s*([^)]+))?\)',
    caseSensitive: false,
  );

  /// Pattern for calendar commands.

  static final RegExp calendar = RegExp(
    r'%% Calendar\(([^)]+)\)',
    caseSensitive: false,
  );

  /// Pattern for dropdown commands.

  static final RegExp dropdown = RegExp(
    r'%% Dropdown\(([^)]+)\)',
    caseSensitive: false,
  );

  /// Pattern for single-line input commands.

  static final RegExp inputSL = RegExp(
    r'%% InputSL\(([^)]+)\)',
    caseSensitive: false,
  );

  /// Pattern for multi-line input commands.

  static final RegExp inputML = RegExp(
    r'%% InputML\(([^)]+)\)',
    caseSensitive: false,
  );

  /// Pattern for button commands.

  static final RegExp button = RegExp(
    r'%% Button\((.+)\)',
    caseSensitive: false,
  );

  /// Pattern for menu placeholders.

  static final RegExp menuPlaceholder = RegExp(
    r'%%MenuPlaceholder\d+%%',
    caseSensitive: false,
  );

  /// Pattern for hidden content placeholder extraction.

  static final RegExp hiddenPlaceholderExtract = RegExp(
    r'%%HiddenPlaceholder\(([^)]+)\)%%',
    caseSensitive: false,
  );

  /// Combined pattern for identifying all custom commands and placeholders.
  ///
  /// This pattern is used to find all command markers in the content for
  /// sequential processing.

  static final RegExp customCommand = RegExp(
    r'(%% Slider\([^\)]+\)|%% Submit|'
    r'%% (Radio|Checkbox)\((?:[^\\()]|\\.)+\)|'
    r'%% InputSL\([^\)]+\)|%% InputML\([^\)]+\)|'
    r'%% Calendar\([^\)]+\)|%% Dropdown\([^\)]+\)|'
    r'%% Image\([^\)]+\)|%% Video\([^\)]+\)|%% Audio\([^\)]+\)|'
    r'%% Timer\([^\)]+\)|%% Button\([^\)]+\)|%% EmptyLine|'
    r'%%DescriptionPlaceholder\d+%%|'
    r'%%HeadingPlaceholder\d+%%|'
    r'%%AlignPlaceholder\d+%%|'
    r'%%MenuPlaceholder\d+%%|'
    r'%%ButtonPlaceholder\d+%%|'
    r'%%HiddenPlaceholder\([^\)]+\)%%|'
    r'%% PageBreak)',
    caseSensitive: false,
  );
}

/// Set of widget types that can be marked as required.

const Set<String> allowedRequiredTypes = {
  'Calendar',
  'Checkbox',
  'Dropdown',
  'InputSL',
  'InputML',
  'Radio',
  'Slider',
};
