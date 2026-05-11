# Markdown Widget Builder Changelog

Noted here are the high level changes for the package.

Guide: Each version update is noted here with a short user-oriented
description of the update. Updates in the 0.0.n series are heading
toward a 0.1 release. The `[version timestamp user]` string is
utilised by the flutter version_widget package.

## 0.1 Stable beta release

+ Remove null/empty values from output JSON [0.0.12 20260511 tonypioneer]
+ Update file_picker dependency [0.0.11 20260424 anushkavid]
+ Migrate to universal_web to allow native web build [0.0.10 20260217 dc]
+ Update the file picker [0.0.10 20260217 tonypioneer]
+ Reduce lines of code per dart file [0.0.9 20260106 tonypioneer]
+ Add the ability to pass a custom onSubmit function [0.0.8 20251216 anushkavid]
+ Fix new flutter RadioGroup conflict [0.0.7 20250825 tonypioneer]
+ Lint cleanup [0.0.6 20250805 tonypioneer]
+ Use interfaces to pass parameters to the package by default. [0.0.5 20250409 tonypioneer]
+ Set Flutter's assets folder as the default directory of markdown file and
  media files and allow users to specify the location of markdown file and
  media files in config.json file. [0.0.4 20250119 tonypioneer]
+ Use pop-up dialogues to display error messages when a file or directory is
  not found.
+ Automatically load the new file after the markdown file is modified.
+ Added an argument to indicate whether the input widget is required.
+ Added a pagination widget.
+ Added click event handling to radio button widgets and checkbox widgets.
+ Adjusted the maximum string length of the label for radio buttons and
  checkboxes that can be displayed in a single line.
+ Allowed extra space in the markdown file.
+ Replaced the path "assets/survey.md" with "example/assets/sample_markdown.md".
+ "Required" note will be automatically added to the mandatory fields.
+ Used escape characters to represent brackets in radio button and checkbox
  labels.
+ Renamed from `markdown_widgets` to `markdown_widget_builder` as there is
  already a similar `markdown_widget`.
+ Initial release of the package [0.0.1 tonypioneer]
