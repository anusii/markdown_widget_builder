/// Image widget.
///
// Time-stamp: <Thursday 2024-11-14 21:33:15 +1100 Graham Williams>
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

import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

// Conditionally import dart:io for non-web platforms.

import 'package:markdown_widget_builder/src/utils/platform_io.dart'
    if (dart.library.html) 'package:markdown_widget_builder/src/utils/platform_web.dart'
    as platform_utils;

import 'package:markdown_widget_builder/src/constants/pkg.dart'
    show contentWidthFactor, mediaPath;

class ImageWidget extends StatefulWidget {
  final String filename;
  final double? width;
  final double? height;

  const ImageWidget({
    super.key,
    required this.filename,
    this.width,
    this.height,
  });

  @override
  ImageWidgetState createState() => ImageWidgetState();
}

class ImageWidgetState extends State<ImageWidget> {
  String? _localPath;
  String? _assetPath;
  Uint8List? _imageBytes;
  bool _failedToLoad = false;
  bool _useAsset = false;

  @override
  void initState() {
    super.initState();
    _initializeImage();
  }

  Future<void> _initializeImage() async {
    final rawLocalPath = '$mediaPath/${widget.filename}';

    final isAssetLike = rawLocalPath.startsWith('assets/') ||
        rawLocalPath.startsWith('assets\\');

    if (kIsWeb) {
      // On web, load image bytes from assets and use Image.memory.

      try {
        final data = await rootBundle.load(rawLocalPath);
        _imageBytes = data.buffer.asUint8List();
        _assetPath = rawLocalPath;
        _useAsset = true;
      } catch (e) {
        _failedToLoad = true;
      }
    } else {
      // On non-web platforms, check if file exists locally.

      final isFileExists = await platform_utils.fileExists(rawLocalPath);

      if (isFileExists && !isAssetLike) {
        _localPath = rawLocalPath;
      } else {
        try {
          final data = await rootBundle.load(rawLocalPath);
          final bytes = data.buffer.asUint8List();

          final tempPath = await platform_utils.writeBytesToTempFile(
            widget.filename,
            bytes,
          );

          _localPath = tempPath;
        } catch (e) {
          _failedToLoad = true;
        }
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_failedToLoad) {
      return const Center(child: Text('Image not found'));
    }

    if (kIsWeb) {
      if (_imageBytes == null) {
        return const Center(child: CircularProgressIndicator());
      }
      return Center(
        child: FractionallySizedBox(
          widthFactor: contentWidthFactor,
          child: Image.memory(
            _imageBytes!,
            width: widget.width,
            height: widget.height,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Text('Image not found');
            },
          ),
        ),
      );
    }

    // Non-web platforms.

    if (_localPath == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: FractionallySizedBox(
        widthFactor: contentWidthFactor,
        child: Image(
          image: FileImage(platform_utils.createFile(_localPath!)),
          width: widget.width,
          height: widget.height,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Text('Image not found');
          },
        ),
      ),
    );
  }
}
