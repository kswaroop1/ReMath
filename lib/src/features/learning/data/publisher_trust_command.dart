import 'publisher_trust_operator.dart';

/// Local operator adapter; never consumes content-pack metadata.
int runPublisherTrustCommand(
  List<String> arguments, {
  required PublisherTrustOperator operator,
}) {
  throw UnimplementedError('SP-006 trust command is not implemented');
}
