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
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:audioplayers/audioplayers.dart';

// Conditionally import dart:io for non-web platforms.

import 'package:markdown_widget_builder/src/utils/platform_io.dart'
    if (dart.library.html) 'package:markdown_widget_builder/src/utils/platform_web.dart'
    as platform_utils;

import 'package:markdown_widget_builder/src/constants/pkg.dart'
    show contentWidthFactor, mediaPath;

class AudioWidget extends StatefulWidget {
  final String filename;

  const AudioWidget({super.key, required this.filename});

  @override
  State<AudioWidget> createState() => _AudioWidgetState();
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

    final isAssetLike = rawLocalPath.startsWith('assets/') ||
        rawLocalPath.startsWith('assets\\');

    Source audioSource;

    try {
      if (kIsWeb) {
        // On web, AssetSource expects a path relative to the assets/ directory,
        // without the 'assets/' prefix.

        String assetPath = rawLocalPath;
        if (assetPath.startsWith('assets/')) {
          assetPath = assetPath.substring(7); // Remove 'assets/' prefix.
        } else if (assetPath.startsWith('assets\\')) {
          assetPath = assetPath.substring(7); // Remove 'assets\\' prefix.
        }
        audioSource = AssetSource(assetPath);
        _sourcePath = assetPath;
      } else {
        // On non-web platforms, check if file exists locally.

        final isFileExists = await platform_utils.fileExists(rawLocalPath);

        if (isFileExists && !isAssetLike) {
          final sourcePath = rawLocalPath.startsWith('file://')
              ? Uri.parse(rawLocalPath).toFilePath()
              : rawLocalPath;
          _sourcePath = sourcePath;
          audioSource = DeviceFileSource(_sourcePath!);
        } else {
          final ByteData data = await rootBundle.load(rawLocalPath);
          final Uint8List bytes = data.buffer.asUint8List();

          final tempPath = await platform_utils.writeBytesToTempFile(
            widget.filename,
            bytes,
          );

          _sourcePath = tempPath;
          audioSource = DeviceFileSource(_sourcePath!);
        }
      }
    } catch (e) {
      _failedToLoad = true;
      setState(() {});
      return;
    }

    try {
      await _player.setSource(audioSource);
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
                          final source = kIsWeb
                              ? AssetSource(_sourcePath!)
                              : DeviceFileSource(_sourcePath!);
                          await _player.play(source);
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
