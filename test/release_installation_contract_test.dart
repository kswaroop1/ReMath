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
}
