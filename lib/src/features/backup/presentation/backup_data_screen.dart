import 'package:flutter/material.dart';

import '../application/backup_coordinator.dart';
import '../application/backup_file_transfer.dart';

final class BackupDataScreen extends StatefulWidget {
  const BackupDataScreen({required this.transfer, super.key});

  final BackupFileTransfer transfer;

  @override
  State<BackupDataScreen> createState() => _BackupDataScreenState();
}

final class _BackupDataScreenState extends State<BackupDataScreen> {
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  PendingBackupImport? _pending;
  String? _message;
  bool _busy = false;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _export() async {
    if (_password.text != _confirmation.text) {
      setState(() => _message = 'Passwords do not match.');
      return;
    }
    await _run(() async {
      final saved = await widget.transfer.export(password: _password.text);
      if (mounted) {
        setState(
          () => _message = saved ? 'Backup saved.' : 'Export cancelled.',
        );
      }
    });
  }

  Future<void> _preview() async {
    await _run(() async {
      final pending = await widget.transfer.previewImport(
        password: _password.text,
      );
      if (!mounted) return;
      setState(() {
        _pending = pending;
        _message = pending == null ? 'No backup selected.' : null;
      });
    });
  }

  Future<void> _apply() async {
    final pending = _pending;
    if (pending == null || !pending.preview.canApply) return;
    await _run(() async {
      final result = await widget.transfer.apply(pending);
      if (!mounted) return;
      final count = result.insertedAttemptCount;
      setState(
        () => _message = '$count attempt${count == 1 ? '' : 's'} restored.',
      );
    });
  }

  Future<void> _run(Future<void> Function() operation) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await operation();
    } on Object {
      if (mounted) setState(() => _message = 'Backup could not be processed.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _pending?.preview;
    return Scaffold(
      appBar: AppBar(title: const Text('Backup and recovery')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            key: const ValueKey('backup-password'),
            controller: _password,
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
          ),
          TextField(
            key: const ValueKey('backup-confirm-password'),
            controller: _confirmation,
            decoration: const InputDecoration(labelText: 'Confirm password'),
            obscureText: true,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _export,
            child: const Text('Export encrypted backup'),
          ),
          OutlinedButton(
            onPressed: _busy ? null : _preview,
            child: const Text('Preview backup'),
          ),
          if (preview != null) ...[
            const SizedBox(height: 16),
            Text('${preview.newAttemptCount} new'),
            Text('${preview.duplicateAttemptCount} duplicates'),
            Text('${preview.conflictingAttemptCount} conflicts'),
            FilledButton(
              onPressed: _busy || !preview.canApply ? null : _apply,
              child: const Text('Apply backup'),
            ),
          ],
          if (_message case final message?) ...[
            const SizedBox(height: 16),
            Text(message),
          ],
        ],
      ),
    );
  }
}
