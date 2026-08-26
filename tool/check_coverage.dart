import 'dart:io';

void main(List<String> arguments) {
  final minimum = arguments.isEmpty ? 70.0 : double.parse(arguments.first);
  final file = File('coverage/lcov.info');
  if (!file.existsSync()) {
    stderr.writeln('coverage/lcov.info does not exist');
    exitCode = 2;
    return;
  }

  var found = 0;
  var hit = 0;
  for (final line in file.readAsLinesSync()) {
    if (line.startsWith('LF:')) {
      found += int.parse(line.substring(3));
    } else if (line.startsWith('LH:')) {
      hit += int.parse(line.substring(3));
    }
  }

  final coverage = found == 0 ? 100.0 : hit * 100 / found;
  stdout.writeln('Line coverage: ${coverage.toStringAsFixed(2)}%');
  if (coverage < minimum) {
    stderr.writeln('Required minimum: ${minimum.toStringAsFixed(2)}%');
    exitCode = 1;
  }
}
