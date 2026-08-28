import 'package:challenge_edu_app/core/api/api_client.dart';
import 'package:challenge_edu_app/core/models/api_models.dart';
import 'package:challenge_edu_app/core/providers/api_provider.dart';
import 'package:challenge_edu_app/core/theme/app_theme.dart';
import 'package:challenge_edu_app/features/setup/providers/setup_provider.dart';
import 'package:challenge_edu_app/features/setup/screens/select_challenge_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('adding true false question selects correct answer without text',
      (tester) async {
    final api = _SetupQuestionApiClient();

    await _pumpChallengeSetup(tester, api);
    await _completeBasicSetup(tester);

    await _tapButton(tester, 'إضافة سؤال');
    await tester.pumpAndSettle();
    await tester.tap(find.text('الدرس الأول').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('اختيار من متعدد').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('صح/خطأ').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'الشمس تشرق نهاراً');
    await tester.tap(find.text('خطأ').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'حفظ'));
    await tester.pumpAndSettle();

    expect(api.lastTeacherQuestionPayload?['question_type'], 'true_false');
    expect(api.lastTeacherQuestionPayload?['correct_answer'], 'خطأ');
  });

  testWidgets('adding multiple choice question uses checked option as answer',
      (tester) async {
    final api = _SetupQuestionApiClient();

    await _pumpChallengeSetup(tester, api);
    await _completeBasicSetup(tester);

    await _tapButton(tester, 'إضافة سؤال');
    await tester.pumpAndSettle();
    await tester.tap(find.text('الدرس الأول').last);
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'اختر عاصمة السعودية');
    await tester.enterText(fields.at(1), 'جدة');
    await tester.enterText(fields.at(2), 'الرياض');
    final correctOption =
        find.byKey(const ValueKey('question-correct-option-b'));
    await tester.ensureVisible(correctOption);
    await tester.pumpAndSettle();
    await tester.tap(correctOption);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'حفظ'));
    await tester.pumpAndSettle();

    expect(api.lastTeacherQuestionPayload?['question_type'], 'multiple_choice');
    expect(api.lastTeacherQuestionPayload?['correct_answer'], 'الرياض');
  });

  testWidgets('adding text question hides and omits the suggested answer',
      (tester) async {
    final api = _SetupQuestionApiClient();

    await _pumpChallengeSetup(tester, api);
    await _completeBasicSetup(tester);

    await _tapButton(tester, 'إضافة سؤال');
    await tester.pumpAndSettle();
    await tester.tap(find.text('الدرس الأول').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('اختيار من متعدد').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('نصي (تصحيح يدوي)').last);
    await tester.pumpAndSettle();

    expect(find.text('الإجابة الصحيحة'), findsNothing);
    await tester.enterText(find.byType(TextField).first, 'اذكر مثالاً');
    await tester.tap(find.widgetWithText(ElevatedButton, 'حفظ'));
    await tester.pumpAndSettle();

    expect(api.lastTeacherQuestionPayload?['question_type'], 'text');
    expect(api.lastTeacherQuestionPayload?['correct_answer'], '');
  });

  testWidgets('multiple choice correct option checkbox has a visible style',
      (tester) async {
    final api = _SetupQuestionApiClient();

    await _pumpChallengeSetup(tester, api);
    await _completeBasicSetup(tester);
    await _tapButton(tester, 'إضافة سؤال');
    await tester.pumpAndSettle();
    await tester.tap(find.text('الدرس الأول').last);
    await tester.pumpAndSettle();

    final checkboxTile = tester.widget<CheckboxListTile>(
      find.descendant(
        of: find.byKey(const ValueKey('question-correct-option-a')),
        matching: find.byType(CheckboxListTile),
      ),
    );

    expect(checkboxTile.activeColor, AppTheme.success);
    expect(checkboxTile.side, isA<BorderSide>());
    expect(checkboxTile.side!.width, 2);
  });
}

class _SetupQuestionApiClient extends ApiClient {
  Map<String, dynamic>? lastTeacherQuestionPayload;

  @override
  Future<List<dynamic>> getSubjects(int gradeId) async => [
        {
          'id': 10,
          'grade_id': gradeId,
          'name': 'رياضيات',
        },
      ];

  @override
  Future<List<dynamic>> getSubjectParts(
    int subjectId, {
    bool includeEmpty = false,
  }) async =>
      [
        {
          'id': 100,
          'subject_id': subjectId,
          'name': 'الجزء الأول',
          'part_number': 1,
          'sort_order': 1,
        },
      ];

  @override
  Future<List<dynamic>> getChapters(
    int subjectId, {
    int? subjectPartId,
  }) async =>
      [
        {
          'id': 1000,
          'subject_id': subjectId,
          'subject_part_id': subjectPartId,
          'name': 'الفصل الأول',
          'sort_order': 1,
        },
      ];

  @override
  Future<List<dynamic>> getLessons(List<int> chapterIds) async => [
        {
          'id': 1,
          'chapter_id': chapterIds.first,
          'name': 'الدرس الأول',
          'sort_order': 1,
        },
      ];

  @override
  Future<List<dynamic>> getQuestions(List<int> lessonIds) async => [
        {
          'id': 1,
          'lesson_id': lessonIds.first,
          'question_text': 'سؤال موجود',
          'question_type': 'text',
          'correct_answer': 'إجابة',
          'level': 'easy',
          'sort_order': 1,
        },
      ];

  @override
  Future<List<dynamic>> getPackageSuggestions({
    int? gradeId,
    int? subjectId,
  }) async =>
      const [];

  @override
  Future<Map<String, dynamic>> createTeacherQuestion(
    Map<String, dynamic> data,
  ) async {
    lastTeacherQuestionPayload = Map<String, dynamic>.of(data);

    return {
      'id': 7000,
      'lesson_id': data['lesson_id'],
      'question_text': data['question_text'],
      'question_type': data['question_type'],
      'option_a': data['option_a'],
      'option_b': data['option_b'],
      'option_c': data['option_c'],
      'option_d': data['option_d'],
      'correct_answer': data['correct_answer'],
      'level': data['level'],
      'sort_order': 1,
    };
  }
}

class _SeededSetupNotifier extends SetupNotifier {
  _SeededSetupNotifier() {
    state = const SetupState(
      selectedGrade: Grade(
        id: 1,
        name: 'الأول',
        sortOrder: 1,
        isActive: true,
      ),
    );
  }
}

Future<void> _pumpChallengeSetup(
  WidgetTester tester,
  ApiClient api,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(api),
        setupProvider.overrideWith((ref) => _SeededSetupNotifier()),
      ],
      child: const MaterialApp(
        locale: Locale('ar'),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: SelectChallengeSetupScreen(),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

Future<void> _completeBasicSetup(WidgetTester tester) async {
  await _tapSetupKey(tester, 'setup-section-card-أ');
  await _tapSetupKey(tester, 'setup-subject-card-10');
  await _tapSetupKey(tester, 'setup-part-card-100');
  await _tapSetupKey(tester, 'setup-chapter-card-1000');
  await _tapSetupKey(tester, 'setup-lesson-card-1');
}

Future<void> _tapSetupKey(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await _scrollUntilBuilt(tester, finder);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _tapButton(WidgetTester tester, String label) async {
  final finder = find.text(label);
  await _scrollUntilBuilt(tester, finder);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

Future<void> _scrollUntilBuilt(WidgetTester tester, Finder finder) async {
  final scrollable = find.byType(Scrollable).first;

  for (var i = 0; i < 8; i++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.drag(scrollable, const Offset(0, 500));
    await tester.pumpAndSettle();
  }

  for (var i = 0; i < 18; i++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.drag(scrollable, const Offset(0, -320));
    await tester.pumpAndSettle();
  }

  expect(finder, findsOneWidget);
}
