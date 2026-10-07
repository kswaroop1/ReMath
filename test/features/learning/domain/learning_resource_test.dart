import 'package:flutter_test/flutter_test.dart';
import 'package:remath/src/features/learning/domain/content_pack.dart';

void main() {
  test('a concept card presents a complete offline learning journey', () {
    const card = ConceptCard(
      application: 'Use complements when checking a bill mentally.',
      commonMistake: 'Do not lose the amount moved between the addends.',
      formula: 'a + b = (a + k) + (b - k)',
      hints: HintLadder(
        conceptCue: 'Move an amount from one addend to the other.',
        methodCue: 'Make one addend a multiple of ten.',
        nextStepCue: 'Move 3 from 27 to 43.',
        workedSolution: '43 + 27 = 46 + 24 = 70.',
      ),
      id: 'card.arithmetic.addition.compensation',
      skillId: 'arithmetic.addition',
      summary: 'Compensation makes mental addition easier.',
      title: 'Addition by compensation',
      workedExample: '43 + 27 becomes 46 + 24.',
    );

    expect(card.hints.reveal(HintLevel.concept).text, contains('addend'));
    expect(card.hints.reveal(HintLevel.method).text, contains('multiple'));
    expect(card.hints.reveal(HintLevel.nextStep).text, contains('Move 3'));
    expect(card.hints.reveal(HintLevel.workedSolution).text, contains('70'));
  });

  test('a content pack finds the learning card for a remediation skill', () {
    const card = ConceptCard(
      application: 'Check totals.',
      commonMistake: 'Keep place values aligned.',
      formula: 'a + b',
      hints: HintLadder(
        conceptCue: 'Combine quantities.',
        methodCue: 'Group tens and units.',
        nextStepCue: 'Add the units.',
        workedSolution: '12 + 7 = 19.',
      ),
      id: 'card.arithmetic.addition.foundation',
      skillId: 'arithmetic.addition',
      summary: 'Build addition fluency.',
      title: 'Addition foundations',
      workedExample: '12 + 7 = 19.',
    );
    const pack = ContentPack(
      conceptCards: [card],
      id: 'org.remath.test',
      license: 'CC-BY-4.0',
      schemaVersion: 2,
      skills: [SkillDefinition(id: 'arithmetic.addition', title: 'Addition')],
      templates: [],
      title: 'Test',
      version: '2.0.0',
    );

    expect(pack.conceptCardFor('arithmetic.addition'), same(card));
    expect(() => pack.conceptCardFor('missing.skill'), throwsStateError);
  });
}
