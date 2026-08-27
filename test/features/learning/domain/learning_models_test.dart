import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/domain/attempt_event.dart';
import 'package:remath/src/features/learning/domain/learning_session.dart';
import 'package:remath/src/features/learning/domain/mastery_summary.dart';

void main() {
  AttemptEvent attempt(String id, {required bool correct}) => AttemptEvent(
    answer: correct ? '4' : '5',
    eventId: id,
    isCorrect: correct,
    occurredAt: DateTime.utc(2026, 8, 27),
    questionId: 'question-$id',
    responseTime: const Duration(seconds: 3),
    sessionId: 'session',
    skillId: 'arithmetic.addition',
  );

  test('new learners have an honest empty mastery summary', () {
    const summary = MasterySummary.empty();
    expect(summary.attempts, 0);
    expect(summary.accuracy, 0);
    expect(MasterySummary.fromAttempts(const []).accuracy, 0);
  });

  test('mastery accuracy reflects all recorded attempts', () {
    final summary = MasterySummary.fromAttempts([
      attempt('correct-1', correct: true),
      attempt('incorrect', correct: false),
      attempt('correct-2', correct: true),
    ]);

    expect(summary.attempts, 3);
    expect(summary.accuracy, closeTo(2 / 3, 0.000001));
  });

  test(
    'resuming a session preserves identity and changes only requested state',
    () {
      final startedAt = DateTime.utc(2026, 8, 27, 8);
      final original = LearningSession(
        answerDraft: '17',
        currentQuestionIndex: 4,
        id: 'session-1',
        seed: 91,
        startedAt: startedAt,
      );

      final unchanged = original.copyWith();
      expect(unchanged.id, 'session-1');
      expect(unchanged.seed, 91);
      expect(unchanged.startedAt, startedAt);
      expect(unchanged.currentQuestionIndex, 4);
      expect(unchanged.answerDraft, '17');

      final advanced = original.copyWith(
        answerDraft: '',
        currentQuestionIndex: 5,
      );
      expect(advanced.id, original.id);
      expect(advanced.seed, original.seed);
      expect(advanced.startedAt, original.startedAt);
      expect(advanced.currentQuestionIndex, 5);
      expect(advanced.answerDraft, isEmpty);
    },
  );

  test('a learning chunk has the promised fifteen-minute duration', () {
    expect(LearningSession.duration, const Duration(minutes: 15));
  });
}
