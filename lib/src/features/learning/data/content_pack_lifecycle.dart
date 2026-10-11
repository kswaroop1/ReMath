import '../application/content_pack_installer.dart';
import 'content_pack_archive_verifier.dart';
import 'content_pack_install_guard.dart';
import 'content_pack_install_store.dart';
import 'content_pack_payload_verifier.dart';

/// Production composition for the complete stage-verify-activate path.
ContentPackInstaller composeContentPackInstaller({
  required ContentPackInstallationBackend backend,
  required ContentPackInstallEnvironment environment,
  required ContentPackSignatureVerifier signatureVerifier,
}) => ContentPackInstaller(
  guard: ValidatedContentPackInstallGuard(environment: environment),
  store: TransactionalContentPackInstallStore(backend: backend),
  verifier: ProductionContentPackVerifier(
    maximumSchemaVersion: environment.maximumSchemaVersion,
    signatureVerifier: signatureVerifier,
  ),
);
