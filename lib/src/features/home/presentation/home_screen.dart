import 'package:flutter/material.dart';

import '../../learning/domain/progress_repository.dart';
import '../../learning/domain/fluency.dart';
import '../../learning/presentation/learning_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.repository, super.key});
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
    _controller = LearningController(repository: widget.repository)
      ..addListener(_handleControllerChange);
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
                child: _controller.hasActiveSession
                    ? _buildActiveChunk(context)
                    : _buildOverview(context),
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
      FilledButton(
        onPressed: _controller.startChunk,
        child: const Text('Start 15-minute drill'),
      ),
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
          'Question ${question.index + 1} • about $minutes min remaining',
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
        TextField(
          autofocus: true,
          controller: _answerController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Answer',
          ),
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          onSubmitted: (_) => _controller.submitAnswer(),
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _controller.isBusy ? null : _controller.submitAnswer,
          child: const Text('Check answer'),
        ),
        if (_controller.lastAssessment != null) ...[
          const SizedBox(height: 12),
          Text(
            switch (_controller.lastAssessment!.pace) {
              AttemptPace.fluent => 'Correct and fluent',
              AttemptPace.slow => 'Correct — keep building speed',
              AttemptPace.incorrect => 'Not quite — this skill will return soon',
            },
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 20),
        TextButton(
          onPressed: _controller.finishChunk,
          child: const Text('Finish for now'),
        ),
      ],
    );
  }
}
