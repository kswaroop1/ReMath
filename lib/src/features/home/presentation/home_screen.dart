import 'package:flutter/material.dart';

import '../../learning/domain/arithmetic_question.dart';
import '../../learning/domain/content_pack.dart';
import '../../learning/domain/diagnostic_placement.dart';
import '../../learning/domain/fluency.dart';
import '../../learning/domain/progress_repository.dart';
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
                      ? _buildActiveChunk(context)
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
        FilledButton(
          onPressed: _controller.startChunk,
          child: const Text('Start 15-minute drill'),
        ),
      ],
    ],
  );

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
}
