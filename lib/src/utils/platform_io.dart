/// Platform utilities for non-web platforms (using dart:io).
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

import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart'
    show getTemporaryDirectory, getApplicationDocumentsDirectory;

/// Checks if a file exists at the given path.
/// Returns false on web platform.

Future<bool> fileExists(String path) async {
  final file = File(path);
  return file.exists();
}

/// Writes bytes to a temporary file and returns the path.
/// Throws on web platform.

Future<String> writeBytesToTempFile(String filename, Uint8List bytes) async {
  final tempDir = await getTemporaryDirectory();
  final fileNameOnly = filename.split('/').last;
  final tempPath = '${tempDir.path}/$fileNameOnly';
  final tempFile = File(tempPath);
  await tempFile.writeAsBytes(bytes);
  return tempFile.path;
}

/// Gets the temporary directory path.
/// Throws on web platform.

Future<String> getTemporaryDirectoryPath() async {
  final tempDir = await getTemporaryDirectory();
  return tempDir.path;
}

/// Returns the operating system name.
/// Returns 'web' on web platform.

String getOperatingSystem() {
  return Platform.operatingSystem;
}

/// Returns the resolved executable path.
/// Returns empty string on web platform.

String getResolvedExecutable() {
  return Platform.resolvedExecutable;
}

/// Returns the application documents directory path.
/// Throws on web platform.

Future<String> getApplicationDocumentsPath() async {
  final docDir = await getApplicationDocumentsDirectory();
  return docDir.path;
}

/// Checks if a directory exists at the given path.
/// Returns false on web platform.

Future<bool> directoryExists(String path) async {
  final dir = Directory(path);
  return dir.exists();
}

/// Reads a file as a string.
/// Throws on web platform.

Future<String> readFileAsString(String path) async {
  final file = File(path);
  return file.readAsString();
}

/// Creates a Directory object for watching file changes.
/// Returns null on web platform.

Stream<FileSystemEvent>? watchDirectory(String path) {
  return Directory(path).watch();
}

/// Creates a File object from a path.
/// Throws on web platform.

File createFile(String path) {
  return File(path);
}
