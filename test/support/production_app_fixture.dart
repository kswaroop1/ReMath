import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:remath/main.dart' as application;
import 'package:remath/src/app.dart';

/// Replaces only the OS directory lookup; bootstrap and SQLite remain real.
final class ProductionAppFixture {
  ProductionAppFixture._(this.root, this.previousProvider);

  final Directory root;
  final PathProviderPlatform previousProvider;
  ReMathApp? app;

  static Future<ProductionAppFixture> create() async {
    final root = await Directory.systemTemp.createTemp('remath-journey-');
    final fixture = ProductionAppFixture._(root, PathProviderPlatform.instance);
    PathProviderPlatform.instance = _TemporarySupportDirectory(
      '${root.path}${Platform.pathSeparator}support',
    );
    return fixture;
  }

  Future<ReMathApp> launch(WidgetTester tester) async {
    await tester.runAsync(application.main);
    await tester.pumpAndSettle();
    app = tester.widget<ReMathApp>(find.byType(ReMathApp));
    return app!;
  }

  Future<void> stop(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await app?.repository.close();
    app = null;
  }

  Future<void> dispose() async {
    await app?.repository.close();
    PathProviderPlatform.instance = previousProvider;
    await root.delete(recursive: true);
  }
}

final class _TemporarySupportDirectory extends PathProviderPlatform {
  _TemporarySupportDirectory(this.path);
  final String path;

  @override
  Future<String?> getApplicationSupportPath() async => path;
}
