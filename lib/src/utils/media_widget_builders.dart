/// Media widget builders for images, videos, and audio.
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

/// Builds media widgets (image, video, audio) from commands.

class MediaWidgetBuilders {
  final BuildContext context;
  final Helpers helpers;

  MediaWidgetBuilders({
    required this.context,
    required this.helpers,
  });

  /// Builds an image widget from command.

  Widget buildImageWidget(String command) {
    final imageMatch = CommandPatterns.image.firstMatch(command);
    if (imageMatch != null) {
      final filename = imageMatch.group(1)!.trim();
      double? width = imageMatch.group(2) != null
          ? double.tryParse(imageMatch.group(2)!.trim())
          : null;
      double? height = imageMatch.group(3) != null
          ? double.tryParse(imageMatch.group(3)!.trim())
          : null;
      return helpers.buildImageWidget(filename, width: width, height: height);
    }
    return const SizedBox.shrink();
  }

  /// Builds a video widget from command.

  Widget buildVideoWidget(String command) {
    final videoMatch = CommandPatterns.video.firstMatch(command);
    if (videoMatch != null) {
      return helpers.buildVideoWidget(videoMatch.group(1)!.trim());
    }
    return const SizedBox.shrink();
  }

  /// Builds an audio widget from command.

  Widget buildAudioWidget(String command) {
    final audioMatch = CommandPatterns.audio.firstMatch(command);
    if (audioMatch != null) {
      return helpers.buildAudioWidget(audioMatch.group(1)!.trim());
    }
    return const SizedBox.shrink();
  }

  /// Builds a timer widget from command.

  Widget buildTimerWidget(String command) {
    final timerMatch = CommandPatterns.timer.firstMatch(command);
    if (timerMatch != null) {
      return helpers.buildTimerWidget(
        timerMatch.group(1)!.trim(),
        isRequired: false,
      );
    }
    return const SizedBox.shrink();
  }

  /// Builds an empty line widget.

  Widget buildEmptyLine() {
    final lineHeight = DefaultTextStyle.of(context).style.fontSize ?? 16.0;
    return SizedBox(height: lineHeight);
  }
}
