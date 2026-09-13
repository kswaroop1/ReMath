import 'dart:async';

import 'package:flutter/material.dart';

import '../../applications/domain/application_curriculum.dart';
import '../../applications/presentation/application_answer_editor.dart';
import '../../learning/domain/attempt_event.dart';
import '../../learning/domain/numeric_answer_contract.dart';
import '../../learning/domain/progress_repository.dart';
import '../../reasoning/domain/reasoning_curriculum.dart';
import '../../reasoning/presentation/reasoning_answer_editor.dart';
import '../domain/number_curriculum.dart';
import '../domain/study_curriculum.dart';
import '../domain/study_plan.dart';
import '../domain/study_scoring.dart';
import 'study_controller.dart';

class StudyScreen extends StatefulWidget {
  const StudyScreen({required this.repository, super.key});
  final ProgressRepository repository;
  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> with WidgetsBindingObserver {
  late final StudyController _controller;
  late final Future<void> _ready;
  final _answer = TextEditingController();
  final _focus = FocusNode();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = StudyController(repository: widget.repository)
      ..addListener(_changed);
    _ready = _controller.initialise().then((_) {
      if (mounted) {
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          unawaited(_controller.checkpoint());
        });
      }
    });
  }

  void _changed() {
    if (!mounted) return;
    final draft = _controller.state.draft;
    if (_answer.text != draft) {
      _answer.value = TextEditingValue(
        text: draft,
        selection: TextSelection.collapsed(offset: draft.length),
      );
    }
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_controller.resume());
    } else {
      unawaited(_controller.pause());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    unawaited(_controller.pause());
    _controller
      ..removeListener(_changed)
      ..dispose();
    _answer.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    SurpriseRating? surprise;
    final q = _controller.question;
    if (_controller.state.confidence != null && q != null) {
      final mark = q.mark(_controller.state.draft);
      final offeredChoice =
          !_controller.isMultipleChoice ||
          q.choices.any((choice) => choice.value == _controller.state.draft);
      if (mark.verdict != AnswerVerdict.invalid && offeredChoice && mounted) {
        await _controller.finishAnswerTiming();
        if (!mounted) return;
        surprise = await showDialog<SurpriseRating>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text(
              mark.verdict == AnswerVerdict.correct
                  ? 'Correct — was that expected?'
                  : 'Not correct — was that expected?',
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(context, SurpriseRating.unsurprising),
                child: const Text('Not surprising'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pop(context, SurpriseRating.surprising),
                child: const Text('Surprising'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Skip'),
              ),
            ],
          ),
        );
      }
    }
    await _controller.submit(surprise: surprise);
    if (mounted &&
        _controller.question != null &&
        !_controller.isMultipleChoice) {
      _focus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    onPopInvokedWithResult: (didPop, result) {
      if (didPop) unawaited(_controller.pause());
    },
    child: Scaffold(
      appBar: AppBar(title: const Text('Number and algebra learning')),
      body: FutureBuilder<void>(
        future: _ready,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Could not open your saved learning session. '
                'Your saved data has been kept.',
              ),
            );
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_controller.error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            _controller.error!,
                            semanticsLabel: _controller.error,
                          ),
                        ),
                      if (_controller.state.plan == null)
                        ..._overview(context)
                      else
                        ..._session(context),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );

  List<Widget> _overview(BuildContext context) => [
    Text('Choose your goal', style: Theme.of(context).textTheme.headlineSmall),
    const SizedBox(height: 12),
    for (final goal in _controller.curriculum.goals)
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: ChoiceChip(
          label: Text(goal.title),
          selected: _controller.state.goalId == goal.id,
          onSelected: _controller.busy
              ? null
              : (_) {
                  unawaited(_controller.selectGoal(goal.id));
                },
        ),
      ),
    FilledButton(
      onPressed: _controller.busy
          ? null
          : () {
              unawaited(_controller.start());
            },
      child: const Text('Plan my next chunk'),
    ),
    OutlinedButton(
      onPressed: _controller.busy
          ? null
          : () => unawaited(_controller.start(session: StudySessionKind.drill)),
      child: const Text('Two-minute drill'),
    ),
    OutlinedButton(
      onPressed: _controller.busy
          ? null
          : () =>
                unawaited(_controller.start(session: StudySessionKind.chained)),
      child: const Text('Chained study block'),
    ),
    TextButton(
      onPressed: _controller.busy
          ? null
          : () {
              unawaited(_controller.start(diagnostic: true));
            },
      child: const Text('Check my starting point'),
    ),
    const SizedBox(height: 20),
    Text(
      'Your skills and progress',
      style: Theme.of(context).textTheme.titleLarge,
    ),
    const Text(
      'Independent fluency and delayed retention are assessed separately. '
      'You can explore any skill.',
    ),
    if (_controller.calibration.ratedAttempts > 0 ||
        _controller.calibration.surpriseRatedAttempts > 0) ...[
      const SizedBox(height: 12),
      Text(
        'Confidence calibration',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      Text(
        '${_controller.calibration.calibrated} calibrated · '
        '${_controller.calibration.overconfident} overconfident · '
        '${_controller.calibration.underconfident} underconfident',
      ),
      Text(
        'Calibration score '
        '${(_controller.calibration.score * 100).round()}% · '
        '${_controller.calibration.surprisingResults} of '
        '${_controller.calibration.surpriseRatedAttempts} results surprising',
      ),
    ],
    for (final progress in _controller.progress) _skillTile(progress),
  ];

  Widget _skillTile(StudyProgress progress) {
    final skill = _controller.curriculum.skill(progress.skillId);
    final events = _controller.history
        .where((e) => e.skillId == skill.id)
        .toList();
    final technique = StudyScoring.techniqueSummary(events);
    return ExpansionTile(
      title: Text(skill.title),
      subtitle: Text(
        'Difficulty ${progress.level + 1} · '
        '${progress.correct}/${progress.independent} independent answers',
      ),
      childrenPadding: const EdgeInsets.all(12),
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(progress.explanation),
        if (skill.id.startsWith('application.'))
          Text(
            '${(technique.$2 * 100).round()}% technique selection across ${technique.$1} independent answers. Method and assumption are scored separately from calculation.',
          ),
        Text(
          '${(progress.chanceAdjustedAccuracy * 100).round()}% chance-adjusted accuracy. '
          'Four-choice answers are adjusted for guessing.',
        ),
        if (skill.prerequisites.isNotEmpty)
          Text(
            'Suggested preparation: ${skill.prerequisites.map((id) => _controller.curriculum.skill(id).title).join(', ')}',
          ),
        TextButton(
          onPressed: _controller.busy
              ? null
              : () {
                  unawaited(_controller.start(exploreSkillId: skill.id));
                },
          child: Text('Study ${skill.title}'),
        ),
        if (events.isEmpty)
          const Text('No attempts yet.')
        else
          ...events.reversed.map(
            (event) => ListTile(
              title: Text(_eventDescription(event)),
              subtitle: Text(
                '${event.occurredAt.toLocal()} · Answer: ${_answerDescription(event)}',
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _reviewPrerequisite(ReasoningQuestion q) async {
    final before = _controller.state.hintCount;
    if (before < 4) await _controller.revealHint();
    if (!mounted || (before < 4 && _controller.state.hintCount == before)) {
      return;
    }
    final skill = _controller.curriculum.skill(q.remediationSkillId);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(skill.title),
        content: SingleChildScrollView(
          child: Text('${skill.lesson}\n\n${skill.example}'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Return to question'),
          ),
        ],
      ),
    );
  }

  String _answerDescription(AttemptEvent event) {
    if (event.kind == AttemptKind.hint) return 'Hint revealed';
    final application = StudyScoring.applicationQuestion(event);
    if (application != null) return application.describeAnswer(event.answer);
    return StudyScoring.reasoningQuestion(
          event,
        )?.describeAnswer(event.answer) ??
        event.answer;
  }

  String _eventDescription(AttemptEvent event) {
    if (!StudyScoring.supports(event)) {
      return 'Unsupported contract; kept in history without mastery credit.';
    }
    if (!event.kind.contributesToMastery) {
      return event.kind == AttemptKind.hint
          ? 'Hint used; no independent mastery credit.'
          : 'Correction or assisted answer; no independent mastery credit.';
    }
    final reasoning = StudyScoring.reasoningQuestion(event);
    if (reasoning != null) {
      return '${event.isCorrect ? 'Correct' : 'Incorrect'} independent reasoning; ${(reasoning.credit(event.answer) * 100).round()}% credit. ${event.misconceptionId ?? ''}';
    }
    if (event.questionId.endsWith('.mcq')) {
      return '${event.isCorrect ? 'Correct' : 'Incorrect'} choice; '
          'choice accuracy only, not numeric mastery.';
    }
    return event.isCorrect
        ? 'Correct independent answer; contributes to fluency '
              'and to retention when a delayed review is due.'
        : 'Incorrect independent answer; resets the fluent streak and makes review due.';
  }

  List<Widget> _session(BuildContext context) {
    final state = _controller.state;
    if (state.needsGeneratorChoice) {
      final current = state.step!;
      final legacy =
          StudyCurriculum.currentTemplateVersion(current.skillId) == 2
          ? current
          : state.plan!.steps.firstWhere(
              (s) =>
                  s.templateVersion == 1 &&
                  StudyCurriculum.currentTemplateVersion(s.skillId) == 2,
            );
      String preview(bool browser) => _controller.curriculum
          .question(
            legacy.skillId,
            legacy.level,
            state.seed,
            state.questionIndex,
            templateVersion: 1,
            legacyBrowser: browser,
          )
          .prompt;
      return [
        Text(
          'Choose the saved question version',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const Text(
          'Your draft is safe. Older versions could produce two different questions from the same saved details. Choose the version you were using before continuing.',
        ),
        Text('Saved answer: ${state.draft}'),
        for (final browser in [true, false]) ...[
          Text(preview(browser)),
          OutlinedButton(
            onPressed: _controller.busy
                ? null
                : () => unawaited(
                    _controller.selectLegacyGenerator(
                      browser ? 'legacy-browser' : 'portable',
                    ),
                  ),
            child: Text(
              browser
                  ? 'Use original browser question'
                  : 'Use portable question',
            ),
          ),
        ],
      ];
    }
    final step = state.step!;
    final plan = state.plan!;
    final skill = _controller.curriculum.skill(step.skillId);
    final q = _controller.question;
    final remaining = _controller.remaining;
    return [
      Text(
        '${remaining.inMinutes}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')} remaining'
        ' · Step ${state.stepIndex + 1}/${plan.steps.length}',
      ),
      ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: const Text('Your plan'),
        children: [
          Text(plan.reason),
          const Text('Recall • Learn • Practise • Reflect'),
        ],
      ),
      if (step.kind == StudyStepKind.learn) ...[
        Text(skill.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Text(skill.lesson),
        const SizedBox(height: 12),
        Text(skill.example),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _controller.busy
              ? null
              : () {
                  unawaited(_controller.continueStep());
                },
          child: const Text('Continue to practice'),
        ),
      ] else if (step.kind == StudyStepKind.reflection) ...[
        Text(
          'Reflect on your session',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const Text(
          'Which method helped? What would you try differently next time? '
          'Review your progress before choosing another chunk.',
        ),
        for (final choice in [
          (StudyCompletionChoice.stop, 'Stop for now'),
          if (!plan.isDiagnostic) ...[
            (StudyCompletionChoice.repeat, 'Repeat this focus'),
            (StudyCompletionChoice.continueTopic, 'Continue this topic'),
            (StudyCompletionChoice.review, 'Review what’s due'),
            (StudyCompletionChoice.challenge, 'Mixed challenge'),
          ],
        ])
          choice.$1 == StudyCompletionChoice.stop
              ? FilledButton(
                  onPressed: _controller.busy
                      ? null
                      : () => unawaited(_controller.complete(choice.$1)),
                  child: Text(choice.$2),
                )
              : OutlinedButton(
                  onPressed: _controller.busy
                      ? null
                      : () => unawaited(_controller.complete(choice.$1)),
                  child: Text(choice.$2),
                ),
      ] else if (q != null) ...[
        if (state.phase == StudyPhase.correction)
          const Text('Correct this answer')
        else if (state.phase == StudyPhase.retest)
          const Text('Try another without help')
        else
          Text(plan.isDiagnostic ? 'Starting-point check' : skill.title),
        const SizedBox(height: 8),
        Text(q.prompt, style: Theme.of(context).textTheme.headlineSmall),
        if (q.inputGuidance != null) Text(q.inputGuidance!),
        const SizedBox(height: 12),
        if (state.phase != StudyPhase.correction && state.hintCount == 0) ...[
          const Text('Optional confidence'),
          Wrap(
            spacing: 8,
            children: [
              for (final rating in ConfidenceRating.values)
                ChoiceChip(
                  label: Text(
                    '${rating.name[0].toUpperCase()}${rating.name.substring(1)}',
                  ),
                  selected: state.confidence == rating,
                  onSelected: _controller.busy || _controller.needsRetry
                      ? null
                      : (selected) => unawaited(
                          _controller.selectConfidence(
                            selected ? rating : null,
                          ),
                        ),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (q is ReasoningQuestion && state.phase == StudyPhase.correction) ...[
          for (final event
              in _controller.history
                  .where(
                    (e) => e.questionId == q.id && e.kind != AttemptKind.hint,
                  )
                  .toList()
                  .reversed
                  .take(1))
            Text(
              'Credit: ${(q.credit(event.answer) * 100).round()}% — complete the correction to continue.',
            ),
          TextButton(
            onPressed: _controller.busy || _controller.needsRetry
                ? null
                : () => _reviewPrerequisite(q),
            child: const Text('Review prerequisite'),
          ),
        ],
        if (q is ApplicationQuestion)
          ApplicationAnswerEditor(
            question: q,
            draft: state.draft,
            enabled: !_controller.busy && !_controller.needsRetry,
            onChanged: (value) => unawaited(_controller.updateDraft(value)),
          )
        else if (q is ReasoningQuestion && q.kind != ReasoningKind.missing)
          ReasoningAnswerEditor(
            question: q,
            draft: state.draft,
            enabled: !_controller.busy && !_controller.needsRetry,
            onChanged: (value) => unawaited(_controller.updateDraft(value)),
          )
        else if (_controller.isMultipleChoice)
          for (final choice in q.choices)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: state.draft == choice.value
                      ? Theme.of(context).colorScheme.secondaryContainer
                      : null,
                ),
                onPressed: _controller.busy || _controller.needsRetry
                    ? null
                    : () {
                        unawaited(_controller.updateDraft(choice.value));
                      },
                child: Text(choice.value),
              ),
            )
        else
          TextField(
            controller: _answer,
            focusNode: _focus,
            autofocus: true,
            enabled: !_controller.busy && !_controller.needsRetry,
            keyboardType:
                q.format == null || q.format == NumberAnswerFormat.fraction
                ? TextInputType.text
                : const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
            decoration: InputDecoration(labelText: q.answerLabel),
            onChanged: (value) {
              unawaited(_controller.updateDraft(value));
            },
            onSubmitted: (_) {
              unawaited(_submit());
            },
          ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _controller.busy ? null : _submit,
          child: Text(_controller.needsRetry ? 'Retry submission' : 'Submit'),
        ),
        if (!plan.isDiagnostic) ...[
          TextButton(
            onPressed:
                _controller.busy ||
                    _controller.needsRetry ||
                    state.hintCount >= 4
                ? null
                : () {
                    unawaited(_controller.revealHint());
                  },
            child: const Text('Show next hint'),
          ),
          for (final hint in q.hints.take(state.hintCount))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(hint),
            ),
        ],
      ],
      if (Navigator.of(context).canPop())
        TextButton(
          onPressed: () async {
            await _controller.pause();
            if (context.mounted) Navigator.of(context).pop();
          },
          child: const Text('Pause and return'),
        ),
    ];
  }
}
