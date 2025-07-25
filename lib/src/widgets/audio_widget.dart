/// Audio playback widget.
///
// Time-stamp: <Tuesday 2024-11-12 20:23:32 +1100 Graham Williams>
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

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

import 'package:markdown_widget_builder/src/constants/pkg.dart'
    show contentWidthFactor, mediaPath;

class AudioWidget extends StatefulWidget {
  final String filename;

  const AudioWidget({super.key, required this.filename});

  @override
  _AudioWidgetState createState() => _AudioWidgetState();
}

class _AudioWidgetState extends State<AudioWidget> {
  late AudioPlayer _player;
  String? _sourcePath;

  Duration? _duration;
  Duration _position = Duration.zero;
  PlayerState? _playerState;

  bool _failedToLoad = false;
  bool _initialized = false;

  late StreamSubscription<Duration> _durationSubscription;
  late StreamSubscription<Duration> _positionSubscription;
  late StreamSubscription<PlayerState> _playerStateSubscription;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initAudioPlayer();
  }

  @override
  void dispose() {
    _durationSubscription.cancel();
    _positionSubscription.cancel();
    _playerStateSubscription.cancel();
    _player.dispose();
    super.dispose();
  }

  /// Loads the audio file either from a local path or from assets,
  /// then initialises the player.

  Future<void> _initAudioPlayer() async {
    final rawLocalPath = '$mediaPath/${widget.filename}';
    final localFile = File(rawLocalPath);
    final isFileExists = await localFile.exists();

    final isAssetLike = rawLocalPath.startsWith('assets/') ||
        rawLocalPath.startsWith('assets\\');

    String sourcePath;
    if (isFileExists && !isAssetLike) {
      sourcePath = rawLocalPath.startsWith('file://')
          ? Uri.parse(rawLocalPath).toFilePath()
          : rawLocalPath;
    } else {
      try {
        final ByteData data = await rootBundle.load(rawLocalPath);
        final Uint8List bytes = data.buffer.asUint8List();

        final tempDir = await getTemporaryDirectory();
        final fileNameOnly = widget.filename.split('/').last;
        final tempPath = '${tempDir.path}/$fileNameOnly';

        final tempFile = File(tempPath);
        await tempFile.writeAsBytes(bytes);

        sourcePath = tempFile.path;
      } catch (e) {
        _failedToLoad = true;
        setState(() {});
        return;
      }
    }

    _sourcePath = sourcePath;

    try {
      await _player.setSource(DeviceFileSource(_sourcePath!));
    } catch (e) {
      _failedToLoad = true;
      setState(() {});
      return;
    }

    _durationSubscription = _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });

    _positionSubscription = _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });

    _playerStateSubscription = _player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _playerState = s);
    });

    setState(() {
      _initialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_failedToLoad) {
      return const Center(child: Text('Audio not found'));
    }
    if (!_initialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final isPlaying = _playerState == PlayerState.playing;
    final isPaused = _playerState == PlayerState.paused;
    final isStopped = _playerState == PlayerState.stopped;
    final isCompleted = _playerState == PlayerState.completed;

    final totalMs = _duration?.inMilliseconds ?? 0;
    final currentMs = _position.inMilliseconds.clamp(0, totalMs);

    return Center(
      child: FractionallySizedBox(
        widthFactor: contentWidthFactor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Slider(
              value: currentMs.toDouble(),
              min: 0.0,
              max: totalMs > 0 ? totalMs.toDouble() : 1.0,
              onChanged: (double value) {
                if (totalMs > 0) {
                  final newPosition = Duration(milliseconds: value.toInt());
                  _player.seek(newPosition);
                }
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: () async {
                    if (isPlaying) {
                      await _player.pause();
                    } else {
                      if (isPaused) {
                        await _player.resume();
                      } else {
                        // If stopped, completed, or never started,
                        // play from the start.

                        if (_sourcePath != null) {
                          await _player.play(DeviceFileSource(_sourcePath!));
                        }
                      }
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.stop),
                  onPressed: () async {
                    await _player.stop();
                    setState(() {
                      _position = Duration.zero;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
