import 'dart:convert';

import 'package:flutter/material.dart';

import '../domain/application_curriculum.dart';

class ApplicationAnswerEditor extends StatelessWidget {
  const ApplicationAnswerEditor({
    required this.question,
    required this.draft,
    required this.enabled,
    required this.onChanged,
    super.key,
  });
  final ApplicationQuestion question;
  final String draft;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> value;
    try {
      final decoded = jsonDecode(draft);
      value = decoded is Map<String, dynamic> ? decoded : {};
    } on FormatException {
      value = {};
    }
    final method = question.methods
        .where((o) => o.id == value['method'])
        .firstOrNull;
    final assumption = question.assumptions
        .where((o) => o.id == value['assumption'])
        .firstOrNull;
    final confirmed =
        value['confirmed'] == true && method != null && assumption != null;
    void change(String key, Object entry) => onChanged(
      jsonEncode({
        ...value,
        key: entry,
        if (key == 'method' || key == 'assumption') 'confirmed': false,
      }),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (confirmed) ...[
          Text('Method: ${method.label}'),
          Text('Assumption: ${assumption.label}'),
          TextFormField(
            key: ValueKey(question.id),
            initialValue: value['value'] is String
                ? value['value'] as String
                : '',
            enabled: enabled,
            autofocus: true,
            decoration: InputDecoration(labelText: question.answerLabel),
            keyboardType: const TextInputType.numberWithOptions(signed: true),
            onChanged: (text) => change('value', text),
          ),
        ] else ...[
          const Text('Choose a method'),
          for (final option in question.methods)
            ChoiceChip(
              label: Text(option.label),
              selected: method == option,
              onSelected: enabled ? (_) => change('method', option.id) : null,
            ),
          const Text('Choose an assumption'),
          for (final option in question.assumptions)
            ChoiceChip(
              label: Text(option.label),
              selected: assumption == option,
              onSelected: enabled
                  ? (_) => change('assumption', option.id)
                  : null,
            ),
          FilledButton(
            onPressed: enabled && method != null && assumption != null
                ? () => change('confirmed', true)
                : null,
            child: const Text('Confirm choices'),
          ),
        ],
      ],
    );
  }
}
