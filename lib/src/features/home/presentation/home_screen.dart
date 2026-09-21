import 'package:flutter/material.dart';

import '../../backup/application/backup_file_transfer.dart';
import '../../backup/presentation/backup_data_screen.dart';
import '../../learning/domain/arithmetic_question.dart';
import '../../learning/domain/content_pack.dart';
import '../../learning/domain/curriculum_graph.dart';
import '../../learning/domain/diagnostic_placement.dart';
import '../../learning/domain/fluency.dart';
import '../../learning/domain/progress_dashboard.dart';
import '../../learning/domain/progress_repository.dart';
import '../../learning/domain/retained_mastery.dart';
import '../../learning/presentation/learning_controller.dart';
import '../../numbers/presentation/study_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    this.backupTransfer,
    required this.contentPack,
    required this.repository,
    super.key,
  });

  final BackupFileTransfer? backupTransfer;
  final ContentPack contentPack;
  final ProgressRepository repository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final LearningController _controller;
  late final TextEditingController _answerController;
  late final FocusNode _answerFocusNode;
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
    _answerFocusNode = FocusNode();
    _initialised = _controller.initialise();
  }

  Future<void> _submitAnswer() async {
    await _controller.submitAnswer();
    if (mounted && _controller.hasActiveSession && !_controller.isLearning) {
      _answerFocusNode.requestFocus();
    }
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
    _answerFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('ReMath'),
      actions: [
        if (widget.backupTransfer case final transfer?)
          TextButton(
            onPressed: () async {
              await Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => BackupDataScreen(transfer: transfer),
                ),
              );
              if (mounted) await _controller.initialise();
            },
            child: const Text('Backup and recovery'),
          ),
        if (!_controller.hasActiveSession)
          TextButton(
            onPressed: () async {
              await Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => StudyScreen(repository: widget.repository),
                ),
              );
              if (mounted) await _controller.initialise();
            },
            child: const Text('Learning journey'),
          ),
      ],
    ),
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
