import 'publisher_trust_operator.dart';

/// Local operator adapter; never consumes content-pack metadata.
int runPublisherTrustCommand(
  List<String> arguments, {
  required PublisherTrustOperator operator,
}) {
  if (arguments.length == 4 &&
      arguments[0] == 'revoke' &&
      arguments[3] == '--confirm') {
    for (final identity in arguments.skip(1).take(2)) {
      if (identity.isEmpty ||
          identity.trim() != identity ||
          identity.length > 128) {
        return 65;
      }
    }
    operator.revoke(
      confirmed: true,
      publisherId: arguments[1],
      keyId: arguments[2],
    );
    return 0;
  }
  if (arguments.length != 5 ||
      arguments[0] != 'enroll' ||
      arguments[4] != '--confirm') {
    return 64;
  }
  final hex = arguments[3];
  if (!RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(hex)) return 64;
  final bytes = [
    for (var index = 0; index < hex.length; index += 2)
      int.parse(hex.substring(index, index + 2), radix: 16),
  ];
  try {
    operator.enroll(
      confirmed: true,
      publisherId: arguments[1],
      keyId: arguments[2],
      publicKey: bytes,
    );
    return 0;
  } on StateError {
    return 65;
  } on ArgumentError {
    return 65;
  }
}
