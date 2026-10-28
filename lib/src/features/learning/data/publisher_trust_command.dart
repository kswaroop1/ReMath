import 'publisher_trust_operator.dart';

/// Local operator adapter; never consumes content-pack metadata.
int runPublisherTrustCommand(
  List<String> arguments, {
  required PublisherTrustOperator operator,
}) {
  if (arguments.length != 5 ||
      arguments[0] != 'enroll' ||
      arguments[4] != '--confirm') {
    return 64;
  }
  final hex = arguments[3];
  if (!RegExp(r'^[0-9a-fA-F]{64}
}
).hasMatch(hex)) return 64;
  final bytes = [
    for (var index = 0; index < hex.length; index += 2)
      int.parse(hex.substring(index, index + 2), radix: 16),
  ];
  operator.enroll(
    confirmed: true,
    publisherId: arguments[1],
    keyId: arguments[2],
    publicKey: bytes,
  );
  return 0;
}
