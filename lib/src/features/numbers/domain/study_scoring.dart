import '../../learning/domain/attempt_event.dart';

/// Immutable v1 interpretation. Unknown algebra evidence remains history only.
abstract final class StudyScoring {
  static bool supports(AttemptEvent event) =>
      !event.skillId.startsWith('algebra.') ||
      RegExp(
        '^algebra\\.${RegExp.escape(event.skillId)}\\.level[0-2]\\.v1\\.mark1\\.score1\\.-?[0-9]+\\.[0-9]+(?:\\.mcq)?\$',
      ).hasMatch(event.questionId);

  static Duration fluentWithin(String skillId) =>
      Duration(seconds: skillId.startsWith('algebra.') ? 60 : 20);
}
