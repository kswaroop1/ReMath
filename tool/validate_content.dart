import 'dart:io';

import 'package:remath/src/features/learning/data/content_pack_parser.dart';
import 'package:remath/src/features/learning/data/content_pack_validator.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.isEmpty) {
    stderr.writeln(
      'Usage: dart run tool/validate_content.dart <pack.json> [...]',
    );
    exitCode = 64;
    return;
  }
  var failed = false;
  for (final path in arguments) {
    try {
      final source = await File(path).readAsString();
      final pack = const ContentPackParser().parse(source);
      final issues = const ContentPackValidator().validate(pack);
      if (issues.isEmpty) {
        stdout.writeln('Validated $path (${pack.id} ${pack.version})');
      } else {
        failed = true;
        stderr.writeln('$path:');
        for (final issue in issues) {
          stderr.writeln('  - $issue');
        }
      }
    } on Object catch (error) {
      failed = true;
      stderr.writeln('$path: $error');
    }
  }
  if (failed) {
    exitCode = 1;
  }
}
