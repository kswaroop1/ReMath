import 'dart:convert';

import '../../learning/domain/attempt_event.dart';
import '../../learning/domain/retained_mastery.dart';
import 'study_curriculum.dart';
import 'study_scoring.dart';

final class StudyProgress {
  const StudyProgress({
    required this.skillId,
    required this.level,
    required this.independent,
    required this.correct,
    required this.assisted,
    required this.retention,
    required this.chanceAdjustedAccuracy,
    this.unsupported = 0,
  });

  factory StudyProgress.forSkill(
    String skillId,
    Iterable<AttemptEvent> attempts,
    DateTime now,
  ) {
    final history = attempts.where((e) => e.skillId == skillId).toList();
    final events = history.where(StudyScoring.supports).toList()
      ..sort((a, b) {
        final time = a.occurredAt.compareTo(b.occurredAt);
        return time == 0 ? a.eventId.compareTo(b.eventId) : time;
      });
    var level = 0;
    var streak = 0;
    var errors = 0;
    final independent = events
        .where((e) => e.kind.contributesToMastery)
        .toList();
    final numeric = independent
        .where((e) => !e.questionId.endsWith('.mcq'))
        .toList();
    for (final event in numeric) {
      final match = RegExp(r'\.level([0-2])\.').firstMatch(event.questionId);
      final attemptedLevel = match == null ? 0 : int.parse(match.group(1)!);
      if (attemptedLevel != level) continue;
      if (event.isCorrect) {
        errors = 0;
        if (event.responseTime <= StudyScoring.fluentWithinEvent(event)) {
          streak++;
          if (streak >= 3 && level < 2) {
            level++;
            streak = 0;
          }
        } else {
          streak = 0;
        }
      } else {
        streak = 0;
        errors++;
        if (errors >= 2 && level > 0) {
          level--;
          errors = 0;
        }
      }
    }
    return StudyProgress(
      skillId: skillId,
      unsupported: history.length - events.length,
      level: level,
      independent: independent.length,
      correct: independent.where((e) => e.isCorrect).length,
      assisted: events.length - independent.length,
      chanceAdjustedAccuracy: independent.isEmpty
          ? 0
          : ((independent.where((e) => e.isCorrect).length -
                        independent
                                .where(
                                  (e) =>
                                      e.questionId.endsWith('.mcq') &&
                                      !e.isCorrect,
                                )
                                .length /
                            3) /
                    independent.length)
                .clamp(0.0, 1.0),
      retention: const RetainedMasteryCalculator().forSkill(
        skillId,
        numeric,
        now: now,
      ),
    );
  }

  final String skillId;
  final int unsupported;
  final int level;
  final int independent;
  final int correct;
  final int assisted;
  final RetainedMastery retention;
  final double chanceAdjustedAccuracy;
  double get accuracy => independent == 0 ? 0 : correct / independent;
  String get explanation {
    final summary = independent == 0
        ? 'No independent evidence yet. Start with a diagnostic or guided practice.'
        : '$correct of $independent independent answers correct; $assisted assisted '
              'events. Difficulty ${level + 1} requires independent '
              '${skillId.startsWith('reasoning.')
                  ? 'reasoning'
                  : skillId.startsWith('algebra.')
                  ? 'symbolic'
                  : 'numeric'} fluency '
              'within ${StudyScoring.fluentWithin(skillId).inSeconds} seconds. '
              '${retention.reason}';
    return unsupported == 0
        ? summary
        : '$summary $unsupported events use unsupported contracts; kept in history without mastery credit.';
  }
}

enum StudyStepKind { retrieval, learn, practice, reflection }

enum StudyPhase { question, correction, retest }

final class StudyStep {
  const StudyStep(
    this.kind,
    this.skillId,
    this.level, {
    this.multipleChoice = false,
    this.templateVersion = 1,
    this.markingVersion = 1,
    this.scoringVersion = 1,
  });
  factory StudyStep.fromJson(Map<String, dynamic> json) => StudyStep(
    StudyStepKind.values.byName(json['kind'] as String),
    json['skill'] as String,
    json['level'] as int,
    multipleChoice: json['mcq'] as bool,
    templateVersion: json['templateVersion'] as int? ?? 1,
    markingVersion: json['markingVersion'] as int? ?? 1,
    scoringVersion: json['scoringVersion'] as int? ?? 1,
  );
  final StudyStepKind kind;
  final String skillId;
  final int level;
  final bool multipleChoice;
  final int templateVersion;
  final int markingVersion;
  final int scoringVersion;
  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'skill': skillId,
    'level': level,
    'mcq': multipleChoice,
    'templateVersion': templateVersion,
    'markingVersion': markingVersion,
    'scoringVersion': scoringVersion,
  };
}

final class StudyPlan {
  StudyPlan({
    required List<StudyStep> steps,
    required this.reason,
    this.isDiagnostic = false,
  }) : steps = List.unmodifiable(steps);
  factory StudyPlan.fromJson(Map<String, dynamic> json) => StudyPlan(
    steps: (json['steps'] as List<dynamic>)
        .map((s) => StudyStep.fromJson(s as Map<String, dynamic>))
        .toList(),
    reason: json['reason'] as String,
    isDiagnostic: json['diagnostic'] as bool,
  );
  final List<StudyStep> steps;
  final String reason;
  final bool isDiagnostic;
  Duration get budget => const Duration(minutes: 15);
  Map<String, Object?> toJson() => {
    'steps': steps.map((s) => s.toJson()).toList(),
    'reason': reason,
    'diagnostic': isDiagnostic,
  };
}

final class StudyPlanner {
  final StudyCurriculum _curriculum = StudyCurriculum();
  StudyStep _step(
    StudyStepKind kind,
    String skillId,
    int level, {
    bool multipleChoice = false,
  }) => StudyStep(
    kind,
    skillId,
    level,
    multipleChoice: multipleChoice,
    templateVersion: StudyCurriculum.currentTemplateVersion(skillId),
    scoringVersion: StudyCurriculum.currentScoringVersion(skillId),
  );

  List<String> _goalSkills(String id) {
    for (final goal in _curriculum.goals) {
      if (goal.id == id) return goal.skillIds;
    }
    throw ArgumentError.value(id, 'goal', 'Unknown learning goal');
  }

  StudyPlan plan(
    String goalId,
    List<AttemptEvent> attempts,
    DateTime now, {
    String? exploreSkillId,
  }) {
    final ids = _goalSkills(goalId);
    final progress = {
      for (final skill in _curriculum.skills)
        skill.id: StudyProgress.forSkill(skill.id, attempts, now),
    };
    final due =
        ids.map((id) => progress[id]!).where((p) => p.retention.isDue).toList()
          ..sort(
            (a, b) =>
                a.retention.nextReviewAt!.compareTo(b.retention.nextReviewAt!),
          );
    String target;
    String reason;
    if (exploreSkillId != null) {
      _curriculum.skill(exploreSkillId);
      target = exploreSkillId;
      reason =
          'Exploring ${_curriculum.skill(target).title}; prerequisite guidance '
          'is advisory, so you can start here.';
    } else if (due.isNotEmpty) {
      target = due.first.skillId;
      reason = '${_curriculum.skill(target).title} is due for delayed review.';
    } else {
      target = ids.firstWhere(
        (id) => progress[id]!.level == 0,
        orElse: () => ids.reduce(
          (a, b) => progress[a]!.level <= progress[b]!.level ? a : b,
        ),
      );
      reason =
          'Build ${_curriculum.skill(target).title} for your selected goal.';
      final prerequisites = _curriculum.skill(target).prerequisites;
      for (final prerequisite in prerequisites) {
        if (progress[prerequisite]?.level == 0) {
          target = prerequisite;
          reason =
              'Refresh prerequisite ${_curriculum.skill(target).title} first.';
          break;
        }
      }
    }
    if (target == 'application.mixed') {
      return StudyPlan(
        reason: 'Choose a method for each unfamiliar scenario.',
        steps: [
          for (var i = 0; i < 9; i++)
            _step(StudyStepKind.practice, target, progress[target]!.level),
          _step(StudyStepKind.reflection, target, progress[target]!.level),
        ],
      );
    }
    final level = StudyProgress.forSkill(target, attempts, now).level;
    final review = due.isEmpty ? target : due.first.skillId;
    return StudyPlan(
      reason: reason,
      steps: [
        _step(
          StudyStepKind.retrieval,
          review,
          StudyProgress.forSkill(review, attempts, now).level,
        ),
        _step(StudyStepKind.learn, target, level),
        for (var i = 0; i < 8; i++)
          _step(
            StudyStepKind.practice,
            target,
            level,
            multipleChoice:
                !target.startsWith('algebra.') &&
                !target.startsWith('reasoning.') &&
                !target.startsWith('application.') &&
                i % 3 == 1,
          ),
        _step(StudyStepKind.reflection, target, level),
      ],
    );
  }

  StudyPlan diagnostic(String goalId) => StudyPlan(
    reason: 'Three independent answers per skill establish a starting point.',
    isDiagnostic: true,
    steps: [
      for (final id in _goalSkills(goalId))
        for (var i = 0; i < 3; i++) _step(StudyStepKind.retrieval, id, 0),
      _step(StudyStepKind.reflection, _goalSkills(goalId).first, 0),
    ],
  );
}

/// Frozen, versioned plan plus exact last persisted interaction state.
final class StudyState {
  const StudyState({
    this.goalId = 'number-fluency',
    this.generator = 'portable',
    this.confidence,
    this.plan,
    this.sessionId = '',
    this.seed = 0,
    this.stepIndex = 0,
    this.questionIndex = 0,
    this.draft = '',
    this.hintCount = 0,
    this.phase = StudyPhase.question,
    this.remainingMilliseconds = 900000,
    this.relatedEventId,
    this.serial = 0,
    this.responseMilliseconds = 0,
  });
  factory StudyState.decode(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    final version = json['version'] as int;
    if (version != 1 && version != 2 && version != 3 && version != 4) {
      throw const FormatException('Unsupported study state');
    }
    if (version != 1 && json['plan'] != null) {
      final plan = json['plan'] as Map<String, dynamic>;
      for (final raw in plan['steps'] as List<dynamic>) {
        final step = raw as Map<String, dynamic>;
        if (!StudyCurriculum.supportsTemplate(
              step['skill'] as String,
              step['templateVersion'] as int,
            ) ||
            step['markingVersion'] != 1 ||
            !StudyCurriculum.supportsScoring(
              step['skill'] as String,
              step['scoringVersion'] as int,
            )) {
          throw const FormatException('Unsupported saved question contract');
        }
      }
    }
    final plan = json['plan'] == null
        ? null
        : StudyPlan.fromJson(json['plan'] as Map<String, dynamic>);
    final hasLegacy =
        plan?.steps.any(
          (step) =>
              step.templateVersion == 1 &&
              StudyCurriculum.currentTemplateVersion(step.skillId) == 2,
        ) ??
        false;
    if ((json['generator'] != null &&
            !['portable', 'legacy-browser'].contains(json['generator'])) ||
        (version >= 3 && !json.containsKey('generator'))) {
      throw const FormatException('Unsupported saved generator');
    }
    final generator = version >= 3
        ? json['generator'] as String?
        : hasLegacy
        ? null
        : 'portable';
    if (generator == null && !hasLegacy) {
      throw const FormatException('Missing generator for a current session');
    }
    final state = StudyState(
      confidence: version == 4 && json['confidence'] != null
          ? ConfidenceRating.values.byName(json['confidence'] as String)
          : null,
      generator: generator,
      goalId: json['goal'] as String,
      plan: plan,
      sessionId: json['session'] as String,
      seed: json['seed'] as int,
      stepIndex: json['step'] as int,
      questionIndex: json['question'] as int,
      draft: json['draft'] as String,
      hintCount: json['hints'] as int,
      phase: StudyPhase.values.byName(json['phase'] as String),
      remainingMilliseconds: json['remaining'] as int,
      relatedEventId: json['related'] as String?,
      serial: json['serial'] as int,
      responseMilliseconds: json['response'] as int,
    );
    if (state.stepIndex < 0 ||
        state.questionIndex < 0 ||
        state.hintCount < 0 ||
        state.hintCount > 4 ||
        state.remainingMilliseconds < 0 ||
        state.serial < 0 ||
        state.responseMilliseconds < 0 ||
        (state.plan != null && state.stepIndex >= state.plan!.steps.length)) {
      throw const FormatException('Invalid study state');
    }
    final curriculum = StudyCurriculum();
    if (!curriculum.goals.any((goal) => goal.id == state.goalId)) {
      throw const FormatException('Unknown saved goal');
    }
    for (final step in state.plan?.steps ?? const <StudyStep>[]) {
      if (!StudyCurriculum.supportsTemplate(
            step.skillId,
            step.templateVersion,
          ) ||
          step.markingVersion != 1 ||
          !StudyCurriculum.supportsScoring(step.skillId, step.scoringVersion) ||
          ((step.skillId.startsWith('algebra.') ||
                  step.skillId.startsWith('reasoning.') ||
                  step.skillId.startsWith('application.')) &&
              (version == 1 || step.multipleChoice)) ||
          step.level < 0 ||
          step.level > 2 ||
          !curriculum.skills.any((skill) => skill.id == step.skillId)) {
        throw const FormatException('Invalid saved skill or difficulty');
      }
    }
    return state;
  }
  final String goalId;
  final String? generator;
  final ConfidenceRating? confidence;
  bool get needsGeneratorChoice => generator == null;
  final StudyPlan? plan;
  final String sessionId;
  final int seed;
  final int stepIndex;
  final int questionIndex;
  final String draft;
  final int hintCount;
  final StudyPhase phase;
  final int remainingMilliseconds;
  final String? relatedEventId;
  final int serial;
  final int responseMilliseconds;
  StudyStep? get step => plan == null ? null : plan!.steps[stepIndex];

  StudyState copyWith({
    String? generator,
    ConfidenceRating? confidence,
    String? goalId,
    StudyPlan? plan,
    String? sessionId,
    int? seed,
    int? stepIndex,
    int? questionIndex,
    String? draft,
    int? hintCount,
    StudyPhase? phase,
    int? remainingMilliseconds,
    String? relatedEventId,
    int? serial,
    int? responseMilliseconds,
    bool clearRelated = false,
    bool clearConfidence = false,
  }) => StudyState(
    generator: generator ?? this.generator,
    confidence: clearConfidence ? null : confidence ?? this.confidence,
    goalId: goalId ?? this.goalId,
    plan: plan ?? this.plan,
    sessionId: sessionId ?? this.sessionId,
    seed: seed ?? this.seed,
    stepIndex: stepIndex ?? this.stepIndex,
    questionIndex: questionIndex ?? this.questionIndex,
    draft: draft ?? this.draft,
    hintCount: hintCount ?? this.hintCount,
    phase: phase ?? this.phase,
    remainingMilliseconds: remainingMilliseconds ?? this.remainingMilliseconds,
    relatedEventId: clearRelated ? null : relatedEventId ?? this.relatedEventId,
    serial: serial ?? this.serial,
    responseMilliseconds: responseMilliseconds ?? this.responseMilliseconds,
  );

  String encode() => jsonEncode({
    'version': 4,
    'generator': generator,
    'confidence': confidence?.name,
    'goal': goalId,
    'plan': plan?.toJson(),
    'session': sessionId,
    'seed': seed,
    'step': stepIndex,
    'question': questionIndex,
    'draft': draft,
    'hints': hintCount,
    'phase': phase.name,
    'remaining': remainingMilliseconds,
    'related': relatedEventId,
    'serial': serial,
    'response': responseMilliseconds,
  });
}
