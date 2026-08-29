import 'package:flutter/material.dart';

import '../../learning/domain/arithmetic_question.dart';
import '../../learning/domain/content_pack.dart';
import '../../learning/domain/curriculum_graph.dart';
import '../../learning/domain/diagnostic_placement.dart';
import '../../learning/domain/fluency.dart';
import '../../learning/domain/progress_dashboard.dart';
import '../../learning/domain/progress_repository.dart';
import '../../learning/domain/retained_mastery.dart';
import '../../learning/presentation/learning_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.contentPack,
    required this.repository,
    super.key,
  });

  final ContentPack contentPack;
  final ProgressRepository repository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final LearningController _controller;
  late final TextEditingController _answerController;
  late final Future<void> _initialised;
  bool _showCurriculum = false;
  bool _showProgress = false;
  String? _selectedProgressSkillId;

  @override
  void initState() {
    super.initState();
    _controller = LearningController(
      contentPack: widget.contentPack,
      repository: widget.repository,
    )..addListener(_handleControllerChange);
    _answerController = TextEditingController()
      ..addListener(() => _controller.updateDraft(_answerController.text));
    _initialised = _controller.initialise();
  }

  void _handleControllerChange() {
    if (!mounted) {
      return;
    }
    final draft = _controller.answerDraft;
    if (_answerController.text != draft) {
      _answerController.value = TextEditingValue(
        text: draft,
        selection: TextSelection.collapsed(offset: draft.length),
      );
    }
    setState(() {});
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleControllerChange)
      ..dispose();
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('ReMath')),
    body: FutureBuilder<void>(
      future: _initialised,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('Could not open local progress data.'),
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        return SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: _controller.hasActiveSession
                      ? _controller.isLearning
                            ? _buildLearnChunk(context)
                            : _buildActiveChunk(context)
                      : _showCurriculum
                      ? _buildCurriculum(context)
                      : _selectedProgressSkillId != null
                      ? _buildSkillHistory(context, _selectedProgressSkillId!)
                      : _showProgress
                      ? _buildProgressDashboard(context)
                      : _buildOverview(context),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );

  Widget _buildOverview(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Mental arithmetic foundation',
        style: Theme.of(context).textTheme.headlineMedium,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 12),
      Text(
        '${_controller.mastery.attempts} attempts • '
        '${(_controller.mastery.accuracy * 100).round()}% accuracy',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 20),
      ..._controller.fluency.map(
        (skill) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(child: Text(skill.operation.label)),
              Text('${(skill.score * 100).round()}% fluent'),
            ],
          ),
        ),
      ),
      const SizedBox(height: 32),
      if (_controller.reviewRecommendations.isNotEmpty) ...[
        Text(
          '${_controller.reviewRecommendations.length} '
          '${_controller.reviewRecommendations.length == 1 ? 'review' : 'reviews'} due',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        for (final recommendation in _controller.reviewRecommendations)
          Text(recommendation.reason, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        FilledButton.tonal(
          onPressed: _controller.startReviewChunk,
          child: const Text('Start review chunk'),
        ),
        const SizedBox(height: 20),
      ],
      if (_controller.remediationRecommendation case final recommendation?) ...[
        Text(
          'Suggested review',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(recommendation.reason, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        FilledButton.tonal(
          onPressed: () =>
              _controller.startLearn(recommendation.recommendedSkillId),
          child: Text(
            'Review ${_skillLabel(recommendation.recommendedSkillId)}',
          ),
        ),
        const SizedBox(height: 20),
      ],
      if (_controller.hasEndOfChunkChoices) ...[
        Text(
          'Chunk complete',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _controller.continueSameSkill,
          child: const Text('Continue same skill'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _controller.practiseWeakestSkill,
          child: const Text('Practise weakest skill'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _controller.startChunk,
          child: const Text('Another mixed drill'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _controller.stopAfterChunk,
          child: const Text('Done for now'),
        ),
      ] else ...[
        if (_controller.diagnosticPlacements.isNotEmpty) ...[
          Text(
            'Your starting points',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ..._controller.diagnosticPlacements.map(
            (placement) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${placement.operation.label}: ${_placementLabel(placement.level)}\n'
                '${placement.reason}',
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        OutlinedButton(
          onPressed: _controller.startDiagnostic,
          child: const Text('Find my starting point'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => setState(() => _showCurriculum = true),
          child: const Text('Explore curriculum'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => _controller.startLearn('arithmetic.addition'),
          child: const Text('Learn addition'),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _controller.startChunk,
          child: const Text('Start 15-minute drill'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => setState(() => _showProgress = true),
          child: const Text('View progress'),
        ),
      ],
    ],
  );

  Widget _buildProgressDashboard(BuildContext context) {
    final dashboard = _controller.progressDashboard;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Progress dashboard',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          dashboard.independentAttempts == 0
              ? 'No independent practice yet'
              : '${dashboard.independentAttempts} independent • '
                    '${dashboard.assistedEvents} assisted',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(_practiceTime(dashboard.totalTime), textAlign: TextAlign.center),
        const SizedBox(height: 20),
        for (final skill in dashboard.skills) ...[
          _buildSkillProgress(context, skill),
          const SizedBox(height: 12),
        ],
        Text(
          'Goal readiness',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        for (final line in _goalReadinessLines())
          Text(line, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() => _showProgress = false),
          child: const Text('Back'),
        ),
      ],
    );
  }

  Widget _buildSkillProgress(BuildContext context, SkillProgress skill) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(skill.label, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (skill.independentAttempts == 0)
            const Text('No evidence yet')
          else ...[
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                Text('${_percent(skill.knowledgeMastery!)} knowledge'),
                Text('${_percent(skill.performanceMastery!)} performance'),
                Text('${_percent(skill.independentAccuracy!)} accuracy'),
              ],
            ),
            const SizedBox(height: 8),
            Text(_retentionLabel(skill)),
            Text(_riskLabel(skill)),
            Text(skill.reviewExplanation),
            if (skill.assistedEvents > 0)
              Text('${skill.assistedEvents} assisted learning event(s)'),
          ],
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () =>
                setState(() => _selectedProgressSkillId = skill.skillId),
            child: Text('View ${skill.label} history'),
          ),
        ],
      ),
    ),
  );

  Widget _buildSkillHistory(BuildContext context, String skillId) {
    final skill = _controller.progressDashboard.skills.singleWhere(
      (candidate) => candidate.skillId == skillId,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${skill.label} history',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(skill.reviewExplanation, textAlign: TextAlign.center),
        const SizedBox(height: 20),
        if (skill.history.isEmpty)
          const Text('No attempts recorded for this skill.')
        else
          for (final entry in skill.history)
            Card(
              child: ListTile(
                title: Text(entry.title),
                subtitle: Text(entry.explanation),
              ),
            ),
        TextButton(
          onPressed: () => setState(() => _selectedProgressSkillId = null),
          child: const Text('Back to progress'),
        ),
      ],
    );
  }

  String _practiceTime(Duration duration) {
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes} min practised';
    }
    return '${duration.inSeconds} sec practised';
  }

  String _retentionLabel(SkillProgress skill) => switch (skill.retentionState) {
    RetainedMasteryState.unattempted => 'Retention: no evidence',
    RetainedMasteryState.learning =>
      'Retention: ${skill.successfulOccasions} of 3 delayed successes',
    RetainedMasteryState.retained => 'Retention confirmed',
    RetainedMasteryState.lapsed => 'Retention lapsed',
  };

  String _riskLabel(SkillProgress skill) {
    final risk = skill.forgettingRisk;
    if (risk == null) {
      return 'Forgetting risk: no evidence';
    }
    if (risk >= 1) {
      return 'Review overdue';
    }
    return '${_percent(risk)} forgetting risk';
  }

  String _percent(double value) => '${(value * 100).round()}%';

  List<String> _goalReadinessLines() {
    final graph = _controller.curriculumGraph;
    final mastered = _controller.masteredSkillIds;
    return graph.goals
        .map((goal) {
          final skills = graph.skillsForGoal(goal.id);
          final ready = skills
              .where((skill) => mastered.contains(skill.id))
              .length;
          return '${goal.title}: $ready of ${skills.length} skills ready';
        })
        .toList(growable: false);
  }

  Widget _buildCurriculum(BuildContext context) {
    final graph = _controller.curriculumGraph;
    final mastered = _controller.masteredSkillIds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Curriculum map',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        for (final goal in graph.goals) ...[
          Text(goal.title, style: Theme.of(context).textTheme.titleLarge),
          Text(
            graph
                .skillsForGoal(goal.id)
                .map((skill) => skill.title)
                .join(' • '),
          ),
          const SizedBox(height: 16),
        ],
        for (final skill in graph.skills) ...[
          _buildCurriculumSkill(context, graph, skill, mastered),
          const SizedBox(height: 12),
        ],
        TextButton(
          onPressed: () => setState(() => _showCurriculum = false),
          child: const Text('Back'),
        ),
      ],
    );
  }

  Widget _buildCurriculumSkill(
    BuildContext context,
    CurriculumGraph graph,
    SkillDefinition skill,
    Set<String> mastered,
  ) {
    final readiness = graph.readinessFor(skill.id, masteredSkillIds: mastered);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(skill.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(readiness.reason),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => _controller.startLearn(skill.id),
              child: Text(
                readiness.isRecommended
                    ? 'Learn ${skill.title.toLowerCase()}'
                    : 'Explore ${skill.title.toLowerCase()} anyway',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLearnChunk(BuildContext context) {
    final card = _controller.conceptCard!;
    final hints = _controller.revealedHints;
    final nextLevel = hints.length < HintLevel.values.length
        ? HintLevel.values[hints.length]
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          card.title,
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(card.summary, textAlign: TextAlign.center),
        const SizedBox(height: 20),
        Text('Formula', style: Theme.of(context).textTheme.titleMedium),
        Text(card.formula),
        const SizedBox(height: 16),
        Text('Worked example', style: Theme.of(context).textTheme.titleMedium),
        Text(card.workedExample),
        const SizedBox(height: 16),
        Text('Common mistake', style: Theme.of(context).textTheme.titleMedium),
        Text(card.commonMistake),
        const SizedBox(height: 16),
        Text(
          'When this is useful',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(card.application),
        for (final hint in hints) ...[
          const SizedBox(height: 12),
          Text(hint.text),
        ],
        if (nextLevel != null) ...[
          const SizedBox(height: 20),
          FilledButton.tonal(
            onPressed: _controller.revealNextHint,
            child: Text('Show ${_hintLabel(nextLevel)} hint'),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _controller.finishChunk,
          child: const Text('Finish learning'),
        ),
      ],
    );
  }

  Widget _buildActiveChunk(BuildContext context) {
    final question = _controller.currentQuestion!;
    final minutes = _controller.remaining.inMinutes;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _controller.isCorrecting
              ? 'Correct this answer'
              : _controller.isRetesting
              ? 'Retest this skill'
              : _controller.isDiagnostic
              ? 'Diagnostic question ${question.index + 1} of 9'
              : _controller.isReviewing
              ? 'Review • ${question.operation.label}'
              : 'Question ${question.index + 1} • about $minutes min remaining',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Text(
          question.prompt,
          key: const Key('questionPrompt'),
          style: Theme.of(context).textTheme.displaySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        if (_controller.correctionPrompt case final prompt?) ...[
          Text(
            'Correct answer: ${prompt.correctAnswer}',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(prompt.explanation, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text(
            'Enter the correct answer to continue.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
        ],
        TextField(
          autofocus: true,
          controller: _answerController,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: _controller.isCorrecting ? 'Correct answer' : 'Answer',
          ),
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          onSubmitted: (_) => _controller.submitAnswer(),
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _controller.isBusy ? null : _controller.submitAnswer,
          child: Text(
            _controller.isCorrecting
                ? 'Submit correction'
                : _controller.isRetesting
                ? 'Check retest'
                : 'Check answer',
          ),
        ),
        if (_controller.lastAssessment != null &&
            !_controller.isCorrecting &&
            !_controller.isRetesting) ...[
          const SizedBox(height: 12),
          Text(switch (_controller.lastAssessment!.pace) {
            AttemptPace.fluent => 'Correct and fluent',
            AttemptPace.slow => 'Correct — keep building speed',
            AttemptPace.incorrect => 'Not quite — this skill will return soon',
          }, textAlign: TextAlign.center),
        ],
        const SizedBox(height: 20),
        TextButton(
          onPressed: _controller.finishChunk,
          child: const Text('Finish for now'),
        ),
      ],
    );
  }

  String _placementLabel(DiagnosticPlacementLevel level) => switch (level) {
    DiagnosticPlacementLevel.moreEvidenceNeeded => 'More evidence needed',
    DiagnosticPlacementLevel.rebuildFundamentals => 'Rebuild fundamentals',
    DiagnosticPlacementLevel.practiseSpeed => 'Practise speed',
    DiagnosticPlacementLevel.readyToProgress => 'Ready to progress',
  };

  String _hintLabel(HintLevel level) => switch (level) {
    HintLevel.concept => 'concept',
    HintLevel.method => 'method',
    HintLevel.nextStep => 'next-step',
    HintLevel.workedSolution => 'worked-solution',
  };

  String _skillLabel(String skillId) =>
      ArithmeticOperationDefinition.fromSkillId(skillId)?.label.toLowerCase() ??
      'this skill';
}
