import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Material Icons fontu Flutter varlıklarına dahil edilir', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final flutterSection = pubspec
        .split(RegExp(r'^flutter_launcher_icons:', multiLine: true))
        .first;

    expect(
      flutterSection,
      contains(RegExp(r'^  uses-material-design:\s*true\s*$', multiLine: true)),
    );
  });
}
