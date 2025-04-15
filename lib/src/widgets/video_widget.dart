/// Video playback widget.
///
// Time-stamp: <Tuesday 2024-11-12 20:18:13 +1100 Graham Williams>
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

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path_provider/path_provider.dart';

import 'package:markdown_widget_builder/src/constants/pkg.dart'
    show contentWidthFactor, mediaPath;

class VideoWidget extends StatefulWidget {
  final String filename;

  const VideoWidget({super.key, required this.filename});

  @override
  _VideoWidgetState createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  late final Player _player;
  late final VideoController _controller;
  bool _isVideoInitialized = false;
  bool _failedToLoad = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    final rawLocalPath = '$mediaPath/${widget.filename}';
    final localFile = File(rawLocalPath);
    final isLocalFile = await localFile.exists();

    String mediaUri;
    try {
      if (isLocalFile) {
        if (rawLocalPath.startsWith('file://')) {
          mediaUri = rawLocalPath;
        } else {
          mediaUri = 'file://$rawLocalPath';
        }
      } else {
        final ByteData data = await rootBundle.load(rawLocalPath);
        final Uint8List bytes = data.buffer.asUint8List();

        final tempDirPath = (await getTemporaryDirectory()).path;
        final fileNameOnly = widget.filename.split('/').last;
        final tempPath = '$tempDirPath/$fileNameOnly';

        final tempFile = File(tempPath);
        await tempFile.writeAsBytes(bytes);

        mediaUri = Uri.file(tempFile.path).toString();
      }
    } catch (e) {
      _failedToLoad = true;
      setState(() {});
      return;
    }

    _player = Player();
    _controller = VideoController(_player);

    try {
      await _player.open(Media(mediaUri), play: false);
      setState(() {
        _isVideoInitialized = true;
      });
    } catch (_) {
      _failedToLoad = true;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failedToLoad) {
      return const Center(child: Text('Video not found'));
    }
    if (!_isVideoInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return _buildVideoPlayer();
  }

  Widget _buildVideoPlayer() {
    return Center(
      child: FractionallySizedBox(
        widthFactor: contentWidthFactor,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Focus(
            canRequestFocus: false,
            child: Video(controller: _controller),
          ),
        ),
      ),
    );
  }
}
