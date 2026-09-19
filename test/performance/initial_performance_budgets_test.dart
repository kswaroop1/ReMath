import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/app.dart';
import 'package:remath/src/core/performance_budget.dart';
import 'package:remath/src/features/learning/data/asset_content_pack_repository.dart';
import 'package:remath/src/features/learning/data/sqlite_progress_repository.dart';
import 'package:remath/src/features/learning/domain/attempt_event.dart';
import 'package:remath/src/features/learning/presentation/learning_controller.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  testWidgets('critical offline operations stay within initial CI budgets', (
    tester,
  ) async {
    final assetRepository = AssetContentPackRepository();
    final contentLoad = await _budget(
      'foundation content load',
      const Duration(milliseconds: 250),
    ).measure(assetRepository.loadFoundationPack);
    expect(
      contentLoad.isWithinBudget,
      isTrue,
      reason: contentLoad.failureMessage,
    );
    final contentPack = await assetRepository.loadFoundationPack();

    final startup = await _budget(
      'application startup',
      const Duration(seconds: 2),
    ).measure(() async {
      final repository = SqliteProgressRepository(sqlite3.openInMemory());
      await tester.pumpWidget(
        ReMathApp(contentPack: contentPack, repository: repository),
      );
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await repository.close();
    });
    expect(
      startup.isWithinBudget,
      isTrue,
      reason: startup.failureMessage,
    );

    final persistenceRepository = SqliteProgressRepository(
      sqlite3.openInMemory(),
    );
    addTearDown(persistenceRepository.close);
    var eventSerial = 0;
    final persistence = await _budget(
      'SQLite attempt persistence',
      const Duration(milliseconds: 100),
    ).measure(() async {
      final serial = eventSerial++;
      await persistenceRepository.recordAttempt(
        AttemptEvent(
          answer: '4',
          eventId: 'performance-event-$serial',
          isCorrect: true,
          kind: AttemptKind.answer,
          occurredAt: DateTime.utc(2026, 9, 15, 12, 0, 0, serial),
          questionId: 'performance-question-$serial',
          responseTime: const Duration(seconds: 1),
          sessionId: 'performance-session',
          skillId: 'arithmetic.addition',
        ),
      );
    });
    expect(
      persistence.isWithinBudget,
      isTrue,
      reason: persistence.failureMessage,
    );

    var controllerSerial = 0;
    final transition = await _budget(
      'question transition',
      const Duration(milliseconds: 500),
    ).measure(() async {
      final repository = SqliteProgressRepository(sqlite3.openInMemory());
      final serial = controllerSerial++;
      var idSerial = 0;
      final controller = LearningController(
        contentPack: contentPack,
        repository: repository,
        clock: () => DateTime.utc(2026, 9, 15, 12),
        idFactory: () => 'performance-id-$serial-${idSerial++}',
      );
      await controller.initialise();
      await controller.startChunk();
      controller.updateDraft(controller.currentQuestion!.answer.toString());
      await controller.submitAnswer();
      controller.dispose();
      await repository.close();
    });
    expect(
      transition.isWithinBudget,
      isTrue,
      reason: transition.failureMessage,
    );
  });
}

PerformanceBudget _budget(String name, Duration maximum) => PerformanceBudget(
  name: name,
  maximum: maximum,
  warmUpRuns: 2,
  sampleRuns: 5,
);
