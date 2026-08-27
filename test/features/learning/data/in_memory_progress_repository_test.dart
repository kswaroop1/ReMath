import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/data/in_memory_progress_repository.dart';
import 'package:remath/src/features/learning/domain/attempt_event.dart';
import 'package:remath/src/features/learning/domain/learning_session.dart';

void main() {
  AttemptEvent attempt(String id) => AttemptEvent(
    answer: '4',
    eventId: id,
    isCorrect: true,
    occurredAt: DateTime.utc(2026, 8, 27),
    questionId: 'question-$id',
    responseTime: const Duration(seconds: 3),
    sessionId: 'session',
    skillId: 'arithmetic.addition',
  );

  LearningSession session(String id) => LearningSession(
    currentQuestionIndex: 0,
    id: id,
    seed: 91,
    startedAt: DateTime.utc(2026, 8, 27),
  );

  test('starts with no personal progress or interrupted session', () async {
    final repository = InMemoryProgressRepository();

    expect(await repository.loadAttempts(), isEmpty);
    expect(await repository.loadSession(), isNull);
    await repository.close();
  });

  test('records immutable attempt events idempotently', () async {
    final repository = InMemoryProgressRepository();

    expect(await repository.recordAttempt(attempt('event-1')), isTrue);
    expect(await repository.recordAttempt(attempt('event-1')), isFalse);
    expect(await repository.recordAttempt(attempt('event-2')), isTrue);

    final loaded = await repository.loadAttempts();
    expect(loaded.map((event) => event.eventId), ['event-1', 'event-2']);
    expect(() => loaded.add(attempt('event-3')), throwsUnsupportedError);
  });

  test('only completing the active session clears resumable work', () async {
    final repository = InMemoryProgressRepository();
    await repository.saveSession(session('active'));

    await repository.completeSession('another-session');
    expect((await repository.loadSession())?.id, 'active');

    await repository.completeSession('active');
    expect(await repository.loadSession(), isNull);
  });

  test('saving again replaces the single active session', () async {
    final repository = InMemoryProgressRepository();
    await repository.saveSession(session('first'));
    await repository.saveSession(session('second'));

    expect((await repository.loadSession())?.id, 'second');
  });
}
