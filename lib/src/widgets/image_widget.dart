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

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

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
  bool _failedToLoad = false;

  @override
  void initState() {
    super.initState();
    _initializeImage();
  }

  Future<void> _initializeImage() async {
    final rawLocalPath = '$mediaPath/${widget.filename}';
    final file = File(rawLocalPath);
    final existsLocally = await file.exists();

    if (existsLocally) {
      _localPath = file.path;
    } else {
      try {
        final data = await rootBundle.load(rawLocalPath);
        final bytes = data.buffer.asUint8List();
        final tempDir = await getTemporaryDirectory();
        final fileNameOnly = widget.filename.split('/').last;
        final tempPath = '${tempDir.path}/$fileNameOnly';

        final tempFile = File(tempPath);
        await tempFile.writeAsBytes(bytes);
        _localPath = tempFile.path;
      } catch (e) {
        _failedToLoad = true;
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_failedToLoad) {
      return const Center(child: Text('Image not found'));
    }
    if (_localPath == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: FractionallySizedBox(
        widthFactor: contentWidthFactor,
        child: Image.file(
          File(_localPath!),
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
