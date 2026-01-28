/// File saving utilities for the button widget.
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

import 'dart:convert';
import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:universal_html/html.dart' as html;

/// JSON encoder with indentation for pretty printing.

const JsonEncoder jsonEncoder = JsonEncoder.withIndent('  ');

/// Downloads data as a JSON file for web platforms.

Future<void> downloadDataForWeb(
  BuildContext context,
  Map<String, dynamic> data,
  String defaultFileName,
  TextEditingController filenameController,
) async {
  final jsonContent = jsonEncoder.convert(data);
  final messenger = ScaffoldMessenger.of(context);

  String? filename = await showDialog<String>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text('Save As'),
        content: TextField(
          controller: filenameController,
          decoration: const InputDecoration(
            hintText: 'Enter filename',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(filenameController.text),
            child: const Text('Save'),
          ),
        ],
      );
    },
  );

  if (filename != null && filename.isNotEmpty) {
    if (!filename.endsWith('.json')) {
      filename = '$filename.json';
    }
    final bytes = utf8.encode(jsonContent);
    final blob = html.Blob([bytes], 'application/json');
    final url = html.Url.createObjectUrlFromBlob(blob);

    html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();

    html.Url.revokeObjectUrl(url);

    messenger.showSnackBar(
      SnackBar(content: Text('Data downloaded as $filename')),
    );
  } else {
    messenger.showSnackBar(
      const SnackBar(content: Text('Save cancelled.')),
    );
  }
}

/// Saves data as a JSON file for non-web platforms.

Future<void> saveDataForNonWeb(
  BuildContext context,
  Map<String, dynamic> data,
  String defaultFileName,
) async {
  final messenger = ScaffoldMessenger.of(context);

  String? selectedFile = await FilePicker.platform.saveFile(
    dialogTitle: 'Please choose a filename and path to save the result',
    fileName: defaultFileName,
    type: FileType.custom,
    allowedExtensions: ['json'],
  );

  if (selectedFile != null) {
    final file = File(selectedFile);
    final jsonContent = jsonEncoder.convert(data);

    try {
      await file.writeAsString(jsonContent);
      debugPrint('File saved at $selectedFile');

      messenger.showSnackBar(
        SnackBar(content: Text('Data saved as $selectedFile')),
      );
    } catch (e) {
      debugPrint('Error saving file: $e');

      messenger.showSnackBar(
        SnackBar(content: Text('Error saving file: $e')),
      );
    }
  } else {
    debugPrint('Save file dialog was cancelled.');
    messenger.showSnackBar(
      const SnackBar(content: Text('Save cancelled.')),
    );
  }
}

/// Saves data locally as a JSON file.

Future<void> saveDataLocally(
  BuildContext context,
  Map<String, dynamic> data,
  String surveyTitle,
  TextEditingController filenameController,
) async {
  debugPrint('Collected Data:');
  debugPrint(jsonEncoder.convert(data));

  final defaultFileName = generateFilename(surveyTitle);

  if (kIsWeb) {
    await downloadDataForWeb(
      context,
      data,
      defaultFileName,
      filenameController,
    );
  } else {
    await saveDataForNonWeb(context, data, defaultFileName);
  }
}

/// Generates a filename based on the survey title.

String generateFilename(String title) {
  String filename = title.toLowerCase();
  filename = filename.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  filename = filename.replaceAll(RegExp(r'^_+|_+$'), '');
  filename = '$filename.json';
  return filename;
}
