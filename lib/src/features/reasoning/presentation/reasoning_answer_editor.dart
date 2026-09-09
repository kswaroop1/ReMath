import 'dart:convert';

import 'package:flutter/material.dart';

import '../domain/reasoning_curriculum.dart';

class ReasoningAnswerEditor extends StatelessWidget {
  const ReasoningAnswerEditor({
    required this.question,
    required this.draft,
    required this.onChanged,
    required this.enabled,
    super.key,
  });
  final ReasoningQuestion question;
  final String draft;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    Object? value;
    try {
      value = jsonDecode(draft);
    } on FormatException {
      value = null;
    }
    final selected = value is List
        ? value
              .whereType<String>()
              .where((id) => question.options.any((o) => o.id == id))
              .toSet()
              .toList()
        : <String>[];
    final diagnosis = value is Map<String, dynamic>
        ? value
        : <String, dynamic>{};
    void choose(String step, String category) =>
        onChanged(jsonEncode({'step': step, 'category': category}));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (question.kind == ReasoningKind.order) ...[
          for (var i = 0; i < selected.length; i++)
            ListTile(
              title: Text(
                '${i + 1}. ${question.options.firstWhere((o) => o.id == selected[i]).label}',
              ),
              trailing: IconButton(
                tooltip: 'Remove step ${i + 1}',
                icon: const Icon(Icons.close),
                onPressed: enabled
                    ? () {
                        final next = List<String>.of(selected)..removeAt(i);
                        onChanged(jsonEncode(next));
                      }
                    : null,
              ),
            ),
          for (final option in question.options.where(
            (o) => !selected.contains(o.id),
          ))
            OutlinedButton(
              onPressed: enabled
                  ? () => onChanged(jsonEncode([...selected, option.id]))
                  : null,
              child: Text(option.label),
            ),
        ] else if (question.kind == ReasoningKind.select) ...[
          for (final option in question.options)
            CheckboxListTile(
              title: Text(option.label),
              value: selected.contains(option.id),
              onChanged: enabled
                  ? (checked) {
                      final next = List<String>.of(selected);
                      if (checked == true) {
                        next.add(option.id);
                      } else {
                        next.remove(option.id);
                      }
                      onChanged(jsonEncode(next));
                    }
                  : null,
            ),
        ] else ...[
          for (final option in question.options)
            OutlinedButton(
              onPressed: enabled
                  ? () => choose(
                      option.id,
                      diagnosis['category'] is String
                          ? diagnosis['category'] as String
                          : '',
                    )
                  : null,
              style: OutlinedButton.styleFrom(
                backgroundColor: diagnosis['step'] == option.id
                    ? Theme.of(context).colorScheme.secondaryContainer
                    : null,
              ),
              child: Text(option.label),
            ),
          Wrap(
            spacing: 8,
            children: [
              for (final category in ReasoningQuestion.categories)
                ChoiceChip(
                  label: Text(category),
                  selected: diagnosis['category'] == category,
                  onSelected: enabled
                      ? (_) => choose(
                          diagnosis['step'] is String
                              ? diagnosis['step'] as String
                              : '',
                          category,
                        )
                      : null,
                ),
            ],
          ),
        ],
      ],
    );
  }
}
