import '../../learning/domain/attempt_event.dart';
import '../../reasoning/domain/reasoning_curriculum.dart';

/// Immutable v1 interpretation. Unknown algebra evidence remains history only.
abstract final class StudyScoring {
  static bool supports(AttemptEvent event) {
    if (event.skillId.startsWith('reasoning.'))
      return reasoningQuestion(event) != null;
    return !event.skillId.startsWith('algebra.') ||
        RegExp(
          '^algebra\\.${RegExp.escape(event.skillId)}\\.level[0-2]\\.v1\\.mark1\\.score1\\.-?[0-9]+\\.[0-9]+(?:\\.mcq)?\$',
        ).hasMatch(event.questionId);
  }

  static ReasoningQuestion? reasoningQuestion(AttemptEvent event) {
    final match = RegExp(
      r'^reasoning\.(reasoning\.(?:order|missing|diagnose|select))\.level([0-2])\.v1\.mark1\.score1\.(-?[0-9]+)\.([0-9]+)$',
    ).firstMatch(event.questionId);
    if (match == null || match.group(1) != event.skillId) return null;
    final seed = int.tryParse(match.group(3)!);
    final index = int.tryParse(match.group(4)!);
    if (seed == null || index == null) return null;
    return ReasoningCurriculum().question(
      event.skillId,
      int.parse(match.group(2)!),
      seed,
      index,
    );
  }

  static Duration fluentWithin(String skillId) => Duration(
    seconds: skillId.startsWith('reasoning.')
        ? 90
        : skillId.startsWith('algebra.')
        ? 60
        : 20,
  );
}
