import '../../learning/domain/numeric_answer_contract.dart';

final class NumberChoice {
  const NumberChoice(this.value, this.misconception);
  final String value;
  final String? misconception;
}

enum NumberAnswerFormat { integer, fraction, decimal }

/// Shared learner-facing question contract; numeric format is absent for algebra.
abstract interface class StudyQuestion {
  String get id;
  String get skillId;
  String get prompt;
  String get answer;
  List<String> get hints;
  List<NumberChoice> get choices;
  NumberAnswerFormat? get format;
  String? get inputGuidance;
  String get answerLabel;
  String get invalidInputMessage;
  AnswerMark mark(String input);
}
