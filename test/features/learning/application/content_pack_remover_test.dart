import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/application/content_pack_remover.dart';
import 'package:remath/src/features/learning/data/in_memory_progress_repository.dart';
import 'package:remath/src/features/learning/domain/attempt_event.dart';
import 'package:remath/src/features/learning/domain/content_pack_retention.dart';

void main() {
  const packId = 'org.remath.algebra.foundation';
  const installed = ContentPackRetentionState(
    installedVersion: '1.0.0',
    pinnedVersion: null,
  );

  test('removing curriculum preserves stable-ID progress history', () async {
    final progress = InMemoryProgressRepository();
    final original = _attempt();
    await progress.recordAttempt(original);
    final availability = _MemoryAvailabilityStore();
    final remover = ContentPackRemover(availabilityStore: availability);

    final transition = await remover.remove(packId, installed);

    expect(transition.outcome, ContentPackRetentionOutcome.changed);
    expect(transition.state.installedVersion, isNull);
    expect(availability.removedPackIds, [packId]);
    final retained = await progress.loadAttempts();
    expect(retained, hasLength(1));
    expect(retained.single.eventId, original.eventId);
    expect(retained.single.skillId, original.skillId);
    expect(retained.single.questionId, original.questionId);
    expect(retained.single.hasSameImmutableContentAs(original), isTrue);
  });

  test(
    'blocked and duplicate removals perform no availability writes',
    () async {
      final availability = _MemoryAvailabilityStore();
      final remover = ContentPackRemover(availabilityStore: availability);

      final blocked = await remover.remove(
        packId,
        const ContentPackRetentionState(
          installedVersion: '1.0.0',
          pinnedVersion: '1.0.0',
        ),
      );
      final duplicate = await remover.remove(
        packId,
        const ContentPackRetentionState.absent(),
      );

      expect(blocked.outcome, ContentPackRetentionOutcome.blockedPinned);
      expect(duplicate.outcome, ContentPackRetentionOutcome.unchanged);
      expect(availability.removedPackIds, isEmpty);
    },
  );

  test(
    'failed removal leaves stable-ID progress available for retry',
    () async {
      final progress = InMemoryProgressRepository();
      final original = _attempt();
      await progress.recordAttempt(original);
      final remover = ContentPackRemover(
        availabilityStore: _MemoryAvailabilityStore(shouldFail: true),
      );

      await expectLater(remover.remove(packId, installed), throwsStateError);

      final retained = await progress.loadAttempts();
      expect(retained, hasLength(1));
      expect(retained.single.hasSameImmutableContentAs(original), isTrue);
    },
  );
}

AttemptEvent _attempt() => AttemptEvent(
  answer: '4x',
  eventId: 'attempt.algebra.collect.1',
  isCorrect: true,
  occurredAt: DateTime.utc(2026, 10, 9),
  questionId: 'algebra.collect-like-terms.question-001',
  responseTime: const Duration(seconds: 12),
  sessionId: 'session.algebra.1',
  skillId: 'algebra.collect-like-terms',
);

final class _MemoryAvailabilityStore implements ContentPackAvailabilityStore {
  _MemoryAvailabilityStore({this.shouldFail = false});

  final List<String> removedPackIds = [];
  final bool shouldFail;

  @override
  Future<void> removeActive(String packId) async {
    if (shouldFail) throw StateError('Removal was interrupted.');
    removedPackIds.add(packId);
  }
}
