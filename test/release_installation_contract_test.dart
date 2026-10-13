import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('future releases publish the verified installation guidance', () {
    final guidance = File('docs/installing.md').readAsStringSync();
    final workflow = File('.github/workflows/release.yml').readAsStringSync();

    expect(guidance, contains('Unblock-File'));
    expect(guidance, contains('unblock the ZIP before extracting'));
    expect(guidance, contains('not upgrade-stable'));
    expect(guidance, contains('Windows code signing'));
    expect(workflow, contains('actions/checkout@'));
    expect(workflow, contains('--notes "\$(cat docs/installing.md)"'));
  });

  test('every released native app receives its calculated semantic version', () {
    final workflow = File('.github/workflows/release.yml').readAsStringSync();
    final nativeComposition = File(
      'lib/src/features/learning/data/open_content_pack_lifecycle_native.dart',
    ).readAsStringSync();
    final versionDefines = RegExp(
      r'--dart-define="APP_VERSION=\$\{\{ needs\.version\.outputs\.version \}\}"',
    ).allMatches(workflow);

    expect(versionDefines.length, 5);
    expect(
      nativeComposition,
      contains("String.fromEnvironment('APP_VERSION'"),
    );
    expect(nativeComposition, isNot(contains("currentAppVersion: '0.1.0'")));
  });
}
