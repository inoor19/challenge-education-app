import 'package:challenge_edu_app/core/api/api_client.dart';
import 'package:challenge_edu_app/core/models/api_models.dart';
import 'package:challenge_edu_app/core/theme/app_theme.dart';
import 'package:challenge_edu_app/features/challenge/providers/challenge_provider.dart';
import 'package:challenge_edu_app/features/challenge/widgets/question_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('loading challenge uses persisted current turn group first', () async {
    final notifier = ChallengeNotifier(
      _ChallengeApiClient(
        challenge: _sessionJson(currentTurnGroupId: 2),
      ),
    );

    await notifier.loadChallenge(77);

    expect(notifier.state.currentGroup?.id, 2);
  });

  test('loading challenge falls back to used question turn restoration',
      () async {
    final notifier = ChallengeNotifier(
      _ChallengeApiClient(
        challenge: _sessionJson(
          currentTurnGroupId: null,
          usedQuestionSelectedGroupId: 1,
        ),
      ),
    );

    await notifier.loadChallenge(77);

    expect(notifier.state.currentGroup?.id, 2);
  });

  testWidgets('wrong text answer does not show a suggested answer',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final notifier = _TestChallengeNotifier(
      ChallengeArenaState(
        session: _challengeSession(),
        currentDiceValue: 1,
        activeQuestion: _challengeQuestion(),
        timerRemaining: 60,
      ),
      api: _ChallengeApiClient(),
    );

    await _pumpQuestionDialog(tester, notifier);

    await tester.tap(find.text('خاطئة'));
    await tester.pumpAndSettle();

    expect(find.text('إجابة خاطئة'), findsOneWidget);
    expect(find.textContaining('الإجابة الصحيحة:'), findsNothing);
  });

  testWidgets('correct text answer does not show the correct answer',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final notifier = _TestChallengeNotifier(
      ChallengeArenaState(
        session: _challengeSession(),
        currentDiceValue: 1,
        activeQuestion: _challengeQuestion(),
        timerRemaining: 60,
      ),
      api: _ChallengeApiClient(),
    );

    await _pumpQuestionDialog(tester, notifier);

    await tester.tap(find.text('صحيحة'));
    await tester.pumpAndSettle();

    expect(find.text('إجابة صحيحة'), findsOneWidget);
    expect(find.text('الإجابة الصحيحة: الرياض'), findsNothing);
  });

  testWidgets('text answer actions place correct on the right in RTL',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final notifier = _TestChallengeNotifier(
      ChallengeArenaState(
        session: _challengeSession(),
        currentDiceValue: 1,
        activeQuestion: _challengeQuestion(),
        timerRemaining: 60,
      ),
      api: _ChallengeApiClient(),
    );

    await _pumpQuestionDialog(tester, notifier);

    final correctCenter = tester.getCenter(find.text('صحيحة'));
    final wrongCenter = tester.getCenter(find.text('خاطئة'));

    expect(correctCenter.dx, greaterThan(wrongCenter.dx));
  });

  test('selected answering group is used and turn advances after it', () async {
    final api = _ChallengeApiClient();
    final notifier = _TestChallengeNotifier(
      ChallengeArenaState(
        session: _challengeSession(),
        currentDiceValue: 1,
        activeQuestion: _challengeQuestion(),
        timerRemaining: 60,
      ),
      api: api,
    );

    notifier.closeQuestion();
    notifier.selectAnsweringGroup(2);
    notifier.openQuestion(_challengeQuestion());
    await notifier.markCorrect();

    expect(api.lastCorrectGroupId, 2);
    expect(notifier.state.currentGroup?.id, 1);
  });

  testWidgets('correct multiple choice answer uses a green background',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final question = _challengeQuestion(
      questionType: 'multiple_choice',
      optionA: 'الرياض',
      optionB: 'جدة',
    );
    final notifier = _TestChallengeNotifier(
      ChallengeArenaState(
        session: _challengeSession(question: question),
        currentDiceValue: 1,
        activeQuestion: question,
        timerRemaining: 60,
      ),
      api: _ChallengeApiClient(),
    );

    await _pumpQuestionDialog(tester, notifier);
    await tester.tap(find.text('الرياض'));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();

    final choice = find.descendant(
      of: find.byKey(const ValueKey('answer-choice-أ')),
      matching: find.byType(AnimatedContainer),
    );
    final choiceContainer = tester.widget<AnimatedContainer>(choice);
    final decoration = choiceContainer.decoration! as BoxDecoration;

    expect(decoration.color, AppTheme.success.withValues(alpha: 0.18));
  });
}

class _TestChallengeNotifier extends ChallengeNotifier {
  _TestChallengeNotifier(
    ChallengeArenaState initial, {
    required ApiClient api,
  }) : super(api) {
    state = initial;
  }
}

class _ChallengeApiClient extends ApiClient {
  final Map<String, dynamic>? challenge;
  int? lastCorrectGroupId;

  _ChallengeApiClient({this.challenge});

  @override
  Future<Map<String, dynamic>> getChallenge(int id) async =>
      challenge ?? _sessionJson();

  @override
  Future<Map<String, dynamic>> markCorrect(
    int challengeId,
    int challengeQuestionId,
    int groupId,
    int diceValue,
  ) async {
    lastCorrectGroupId = groupId;
    return {
      'points_awarded': diceValue,
      'groups': _groupsJson(),
    };
  }

  @override
  Future<void> markWrong(
    int challengeId,
    int challengeQuestionId,
    int groupId,
    int diceValue,
  ) async {}

  @override
  Future<Map<String, dynamic>> completeChallenge(int challengeId) async => {
        'status': 'completed',
      };
}

Future<void> _pumpQuestionDialog(
  WidgetTester tester,
  ChallengeNotifier notifier,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        challengeProvider.overrideWith((ref) => notifier),
      ],
      child: const MaterialApp(
        locale: Locale('ar'),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: QuestionDialog()),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

ChallengeSession _challengeSession({ChallengeQuestionItem? question}) =>
    ChallengeSession(
      id: 77,
      timerSeconds: 60,
      timerEnabled: true,
      status: 'active',
      groups: _groups,
      chapters: const [],
      lessons: const [],
      questions: [question ?? _challengeQuestion()],
    );

ChallengeQuestionItem _challengeQuestion({
  String questionType = 'text',
  String? optionA,
  String? optionB,
}) =>
    ChallengeQuestionItem(
      id: 101,
      sequenceNumber: 1,
      isUsed: false,
      question: Question(
        id: 1,
        lessonId: 1,
        questionText: 'ما عاصمة السعودية؟',
        questionType: questionType,
        optionA: optionA,
        optionB: optionB,
        correctAnswer: 'الرياض',
        level: 'easy',
      ),
    );

const _groups = [
  ChallengeGroup(
    id: 1,
    challengeSessionId: 77,
    name: 'الفريق الأول',
    score: 0,
    sortOrder: 0,
  ),
  ChallengeGroup(
    id: 2,
    challengeSessionId: 77,
    name: 'الفريق الثاني',
    score: 0,
    sortOrder: 1,
  ),
];

Map<String, dynamic> _sessionJson({
  int? currentTurnGroupId,
  int? usedQuestionSelectedGroupId,
}) =>
    {
      'id': 77,
      'grade_section': 'أ',
      'timer_seconds': 60,
      'timer_enabled': true,
      'status': 'active',
      'current_turn_group_id': currentTurnGroupId,
      'groups': _groupsJson(),
      'chapters': const [],
      'lessons': const [],
      'questions': [
        {
          'id': 101,
          'sequence_number': 1,
          'is_used': usedQuestionSelectedGroupId != null,
          'used_at': usedQuestionSelectedGroupId == null
              ? null
              : '2026-05-25T10:00:00.000000Z',
          'answer_status': usedQuestionSelectedGroupId == null ? null : 'wrong',
          'awarded_points': usedQuestionSelectedGroupId == null ? null : 0,
          'last_dice_value': usedQuestionSelectedGroupId == null ? null : 1,
          'selected_group_id': usedQuestionSelectedGroupId,
          'question': {
            'id': 1,
            'lesson_id': 1,
            'question_text': 'ما عاصمة السعودية؟',
            'question_type': 'text',
            'correct_answer': 'الرياض',
            'level': 'easy',
          },
        },
      ],
    };

List<Map<String, dynamic>> _groupsJson() => _groups
    .map(
      (group) => {
        'id': group.id,
        'challenge_session_id': group.challengeSessionId,
        'name': group.name,
        'score': group.score,
        'sort_order': group.sortOrder,
      },
    )
    .toList();
