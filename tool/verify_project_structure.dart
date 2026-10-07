import 'dart:io';

const requiredApplicationFiles = <String>[
  'pubspec.lock',
  'android/app/build.gradle.kts',
  'android/app/src/main/AndroidManifest.xml',
  'ios/Runner.xcodeproj/project.pbxproj',
  'linux/CMakeLists.txt',
  'macos/Runner.xcodeproj/project.pbxproj',
  'web/index.html',
  'windows/CMakeLists.txt',
];

void main() {
  final missing = requiredApplicationFiles
      .where((path) => !File(path).existsSync())
      .toList(growable: false);
  if (missing.isEmpty) {
    stdout.writeln('Committed application structure is complete.');
    return;
  }

  stderr.writeln('Required committed application files are missing:');
  for (final path in missing) {
    stderr.writeln('- $path');
  }
  exitCode = 1;
}
