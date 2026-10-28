import 'publisher_trust_operator.dart';

/// Local operator adapter; never consumes content-pack metadata.
int runPublisherTrustCommand(
  List<String> arguments, {
  required PublisherTrustOperator operator,
}) {
  return 64;
}
