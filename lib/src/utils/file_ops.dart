/// DESCRIPTION
///
// Time-stamp: <Tuesday 2025-08-26 11:19:03 +1000 Graham Williams>
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
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;

import 'package:path/path.dart' as p;

// Conditionally import dart:io for non-web platforms.

import 'package:markdown_widget_builder/src/utils/platform_io.dart'
    if (dart.library.html) 'package:markdown_widget_builder/src/utils/platform_web.dart'
    as platform_utils;

import 'package:markdown_widget_builder/markdown_widget_builder.dart'
    show setMarkdownMediaPath;
import 'package:markdown_widget_builder/src/constants/pkg.dart'
    show defaultConfigFile, mdPath, mediaPath;

/// Structure of md_config.json.

class PathType {
  final String path;

  PathType({required this.path});

  factory PathType.fromJson(Map<String, dynamic> json) {
    return PathType(
      path: json['path'] as String,
    );
  }
}

/// Parse the data from md_config.json.

class Config {
  final PathType markdown;
  final PathType media;

  Config({required this.markdown, required this.media});

  factory Config.fromJson(Map<String, dynamic> json) {
    // Read the markdown configuration.

    final rawMarkdown = json['markdown'] as Map<String, dynamic>?;
    String markdownPath = '';

    if (rawMarkdown == null) {
      // If "markdown" is missing, use the default.

      markdownPath = mdPath;
    } else {
      markdownPath = (rawMarkdown['path'] as String?)?.trim() ?? '';
    }

    // Read the media configuration.

    final rawMedia = json['media'] as Map<String, dynamic>?;
    String mediaPathLocal = '';

    if (rawMedia == null) {
      mediaPathLocal = mediaPath;
    } else {
      mediaPathLocal = (rawMedia['path'] as String?)?.trim() ?? '';
    }

    return Config(
      markdown: PathType(path: markdownPath),
      media: PathType(path: mediaPathLocal),
    );
  }
}

/// Returns the executable directory (or application directory) on different
/// platforms.

Future<String> getAppDirectory() async {
  if (kIsWeb) {
    // On web, return a fallback path as there is no file system access.

    return '';
  }

  final os = platform_utils.getOperatingSystem();
  final exePath = platform_utils.getResolvedExecutable();

  if (os == 'macos') {
    final exeDir = p.dirname(exePath);
    final contentsDir = p.dirname(exeDir);
    final appDir = p.dirname(contentsDir);
    final outerDir = p.dirname(appDir);
    return outerDir;
  } else if (os == 'windows' || os == 'linux') {
    return p.dirname(exePath);
  } else if (os == 'android' || os == 'ios') {
    final docDirPath = await platform_utils.getApplicationDocumentsPath();
    return docDirPath;
  } else {
    return p.dirname(exePath);
  }
}

/// If the path is relative, concatenate it with the app directory; if it's
/// absolute, return it as is.

Future<String> interpretPath(String rawPath) async {
  String trimmed = rawPath;
  while (trimmed.endsWith('/') || trimmed.endsWith('\\')) {
    trimmed = trimmed.substring(0, trimmed.length - 1);
  }

  if (p.isAbsolute(trimmed)) {
    return p.normalize(trimmed);
  }
  final appDir = await getAppDirectory();
  return p.normalize(p.join(appDir, trimmed));
}

/// Returns a Config object; if an error occurs, returns a Config with default.

Future<Config> loadConfigFromAssets({
  String configAssetPath = defaultConfigFile,
  Function(String)? onError,
  Map<String, dynamic>? configMapFromApi,
}) async {
  try {
    final jsonStr = await rootBundle.loadString(configAssetPath);
    final jsonMap = json.decode(jsonStr) as Map<String, dynamic>;
    return Config.fromJson(jsonMap);
  } catch (e) {
    if (configMapFromApi != null && configMapFromApi.isNotEmpty) {
      return Config.fromJson(configMapFromApi);
    }

    // onError?.call('Error loading $configAssetPath: $e');

    // Construct a Config with default paths when an error occurs.

    return Config(
      markdown: PathType(path: mdPath),
      media: PathType(path: mediaPath),
    );
  }
}

/// Load media files from the local directory; if the directory does not exist,
/// fallback to the default media path.

Future<void> loadMediaFiles(
  String rawMediaPath, {
  Function(String)? onError,
}) async {
  if (kIsWeb) {
    // On web, always use asset path as there is no local file system access.

    setMarkdownMediaPath(mediaPath);
    return;
  }

  if (rawMediaPath.trim().isEmpty) {
    // If the path is empty, fallback to assets.

    // onError?.call(
    //     'Media path is empty, fallback to $mdPath from assets.'
    // );

    setMarkdownMediaPath(mediaPath);
    return;
  }

  final interpretedMediaPath = await interpretPath(rawMediaPath);
  final dirExists = await platform_utils.directoryExists(interpretedMediaPath);

  if (!dirExists) {
    // If the media directory does not exist, fallback to the default.

    onError?.call('Media directory not found: $interpretedMediaPath. '
        'Fallback to default: $mediaPath');
    setMarkdownMediaPath(mediaPath);
  } else {
    // Otherwise, use this local path.

    setMarkdownMediaPath(interpretedMediaPath);
  }
}

/// Load a local markdown file; if it does not exist, fallback to assets.

Future<String> loadMarkdownContent(
  String rawPath, {
  Function(String)? onError,
}) async {
  if (kIsWeb) {
    // On web, always load from assets.

    if (rawPath.trim().isEmpty) {
      return rootBundle.loadString(mdPath);
    }
    try {
      return await rootBundle.loadString(rawPath);
    } catch (e) {
      try {
        return await rootBundle.loadString(mdPath);
      } catch (e) {
        onError?.call('Error loading asset: $e');
        return 'Error: Could not load asset.';
      }
    }
  }

  if (rawPath.trim().isEmpty) {
    // If the path is empty, fallback to assets.

    // onError?.call(
    //     'Markdown path is empty, fallback to $mdPath from assets.'
    // );
    return rootBundle.loadString(mdPath);
  }
  final interpretedPath = await interpretPath(rawPath);
  final fileExists = await platform_utils.fileExists(interpretedPath);

  if (!fileExists) {
    // If the file does not exist, fallback to assets.

    onError?.call('Markdown file not found at $interpretedPath. '
        'Fallback to $mdPath from assets.');
    try {
      return await rootBundle.loadString(mdPath);
    } catch (e) {
      onError?.call('Error loading fallback asset: $e');
      return 'Error: Could not load fallback asset.';
    }
  } else {
    return platform_utils.readFileAsString(interpretedPath);
  }
}

/// File watcher. Returns a subscription object that the caller can cancel at
/// an appropriate time.
/// Returns null on web platform as file watching is not supported.

StreamSubscription<dynamic>? watchFileChanges(
  String filePath, {
  required void Function(String newContent) onFileContentChanged,
}) {
  if (kIsWeb) {
    // File watching is not supported on web.

    return null;
  }

  final parentDirPath = p.dirname(filePath);
  final watchStream = platform_utils.watchDirectory(parentDirPath);

  if (watchStream == null) {
    return null;
  }

  return watchStream.listen((event) async {
    // On non-web platforms, event is FileSystemEvent.

    if (event.type == 2 && event.path == filePath) {
      // type 2 is FileSystemEvent.modify

      final fileExists = await platform_utils.fileExists(filePath);
      if (fileExists) {
        final updated = await platform_utils.readFileAsString(filePath);
        onFileContentChanged(updated);
      }
    }
  });
}
