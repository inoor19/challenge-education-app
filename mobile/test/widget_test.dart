import 'dart:async';

import 'package:challenge_edu_app/core/theme/app_theme.dart';
import 'package:challenge_edu_app/core/api/api_client.dart';
import 'package:challenge_edu_app/core/models/api_models.dart';
import 'package:challenge_edu_app/core/providers/api_provider.dart';
import 'package:challenge_edu_app/features/auth/providers/auth_provider.dart';
import 'package:challenge_edu_app/features/auth/screens/login_screen.dart';
import 'package:challenge_edu_app/features/auth/screens/splash_screen.dart';
import 'package:challenge_edu_app/features/challenge/providers/challenge_provider.dart';
import 'package:challenge_edu_app/features/challenge/screens/challenge_arena_screen.dart';
import 'package:challenge_edu_app/features/challenge/screens/saved_challenges_screen.dart';
import 'package:challenge_edu_app/features/packages/providers/package_provider.dart';
import 'package:challenge_edu_app/features/packages/screens/packages_screen.dart';
import 'package:challenge_edu_app/features/packages/services/iap_service.dart';
import 'package:challenge_edu_app/features/setup/providers/setup_provider.dart';
import 'package:challenge_edu_app/features/setup/screens/select_challenge_setup_screen.dart';
import 'package:challenge_edu_app/features/setup/screens/select_questions_screen.dart';
import 'package:challenge_edu_app/features/setup/screens/setup_groups_screen.dart';
import 'package:challenge_edu_app/features/teacher_content/screens/manage_content_screen.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('theme uses Tajawal and supports RTL text', (tester) async {
    final theme = AppTheme.light();

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        locale: const Locale('ar'),
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: Text('ساحة التنافس'),
        ),
      ),
    );

    final textContext = tester.element(find.text('ساحة التنافس'));

    expect(theme.textTheme.bodyLarge?.fontFamily, 'Tajawal');
    expect(theme.appBarTheme.titleTextStyle?.fontFamily, 'Tajawal');
    expect(Directionality.of(textContext), TextDirection.rtl);
  });

  testWidgets('splash shows onboarding once and stores skip preference',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => _TestAuthNotifier()),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: SplashScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('حوّل الدرس إلى منافسة حية'), findsOneWidget);

    await tester.tap(find.text('تخطي'));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(SplashScreen.onboardingCompletedKey), isTrue);
  });

  testWidgets('auth screen switches to register fields', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => _TestAuthNotifier()),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: LoginScreen(),
          ),
        ),
      ),
    );

    await tester.tap(find.text('حساب جديد'));
    await tester.pumpAndSettle();

    expect(find.text('إنشاء حساب جديد'), findsOneWidget);
    expect(find.text('اسم المعلم'), findsOneWidget);
    expect(find.text('تأكيد كلمة المرور'), findsOneWidget);
  });

  testWidgets('content manager explains readiness and locks later steps',
      (tester) async {
    await _pumpContentManager(tester, _FakeApiClient());

    expect(
      find.text(
        'لن يظهر الصف في الرئيسية إلا بعد إضافة مادة وفصل ودرس وسؤال واحد على الأقل.',
      ),
      findsOneWidget,
    );
    expect(find.text('اختر صفاً أولاً لإضافة مادة.'), findsOneWidget);
    expect(find.text('إنشاء صفوف واسئلة'), findsOneWidget);
  });

  testWidgets('saving grade shows homepage readiness guidance', (tester) async {
    final api = _FakeApiClient(teacherGrades: <dynamic>[]);

    await _pumpContentManager(tester, api);
    await tester.enterText(
      find.byKey(const ValueKey('content-grade-name')),
      'الصف التجريبي',
    );
    await tester.tap(find.text('حفظ الصف'));
    await tester.pumpAndSettle();

    expect(api.teacherGrades.length, 1);
    expect(find.text('الصف التجريبي'), findsWidgets);
    expect(
      find.text(
        'تم حفظ الصف في محتواك. سيظهر في الرئيسية بعد إضافة مادة وفصل ودرس وسؤال واحد على الأقل.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
      'content manager filters dependent lists and advances after saves',
      (tester) async {
    final api = _FakeApiClient(
      teacherGrades: <dynamic>[
        _gradeJson(1, 'الأول'),
        _gradeJson(2, 'الثاني'),
      ],
      teacherSubjects: <dynamic>[
        {'id': 10, 'grade_id': 1, 'name': 'رياضيات'},
        {'id': 20, 'grade_id': 2, 'name': 'علوم'},
      ],
      teacherPartsBySubject: {
        10: <dynamic>[_partJson(100, 10, 'الجزء الأول')],
        20: <dynamic>[_partJson(200, 20, 'الجزء الأول')],
      },
      teacherChapters: <dynamic>[
        _chapterJson(1000, 10, 100, 'الفصل الموجود'),
        _chapterJson(2000, 20, 200, 'فصل العلوم'),
      ],
      teacherLessons: <dynamic>[
        _lessonJson(3000, 1000, 'درس موجود'),
      ],
      teacherQuestions: <dynamic>[
        _questionJson(4000, 3000, 'سؤال موجود'),
      ],
    );

    await _pumpContentManager(tester, api);

    expect(find.text('رياضيات'), findsOneWidget);
    expect(find.text('علوم'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('content-subject-name')),
      'لغتي',
    );
    await _tapButton(tester, 'حفظ المادة');
    await tester.pumpAndSettle();

    expect(find.text('لغتي'), findsWidgets);
    expect(find.text('الجزء الأول'), findsWidgets);

    await _scrollUntilBuilt(
      tester,
      find.byKey(const ValueKey('content-chapter-name')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('content-chapter-name')),
      'الفصل الأول',
    );
    await _tapButton(tester, 'حفظ الفصل');
    await tester.pumpAndSettle();

    expect(find.text('الفصل الأول'), findsWidgets);

    await _scrollUntilBuilt(
      tester,
      find.byKey(const ValueKey('content-lesson-name')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('content-lesson-name')),
      'الدرس الأول',
    );
    await _tapButton(tester, 'حفظ الدرس');
    await tester.pumpAndSettle();

    expect(find.text('الدرس الأول'), findsWidgets);

    await _scrollUntilBuilt(
      tester,
      find.byKey(const ValueKey('content-question-text')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('content-question-text')),
      'ما عاصمة السعودية؟',
    );
    await tester.enterText(
      find.byKey(const ValueKey('content-correct-answer')),
      'الرياض',
    );
    await _tapButton(tester, 'حفظ السؤال');
    await tester.pumpAndSettle();

    expect(api.teacherQuestions.length, 2);
    expect(find.text('أسئلة الدرس المحدد: 1'), findsOneWidget);
  });

  testWidgets('question selection defaults to all and can toggle all',
      (tester) async {
    final api = _FakeApiClient(questionList: _questionJsonList());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(api),
          setupProvider.overrideWith(
            (ref) => _TestSetupNotifier(_setupState()),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: SelectQuestionsScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('2 سؤال محدد'), findsOneWidget);

    await tester.tap(find.text('إلغاء تحديد الكل'));
    await tester.pumpAndSettle();

    expect(find.text('اختر سؤالاً واحداً على الأقل'), findsOneWidget);

    await tester.tap(find.text('سؤال 1'));
    await tester.pumpAndSettle();

    expect(find.text('1 سؤال محدد'), findsOneWidget);
  });

  testWidgets('challenge setup reveals dependent selection grids',
      (tester) async {
    final notifier = _TestSetupNotifier(
      const SetupState(
        selectedGrade:
            Grade(id: 1, name: 'الأول', sortOrder: 1, isActive: true),
      ),
    );
    final api = _FakeApiClient(
      subjects: _subjectJsonList(),
      partsBySubject: {10: _partJsonList(10)},
      chaptersBySubjectPart: {100: _chapterJsonList()},
      lessonsByChapter: {1000: _lessonJsonList()},
      questionList: _questionJsonList(),
    );

    await _pumpChallengeSetup(tester, api, notifier);

    expect(find.byKey(const ValueKey('setup-subject-card-10')), findsNothing);

    await _tapSetupKey(tester, 'setup-section-card-أ');
    await tester.pumpAndSettle();

    await _tapSetupKey(tester, 'setup-subject-card-10');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('setup-part-card-100')), findsOneWidget);

    await _tapSetupKey(tester, 'setup-part-card-100');
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey('setup-chapter-card-1000')), findsOneWidget);

    await _tapSetupKey(tester, 'setup-chapter-card-1000');
    await _tapSetupKey(tester, 'setup-chapter-card-2000');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('setup-lesson-card-1')), findsOneWidget);

    await _tapSetupKey(tester, 'setup-lesson-card-1');
    await tester.pumpAndSettle();

    await _waitForSetupState(
      tester,
      () => notifier.state.selectedQuestions.length == 2,
    );
    expect(notifier.state.selectedQuestions.length, 2);
    final nextButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'إعداد الفرق'),
    );
    expect(nextButton.onPressed, isNotNull);
  });

  testWidgets('changing subject clears dependent setup selections',
      (tester) async {
    final notifier = _TestSetupNotifier(
      const SetupState(
        selectedGrade:
            Grade(id: 1, name: 'الأول', sortOrder: 1, isActive: true),
      ),
    );
    final api = _FakeApiClient(
      subjects: _subjectJsonList(),
      partsBySubject: {10: _partJsonList(10), 20: _partJsonList(20)},
      chaptersBySubjectPart: {100: _chapterJsonList()},
      lessonsByChapter: {1000: _lessonJsonList()},
      questionList: _questionJsonList(),
    );

    await _pumpChallengeSetup(tester, api, notifier);
    await _completeBasicSetup(tester);

    expect(notifier.state.isReadyToChallenge, isTrue);

    await _tapSetupKey(tester, 'setup-subject-card-20');
    await tester.pumpAndSettle();

    expect(notifier.state.selectedSubject?.name, 'علوم');
    expect(notifier.state.selectedSubjectPart, isNull);
    expect(notifier.state.selectedChapters, isEmpty);
    expect(notifier.state.selectedLessons, isEmpty);
    expect(notifier.state.selectedQuestions, isEmpty);

    final nextButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'إعداد الفرق'),
    );
    expect(nextButton.onPressed, isNull);
  });

  testWidgets('question grid can clear auto-selected questions',
      (tester) async {
    final notifier = _TestSetupNotifier(
      const SetupState(
        selectedGrade:
            Grade(id: 1, name: 'الأول', sortOrder: 1, isActive: true),
      ),
    );
    final api = _FakeApiClient(
      subjects: _subjectJsonList(),
      partsBySubject: {10: _partJsonList(10)},
      chaptersBySubjectPart: {100: _chapterJsonList()},
      lessonsByChapter: {1000: _lessonJsonList()},
      questionList: _questionJsonList(),
    );

    await _pumpChallengeSetup(tester, api, notifier);
    await _completeBasicSetup(tester);

    await _waitForSetupState(
      tester,
      () => notifier.state.selectedQuestions.length == 2,
    );
    expect(notifier.state.selectedQuestions.length, 2);

    await _tapSetupKey(tester, 'setup-question-card-toggle-all');
    await tester.pumpAndSettle();

    expect(notifier.state.selectedQuestions, isEmpty);
    final nextButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'إعداد الفرق'),
    );
    expect(nextButton.onPressed, isNull);
    expect(find.byTooltip('شراء أسئلة إضافية'), findsNothing);
  });

  testWidgets(
      'challenge setup suggests package purchase when grade has no subjects',
      (tester) async {
    final notifier = _TestSetupNotifier(
      const SetupState(
        selectedGrade:
            Grade(id: 1, name: 'الأول', sortOrder: 1, isActive: true),
      ),
    );
    final api = _FakeApiClient(
      subjects: const [],
      packageSuggestions: [_packageSuggestionJson()],
    );

    await _pumpChallengeSetup(tester, api, notifier);
    await _tapSetupKey(tester, 'setup-section-card-أ');
    await tester.pumpAndSettle();

    expect(find.text('شراء حزم الأسئلة'), findsWidgets);
    final buyButton =
        find.byKey(const ValueKey('setup-buy-packages-empty-subjects'));
    expect(buyButton, findsOneWidget);

    await tester.ensureVisible(buyButton);
    await tester.pumpAndSettle();
    await tester.tap(buyButton);
    await tester.pumpAndSettle();

    expect(find.text('حزمة إضافية للرياضيات'), findsOneWidget);
  });

  testWidgets('question section shows package suggestion as last grid card',
      (tester) async {
    final notifier = _TestSetupNotifier(
      const SetupState(
        selectedGrade:
            Grade(id: 1, name: 'الأول', sortOrder: 1, isActive: true),
      ),
    );
    final api = _FakeApiClient(
      subjects: _subjectJsonList(),
      partsBySubject: {10: _partJsonList(10)},
      chaptersBySubjectPart: {100: _chapterJsonList()},
      lessonsByChapter: {1000: _lessonJsonList()},
      questionList: _questionJsonList(),
      packageSuggestions: [_packageSuggestionJson()],
    );

    await _pumpChallengeSetup(tester, api, notifier);
    await _completeBasicSetup(tester);

    await _waitForSetupState(
      tester,
      () => notifier.state.selectedQuestions.length == 2,
    );

    final suggestionCard =
        find.byKey(const ValueKey('setup-question-package-suggestions'));
    await _scrollUntilBuilt(tester, suggestionCard);
    expect(suggestionCard, findsOneWidget);
    expect(find.text('شراء أسئلة إضافية لهذه المادة'), findsOneWidget);
    expect(find.text('يفتح قائمة حزم المادة'), findsOneWidget);
    expect(find.byTooltip('شراء أسئلة إضافية'), findsNothing);

    await tester.ensureVisible(suggestionCard);
    await tester.pumpAndSettle();
    await tester.tap(suggestionCard);
    await tester.pumpAndSettle();

    expect(find.text('الأول (1 مادة)'), findsOneWidget);
    expect(find.text('رياضيات (1)'), findsOneWidget);
    expect(find.text('حزمة إضافية للرياضيات'), findsOneWidget);
  });

  test('challenge creation sends selected question ids', () async {
    final api = _FakeApiClient(groups: _testGroups);
    final notifier = ChallengeNotifier(api);

    await notifier.createChallenge(
      setup: _setupState(
        selectedQuestions: const [
          Question(
            id: 11,
            lessonId: 1,
            questionText: 'سؤال مختار',
            questionType: 'text',
            correctAnswer: 'إجابة',
            level: 'easy',
          ),
        ],
      ),
      groupNames: const ['المجموعة الأولى', 'المجموعة الثانية'],
      timerSeconds: 60,
      timerEnabled: true,
    );

    expect(api.lastCreatePayload?['question_ids'], [11]);
    expect(api.lastCreatePayload?['grade_section'], 'أ');
  });

  test('question dialog starts timer after dice roll', () async {
    final enabledNotifier = _TestChallengeNotifier(
      ChallengeArenaState(
        session: _challengeSession(
          questionCount: 1,
          hardThrough: 0,
          groups: _testGroups,
        ),
        timerRemaining: 60,
      ),
      api: _FakeApiClient(diceValue: 3),
    );

    await enabledNotifier.rollDice();

    expect(enabledNotifier.state.currentDiceValue, 3);
    expect(enabledNotifier.state.timerRunning, isFalse);

    enabledNotifier.openQuestion(enabledNotifier.state.questions.first);

    expect(enabledNotifier.state.timerRunning, isTrue);
    enabledNotifier.pauseTimer();

    final disabledNotifier = _TestChallengeNotifier(
      ChallengeArenaState(
        session: _challengeSession(
          questionCount: 1,
          hardThrough: 0,
          groups: _testGroups,
          timerEnabled: false,
        ),
        timerRemaining: 60,
      ),
      api: _FakeApiClient(diceValue: 2),
    );

    await disabledNotifier.rollDice();

    expect(disabledNotifier.state.currentDiceValue, 2);
    expect(disabledNotifier.state.timerRunning, isFalse);

    disabledNotifier.openQuestion(disabledNotifier.state.questions.first);

    expect(disabledNotifier.state.timerRunning, isFalse);
  });

  test('loading saved challenge resumes turn after last answering group',
      () async {
    final notifier = ChallengeNotifier(
      _FakeApiClient(
        challengeById: {
          77: _savedChallengeJson(
            status: 'active',
            selectedGroupId: 1,
            usedAt: '2026-05-25T10:00:00.000000Z',
          ),
        },
      ),
    );

    await notifier.loadChallenge(77);

    expect(notifier.state.currentGroup?.id, 2);
  });

  test('loading saved challenge wraps turn after last group', () async {
    final notifier = ChallengeNotifier(
      _FakeApiClient(
        challengeById: {
          77: _savedChallengeJson(
            status: 'active',
            selectedGroupId: 2,
            usedAt: '2026-05-25T10:00:00.000000Z',
          ),
        },
      ),
    );

    await notifier.loadChallenge(77);

    expect(notifier.state.currentGroup?.id, 1);
  });

  testWidgets('created challenge opens saved challenges without arena',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    final api = _FakeApiClient(
      groups: _testGroups,
      savedChallenges: [_savedChallengeJson(id: 1, status: 'active')],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(api),
          setupProvider.overrideWith(
            (ref) => _TestSetupNotifier(_setupState()),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('ar'),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SetupGroupsScreen(),
                      ),
                    ),
                    child: const Text('الرئيسية'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('الرئيسية'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إنشاء المنافسة'));
    await tester.pumpAndSettle();

    expect(find.text('قائمة المنافسات'), findsOneWidget);
    expect(find.byType(ChallengeArenaScreen), findsNothing);
    expect(find.text('إعداد المجموعات'), findsNothing);

    Navigator.of(tester.element(find.text('قائمة المنافسات'))).pop();
    await tester.pumpAndSettle();

    expect(find.text('الرئيسية'), findsOneWidget);
  });

  testWidgets('challenge arena paginates questions and resets page on filter',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(400, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final notifier = _TestChallengeNotifier(
      ChallengeArenaState(
        session: _challengeSession(questionCount: 72, hardThrough: 36),
        currentDiceValue: 1,
        timerRemaining: 60,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          challengeProvider.overrideWith((ref) => notifier),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: ChallengeArenaScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('1'), findsOneWidget);
    expect(find.text('30'), findsNothing);
    expect(find.textContaining(' / '), findsOneWidget);

    await tester.tap(find.byTooltip('الصفحة التالية'));
    await tester.pumpAndSettle();

    expect(find.text('30'), findsOneWidget);

    await tester.tap(find.text('صعب x2'));
    await tester.pumpAndSettle();

    expect(find.text('1'), findsOneWidget);
    expect(find.text('30'), findsNothing);
  });

  testWidgets('challenge arena uses the current turn group automatically',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    final api = _FakeApiClient(groups: _testGroups);
    final notifier = _TestChallengeNotifier(
      ChallengeArenaState(
        session: _challengeSession(
          questionCount: 2,
          hardThrough: 0,
          groups: _testGroups,
        ),
        currentDiceValue: 1,
        timerRemaining: 60,
      ),
      api: api,
    );

    await _pumpArena(tester, notifier);

    expect(find.text('دور المجموعة الأولى لرمي النرد'), findsOneWidget);

    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('رجوع'), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_checked_rounded), findsNothing);
    expect(find.text('المجموعة التي تجيب: المجموعة الأولى'), findsOneWidget);

    await tester.tap(find.text('صحيحة'));
    await tester.pump();

    expect(api.lastCorrectGroupId, 1);
    expect(find.byKey(const ValueKey('correct')), findsOneWidget);
    expect(find.text('إجابة صحيحة'), findsOneWidget);
    expect(find.byTooltip('إغلاق السؤال'), findsOneWidget);
    expect(find.text('المجموعة التي تجيب: المجموعة الأولى'), findsOneWidget);

    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('إغلاق السؤال'));
    await tester.pumpAndSettle();

    expect(find.text('دور المجموعة الثانية لرمي النرد'), findsOneWidget);
    expect(find.text('إجابة صحيحة'), findsNothing);
  });

  testWidgets('dice button can be rolled from the arena controls',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(400, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final notifier = _TestChallengeNotifier(
      ChallengeArenaState(
        session: _challengeSession(
          questionCount: 2,
          hardThrough: 0,
          groups: _testGroups,
        ),
        timerRemaining: 60,
      ),
      api: _FakeApiClient(groups: _testGroups, diceValue: 3),
    );

    await _pumpArena(tester, notifier);

    expect(find.text('نقاط الحظ'), findsOneWidget);

    await tester.tap(find.text('نقاط الحظ'));
    await tester.pumpAndSettle();

    expect(find.text('3 نقطة'), findsOneWidget);
    expect(notifier.state.timerRunning, isFalse);
  });

  testWidgets('multiple choice answers are selected by touch', (tester) async {
    SharedPreferences.setMockInitialValues({});

    final api = _FakeApiClient(groups: _testGroups);
    final notifier = _TestChallengeNotifier(
      ChallengeArenaState(
        session: _challengeSession(
          questionCount: 2,
          hardThrough: 0,
          groups: _testGroups,
          questionType: 'multiple_choice',
          optionA: 'الإجابة الصحيحة',
          optionB: 'إجابة أخرى',
          correctAnswer: 'الإجابة الصحيحة',
        ),
        currentDiceValue: 2,
        timerRemaining: 60,
      ),
      api: api,
    );

    await _pumpArena(tester, notifier);
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('الإجابة الصحيحة'));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();

    expect(api.lastCorrectGroupId, 1);
    expect(find.byKey(const ValueKey('correct')), findsOneWidget);
    expect(find.text('إجابة صحيحة'), findsOneWidget);
    expect(find.byTooltip('إغلاق السؤال'), findsOneWidget);
  });

  testWidgets('last answered question completes the challenge automatically',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    final api = _FakeApiClient(groups: _testGroups);
    final notifier = _TestChallengeNotifier(
      ChallengeArenaState(
        session: _challengeSession(
          questionCount: 1,
          hardThrough: 0,
          groups: _testGroups,
        ),
        currentDiceValue: 1,
        timerRemaining: 60,
      ),
      api: api,
    );

    await _pumpArena(tester, notifier);
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('خاطئة'));
    await tester.pump();

    expect(api.lastWrongGroupId, 1);
    expect(api.completeCalls, 1);
    expect(find.byKey(const ValueKey('wrong')), findsOneWidget);
    expect(find.text('إجابة خاطئة'), findsOneWidget);
    expect(find.byTooltip('إغلاق السؤال'), findsOneWidget);
    expect(find.text('انتهى التحدي'), findsNothing);

    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('إغلاق السؤال'));
    await tester.pumpAndSettle();

    expect(find.text('انتهى التحدي'), findsOneWidget);
  });

  testWidgets('saved challenges screen opens a stored challenge',
      (tester) async {
    final api = _FakeApiClient(
      savedChallenges: [_savedChallengeJson()],
      challengeById: {77: _savedChallengeJson()},
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(api),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: SavedChallengesScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('رياضيات - الجزء الأول'), findsOneWidget);
    expect(find.text('الأول (أ) • 2026-05-25'), findsOneWidget);
    expect(find.text('أعلى 7'), findsOneWidget);

    await tester.tap(find.text('دخول'));
    await tester.pumpAndSettle();

    expect(api.loadedChallengeId, 77);
    expect(find.text('دور الفريق الثاني لرمي النرد'), findsOneWidget);
  });

  testWidgets('saved challenge edit updates timer and groups', (tester) async {
    final api = _FakeApiClient(savedChallenges: [_savedChallengeJson()]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(api),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: SavedChallengesScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('تعديل'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'الفريق المحدّث');
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();

    expect(api.lastUpdateChallengeId, 77);
    expect(api.lastUpdatePayload?['timer_seconds'], 60);
    expect((api.lastUpdatePayload?['groups'] as List).first['name'],
        'الفريق المحدّث');
  });

  testWidgets('saved challenge delete requires confirmation', (tester) async {
    final api = _FakeApiClient(
      savedChallenges: [_savedChallengeJson()],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(api),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: SavedChallengesScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.widgetWithText(OutlinedButton, 'حذف'), findsNothing);
    expect(find.byTooltip('حذف المنافسة'), findsOneWidget);

    await tester.tap(find.byTooltip('حذف المنافسة'));
    await tester.pumpAndSettle();

    expect(find.text('حذف المنافسة'), findsOneWidget);

    await tester.tap(find.text('إلغاء').last);
    await tester.pumpAndSettle();

    expect(api.deletedChallengeId, isNull);
    expect(find.text('رياضيات - الجزء الأول'), findsOneWidget);

    await tester.tap(find.byTooltip('حذف المنافسة'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'حذف'));
    await tester.pumpAndSettle();

    expect(api.deletedChallengeId, 77);
    expect(find.text('لا توجد تحديات محفوظة'), findsOneWidget);
  });

  testWidgets('completed saved challenge can be restarted', (tester) async {
    final api = _FakeApiClient(
      savedChallenges: [_savedChallengeJson()],
      restartedChallenge: _savedChallengeJson(
        id: 88,
        status: 'active',
        isUsed: false,
        selectedGroupId: null,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(api),
        ],
        child: const MaterialApp(
          locale: Locale('ar'),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: SavedChallengesScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('إعادة التنافس'), findsOneWidget);

    await tester.tap(find.text('إعادة التنافس'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إعادة').last);
    await tester.pumpAndSettle();

    expect(api.restartedChallengeId, 77);
    expect(find.text('دور الفريق الأول لرمي النرد'), findsOneWidget);
  });

  testWidgets('packages screen opens a details sheet before purchase',
      (tester) async {
    tester.view.physicalSize = const Size(400, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          packageProvider.overrideWith(
            (ref) =>
                PackageNotifier(_FakePackageApiClient(), _FakeIapService()),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('ar'),
          home: const Directionality(
            textDirection: TextDirection.rtl,
            child: PackagesScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('الأول الابتدائي (2 مادة)'), findsOneWidget);
    expect(find.text('رياضيات (1)'), findsOneWidget);
    expect(find.text('علوم (1)'), findsOneWidget);
    expect(find.text('حزمة رياضيات الصف الأول'), findsOneWidget);
    expect(find.text('حزمة علوم الصف الأول'), findsNothing);

    await tester.tap(find.text('علوم (1)'));
    await tester.pumpAndSettle();

    expect(find.text('حزمة علوم الصف الأول'), findsOneWidget);
    expect(find.text('حزمة رياضيات الصف الأول'), findsNothing);

    await tester.tap(find.text('رياضيات (1)'));
    await tester.pumpAndSettle();

    expect(find.text('حزمة رياضيات الصف الأول'), findsOneWidget);
    expect(find.text('استعراض التفاصيل'), findsOneWidget);

    await tester.tap(find.text('استعراض التفاصيل'));
    await tester.pumpAndSettle();

    expect(find.text('تفاصيل المحتوى'), findsOneWidget);
    expect(find.text('الأول الابتدائي'), findsWidgets);
    expect(find.text('رياضيات'), findsWidgets);
    expect(find.text('الجمع والطرح، الهندسة'), findsOneWidget);
    expect(find.text('جمع الأعداد، الأشكال الهندسية'), findsOneWidget);
    expect(find.text('12 سؤال'), findsWidgets);
    expect(find.text('الحزمة مجانية ومتاحة'), findsOneWidget);
    expect(find.text('شراء الحزمة'), findsNothing);
  });

  testWidgets('packages screen can open on a selected subject tab',
      (tester) async {
    tester.view.physicalSize = const Size(400, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          packageProvider.overrideWith(
            (ref) =>
                PackageNotifier(_FakePackageApiClient(), _FakeIapService()),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('ar'),
          home: const Directionality(
            textDirection: TextDirection.rtl,
            child: PackagesScreen(initialSubjectId: 11),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('الأول الابتدائي (2 مادة)'), findsOneWidget);
    expect(find.text('رياضيات (1)'), findsOneWidget);
    expect(find.text('علوم (1)'), findsOneWidget);
    expect(find.text('حزمة علوم الصف الأول'), findsOneWidget);
    expect(find.text('حزمة رياضيات الصف الأول'), findsNothing);
  });
}

class _TestChallengeNotifier extends ChallengeNotifier {
  _TestChallengeNotifier(
    ChallengeArenaState initial, {
    _FakeApiClient? api,
  }) : super(api ?? _FakeApiClient()) {
    state = initial;
  }
}

class _TestSetupNotifier extends SetupNotifier {
  _TestSetupNotifier(SetupState initial) {
    state = initial;
  }
}

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier() : super(_FakeApiClient());

  @override
  Future<bool> tryAutoLogin() async => false;

  @override
  Future<bool> login(String email, String password) async => true;

  @override
  Future<bool> register(String name, String email, String password) async =>
      true;
}

class _FakeApiClient extends ApiClient {
  final List<ChallengeGroup> groups;
  final List<dynamic> subjects;
  final Map<int, List<dynamic>> partsBySubject;
  final Map<int, List<dynamic>> chaptersBySubjectPart;
  final Map<int, List<dynamic>> lessonsByChapter;
  final List<dynamic> questionList;
  final List<dynamic> teacherGrades;
  final List<dynamic> teacherSubjects;
  final Map<int, List<dynamic>> teacherPartsBySubject;
  final List<dynamic> teacherChapters;
  final List<dynamic> teacherLessons;
  final List<dynamic> teacherQuestions;
  final List<dynamic> packageSuggestions;
  final List<dynamic> savedChallenges;
  final Map<int, Map<String, dynamic>> challengeById;
  final Map<String, dynamic>? restartedChallenge;
  final int diceValue;
  int? lastCorrectGroupId;
  int? lastWrongGroupId;
  int? loadedChallengeId;
  int? lastUpdateChallengeId;
  int? restartedChallengeId;
  int? deletedChallengeId;
  int completeCalls = 0;
  Map<String, dynamic>? lastCreatePayload;
  Map<String, dynamic>? lastUpdatePayload;

  _FakeApiClient({
    this.groups = const [],
    this.subjects = const [],
    this.partsBySubject = const {},
    this.chaptersBySubjectPart = const {},
    this.lessonsByChapter = const {},
    this.questionList = const [],
    this.teacherGrades = const [],
    this.teacherSubjects = const [],
    this.teacherPartsBySubject = const {},
    this.teacherChapters = const [],
    this.teacherLessons = const [],
    this.teacherQuestions = const [],
    this.packageSuggestions = const [],
    this.savedChallenges = const [],
    this.challengeById = const {},
    this.restartedChallenge,
    this.diceValue = 1,
  });

  @override
  Future<List<dynamic>> getSubjects(int gradeId) async => subjects;

  @override
  Future<List<dynamic>> getChapters(
    int subjectId, {
    int? subjectPartId,
  }) async =>
      chaptersBySubjectPart[subjectPartId] ?? const [];

  @override
  Future<List<dynamic>> getLessons(List<int> chapterIds) async => chapterIds
      .expand((id) => lessonsByChapter[id] ?? const <dynamic>[])
      .toList();

  @override
  Future<List<dynamic>> getQuestions(List<int> lessonIds) async => questionList;

  @override
  Future<List<dynamic>> getTeacherGrades() async => teacherGrades;

  @override
  Future<Map<String, dynamic>> createTeacherGrade(
    Map<String, dynamic> data,
  ) async {
    final grade = _gradeJson(
      teacherGrades.length + 1,
      data['name'] as String,
    );
    teacherGrades.add(grade);
    return grade;
  }

  @override
  Future<List<dynamic>> getTeacherSubjects({int? gradeId}) async {
    if (gradeId == null) return teacherSubjects;
    return teacherSubjects
        .where((subject) => subject['grade_id'] == gradeId)
        .toList();
  }

  @override
  Future<Map<String, dynamic>> createTeacherSubject(
    Map<String, dynamic> data,
  ) async {
    final subject = {
      'id': 100 + teacherSubjects.length,
      'grade_id': data['grade_id'],
      'name': data['name'],
    };
    teacherSubjects.add(subject);
    final subjectId = subject['id'] as int;
    teacherPartsBySubject[subjectId] = <dynamic>[
      _partJson(1000 + subjectId, subjectId, 'الجزء الأول'),
      _partJson(2000 + subjectId, subjectId, 'الجزء الثاني'),
    ];
    return subject;
  }

  @override
  Future<List<dynamic>> getSubjectParts(
    int subjectId, {
    bool includeEmpty = false,
  }) async =>
      teacherPartsBySubject[subjectId] ?? partsBySubject[subjectId] ?? const [];

  @override
  Future<List<dynamic>> getTeacherChapters({
    int? subjectId,
    int? subjectPartId,
  }) async {
    return teacherChapters.where((chapter) {
      final matchesSubject =
          subjectId == null || chapter['subject_id'] == subjectId;
      final matchesPart =
          subjectPartId == null || chapter['subject_part_id'] == subjectPartId;
      return matchesSubject && matchesPart;
    }).toList();
  }

  @override
  Future<Map<String, dynamic>> createTeacherChapter(
    Map<String, dynamic> data,
  ) async {
    final partId = data['subject_part_id'] as int;
    final part = teacherPartsBySubject.values
        .expand((parts) => parts)
        .cast<Map<String, dynamic>>()
        .firstWhere((part) => part['id'] == partId);
    final chapter = _chapterJson(
      3000 + teacherChapters.length,
      part['subject_id'] as int,
      partId,
      data['name'] as String,
    );
    teacherChapters.add(chapter);
    return chapter;
  }

  @override
  Future<List<dynamic>> getTeacherLessons({int? chapterId}) async {
    if (chapterId == null) return teacherLessons;
    return teacherLessons
        .where((lesson) => lesson['chapter_id'] == chapterId)
        .toList();
  }

  @override
  Future<Map<String, dynamic>> createTeacherLesson(
    Map<String, dynamic> data,
  ) async {
    final lesson = _lessonJson(
      5000 + teacherLessons.length,
      data['chapter_id'] as int,
      data['name'] as String,
    );
    teacherLessons.add(lesson);
    return lesson;
  }

  @override
  Future<List<dynamic>> getTeacherQuestions({int? lessonId}) async {
    if (lessonId == null) return teacherQuestions;
    return teacherQuestions
        .where((question) => question['lesson_id'] == lessonId)
        .toList();
  }

  @override
  Future<Map<String, dynamic>> createTeacherQuestion(
    Map<String, dynamic> data,
  ) async {
    final question = _questionJson(
      7000 + teacherQuestions.length,
      data['lesson_id'] as int,
      data['question_text'] as String,
      correctAnswer: data['correct_answer'] as String,
      questionType: data['question_type'] as String,
      level: data['level'] as String,
    );
    teacherQuestions.add(question);
    return question;
  }

  @override
  Future<List<dynamic>> getPackageSuggestions({
    int? gradeId,
    int? subjectId,
  }) async =>
      packageSuggestions;

  @override
  Future<List<dynamic>> getPackages() async => packageSuggestions;

  @override
  Future<List<dynamic>> getChallenges() async => savedChallenges;

  @override
  Future<Map<String, dynamic>> createChallenge(
    Map<String, dynamic> data,
  ) async {
    lastCreatePayload = data;
    return _sessionJson(groups: const [], questions: const []);
  }

  @override
  Future<Map<String, dynamic>> addGroup(
    int challengeId,
    String name,
    int sortOrder,
  ) async {
    return _groupJson(
      ChallengeGroup(
        id: sortOrder + 1,
        challengeSessionId: challengeId,
        name: name,
        score: 0,
        sortOrder: sortOrder,
      ),
    );
  }

  @override
  Future<Map<String, dynamic>> getChallenge(int id) async {
    loadedChallengeId = id;
    if (challengeById.containsKey(id)) {
      return challengeById[id]!;
    }
    return _sessionJson(groups: groups, questions: const []);
  }

  @override
  Future<Map<String, dynamic>> updateChallenge(
    int id,
    Map<String, dynamic> data,
  ) async {
    lastUpdateChallengeId = id;
    lastUpdatePayload = data;
    return challengeById[id] ?? _savedChallengeJson();
  }

  @override
  Future<Map<String, dynamic>> restartChallenge(int id) async {
    restartedChallengeId = id;
    return restartedChallenge ??
        _savedChallengeJson(id: id + 1, status: 'active');
  }

  @override
  Future<void> deleteChallenge(int id) async {
    deletedChallengeId = id;
    savedChallenges.removeWhere(
      (challenge) => (challenge as Map<String, dynamic>)['id'] == id,
    );
  }

  @override
  Future<int> rollDice(int challengeId) async => diceValue;

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
      'group': _groupJson(groups.firstWhere((g) => g.id == groupId)),
      'groups': groups.map(_groupJson).toList(),
    };
  }

  @override
  Future<void> markWrong(
    int challengeId,
    int challengeQuestionId,
    int groupId,
    int diceValue,
  ) async {
    lastWrongGroupId = groupId;
  }

  @override
  Future<Map<String, dynamic>> completeChallenge(int challengeId) async {
    completeCalls += 1;
    return {'status': 'completed'};
  }
}

class _FakePackageApiClient extends ApiClient {
  @override
  Future<List<dynamic>> getPackages() async {
    return [
      {
        'id': 101,
        'title': 'حزمة رياضيات الصف الأول',
        'description': 'أسئلة قصيرة لتجهيز تحديات سريعة قبل الحصة.',
        'grade': {
          'id': 1,
          'name': 'الأول الابتدائي',
          'sort_order': 1,
          'is_active': true,
        },
        'subject': {
          'id': 10,
          'grade_id': 1,
          'name': 'رياضيات',
        },
        'chapter': {
          'id': 20,
          'subject_id': 10,
          'name': 'الجمع والطرح',
          'sort_order': 1,
        },
        'lesson': {
          'id': 30,
          'chapter_id': 20,
          'name': 'جمع الأعداد',
          'sort_order': 1,
        },
        'chapters': [
          {
            'id': 20,
            'subject_id': 10,
            'name': 'الجمع والطرح',
            'sort_order': 1,
          },
          {
            'id': 22,
            'subject_id': 10,
            'name': 'الهندسة',
            'sort_order': 2,
          },
        ],
        'lessons': [
          {
            'id': 30,
            'chapter_id': 20,
            'name': 'جمع الأعداد',
            'sort_order': 1,
          },
          {
            'id': 32,
            'chapter_id': 22,
            'name': 'الأشكال الهندسية',
            'sort_order': 1,
          },
        ],
        'is_free': true,
        'price': null,
        'purchase_type': 'non_consumable',
        'is_active': true,
        'questions_count': 12,
        'is_owned': true,
      },
      {
        'id': 102,
        'title': 'حزمة علوم الصف الأول',
        'description': 'أسئلة علوم قصيرة.',
        'grade': {
          'id': 1,
          'name': 'الأول الابتدائي',
          'sort_order': 1,
          'is_active': true,
        },
        'subject': {
          'id': 11,
          'grade_id': 1,
          'name': 'علوم',
        },
        'chapter': {
          'id': 21,
          'subject_id': 11,
          'name': 'النباتات',
          'sort_order': 1,
        },
        'lesson': {
          'id': 31,
          'chapter_id': 21,
          'name': 'أجزاء النبات',
          'sort_order': 1,
        },
        'is_free': false,
        'price': '9.99',
        'purchase_type': 'non_consumable',
        'is_active': true,
        'questions_count': 10,
        'is_owned': false,
      },
    ];
  }
}

class _FakeIapService extends IapService {
  final _controller = StreamController<List<PurchaseDetails>>.broadcast();

  @override
  Stream<List<PurchaseDetails>> get purchaseUpdates => _controller.stream;

  @override
  Future<void> buyPackage(QuestionPackage package) async {}

  @override
  Future<void> restorePurchases() async {}
}

Future<void> _pumpArena(
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
          child: ChallengeArenaScreen(),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

Future<void> _pumpChallengeSetup(
  WidgetTester tester,
  ApiClient api,
  SetupNotifier notifier,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(api),
        setupProvider.overrideWith((ref) => notifier),
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

Future<void> _pumpContentManager(
  WidgetTester tester,
  ApiClient api,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(api),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('ar'),
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: ManageContentScreen(),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

Future<void> _completeBasicSetup(WidgetTester tester) async {
  await _tapSetupKey(tester, 'setup-section-card-أ');
  await tester.pumpAndSettle();

  await _tapSetupKey(tester, 'setup-subject-card-10');
  await tester.pumpAndSettle();

  await _tapSetupKey(tester, 'setup-part-card-100');
  await tester.pumpAndSettle();

  await _tapSetupKey(tester, 'setup-chapter-card-1000');
  await tester.pumpAndSettle();

  await _tapSetupKey(tester, 'setup-lesson-card-1');
  await tester.pumpAndSettle();
}

Future<void> _tapSetupKey(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await _scrollUntilBuilt(tester, finder);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pumpAndSettle();
}

Future<void> _tapButton(WidgetTester tester, String label) async {
  final finder = find.text(label);
  await _scrollUntilBuilt(tester, finder);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _waitForSetupState(
  WidgetTester tester,
  bool Function() condition,
) async {
  for (var i = 0; i < 12; i++) {
    if (condition()) return;
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(condition(), isTrue);
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

const _testGroups = [
  ChallengeGroup(
    id: 1,
    challengeSessionId: 1,
    name: 'المجموعة الأولى',
    score: 0,
    sortOrder: 0,
  ),
  ChallengeGroup(
    id: 2,
    challengeSessionId: 1,
    name: 'المجموعة الثانية',
    score: 0,
    sortOrder: 1,
  ),
];

Map<String, dynamic> _groupJson(ChallengeGroup group) => {
      'id': group.id,
      'challenge_session_id': group.challengeSessionId,
      'name': group.name,
      'score': group.score,
      'sort_order': group.sortOrder,
    };

Map<String, dynamic> _sessionJson({
  required List<ChallengeGroup> groups,
  required List<dynamic> questions,
}) =>
    {
      'id': 1,
      'grade_section': 'أ',
      'timer_seconds': 60,
      'timer_enabled': true,
      'status': 'active',
      'groups': groups.map(_groupJson).toList(),
      'questions': questions,
    };

Map<String, dynamic> _savedChallengeJson({
  int id = 77,
  String status = 'completed',
  bool isUsed = true,
  int? selectedGroupId = 1,
  String? usedAt,
}) =>
    {
      'id': id,
      'grade_section': 'أ',
      'grade': {
        'id': 1,
        'name': 'الأول',
        'sort_order': 1,
        'is_active': true,
      },
      'subject': {
        'id': 1,
        'grade_id': 1,
        'name': 'رياضيات',
      },
      'subject_part': {
        'id': 1,
        'subject_id': 1,
        'name': 'الجزء الأول',
        'part_number': 1,
        'sort_order': 1,
      },
      'chapters': const [],
      'lessons': const [],
      'timer_seconds': 60,
      'timer_enabled': true,
      'status': status,
      'started_at': '2026-05-25T10:00:00.000000Z',
      'groups': [
        {
          'id': 1,
          'challenge_session_id': id,
          'name': 'الفريق الأول',
          'score': 7,
          'sort_order': 0,
        },
        {
          'id': 2,
          'challenge_session_id': id,
          'name': 'الفريق الثاني',
          'score': 3,
          'sort_order': 1,
        },
      ],
      'questions': [
        {
          'id': 101,
          'sequence_number': 1,
          'is_used': isUsed,
          'used_at': usedAt,
          'answer_status': 'correct',
          'awarded_points': 7,
          'last_dice_value': 2,
          'selected_group_id': selectedGroupId,
          'question': {
            'id': 1,
            'lesson_id': 1,
            'question_text': 'سؤال محفوظ',
            'question_type': 'text',
            'correct_answer': 'إجابة',
            'level': 'easy',
          },
        },
      ],
    };

SetupState _setupState({
  List<Question>? selectedQuestions,
}) {
  final questions = selectedQuestions ??
      const [
        Question(
          id: 1,
          lessonId: 1,
          questionText: 'سؤال 1',
          questionType: 'text',
          correctAnswer: 'إجابة',
          level: 'easy',
        ),
        Question(
          id: 2,
          lessonId: 1,
          questionText: 'سؤال 2',
          questionType: 'text',
          correctAnswer: 'إجابة',
          level: 'hard',
        ),
      ];

  return SetupState(
    selectedGrade:
        const Grade(id: 1, name: 'الأول', sortOrder: 1, isActive: true),
    selectedGradeSection: 'أ',
    selectedSubject: const Subject(id: 1, gradeId: 1, name: 'رياضيات'),
    selectedSubjectPart: const SubjectPart(
      id: 1,
      subjectId: 1,
      name: 'الجزء الأول',
      partNumber: 1,
      sortOrder: 1,
    ),
    selectedChapters: const [
      Chapter(
          id: 1, subjectId: 1, subjectPartId: 1, name: 'الفصل', sortOrder: 1),
    ],
    selectedLessons: const [
      Lesson(id: 1, chapterId: 1, name: 'الدرس الأول', sortOrder: 1),
    ],
    selectedQuestions: questions,
  );
}

Map<String, dynamic> _gradeJson(int id, String name) => {
      'id': id,
      'name': name,
      'sort_order': id,
      'is_active': true,
    };

Map<String, dynamic> _partJson(
  int id,
  int subjectId,
  String name,
) =>
    {
      'id': id,
      'subject_id': subjectId,
      'name': name,
      'part_number': 1,
      'sort_order': 1,
    };

Map<String, dynamic> _chapterJson(
  int id,
  int subjectId,
  int subjectPartId,
  String name,
) =>
    {
      'id': id,
      'subject_id': subjectId,
      'subject_part_id': subjectPartId,
      'name': name,
      'sort_order': 1,
    };

Map<String, dynamic> _lessonJson(
  int id,
  int chapterId,
  String name,
) =>
    {
      'id': id,
      'chapter_id': chapterId,
      'name': name,
      'sort_order': 1,
    };

Map<String, dynamic> _questionJson(
  int id,
  int lessonId,
  String text, {
  String correctAnswer = 'إجابة',
  String questionType = 'text',
  String level = 'easy',
}) =>
    {
      'id': id,
      'lesson_id': lessonId,
      'question_text': text,
      'question_type': questionType,
      'correct_answer': correctAnswer,
      'level': level,
      'sort_order': 1,
    };

List<Map<String, dynamic>> _questionJsonList() => [
      {
        'id': 1,
        'lesson_id': 1,
        'question_text': 'سؤال 1',
        'question_type': 'text',
        'correct_answer': 'إجابة',
        'level': 'easy',
        'sort_order': 1,
      },
      {
        'id': 2,
        'lesson_id': 1,
        'question_text': 'سؤال 2',
        'question_type': 'text',
        'correct_answer': 'إجابة',
        'level': 'hard',
        'sort_order': 2,
      },
    ];

List<Map<String, dynamic>> _subjectJsonList() => [
      {
        'id': 10,
        'grade_id': 1,
        'name': 'رياضيات',
      },
      {
        'id': 20,
        'grade_id': 1,
        'name': 'علوم',
      },
    ];

List<Map<String, dynamic>> _partJsonList(int subjectId) => [
      {
        'id': subjectId * 10,
        'subject_id': subjectId,
        'name': subjectId == 10 ? 'الجزء الأول' : 'الجزء الثاني',
        'part_number': subjectId == 10 ? 1 : 2,
        'sort_order': 1,
      },
    ];

List<Map<String, dynamic>> _chapterJsonList() => [
      {
        'id': 1000,
        'subject_id': 10,
        'subject_part_id': 100,
        'name': 'الفصل الأول',
        'sort_order': 1,
      },
      {
        'id': 2000,
        'subject_id': 10,
        'subject_part_id': 100,
        'name': 'الفصل الثاني',
        'sort_order': 2,
      },
    ];

List<Map<String, dynamic>> _lessonJsonList() => [
      {
        'id': 1,
        'chapter_id': 1000,
        'name': 'الدرس الأول',
        'sort_order': 1,
      },
    ];

Map<String, dynamic> _packageSuggestionJson({
  int id = 501,
  bool isOwned = false,
}) =>
    {
      'id': id,
      'title': 'حزمة إضافية للرياضيات',
      'description': 'أسئلة إضافية للمادة.',
      'grade': {
        'id': 1,
        'name': 'الأول',
        'sort_order': 1,
        'is_active': true,
      },
      'subject': {
        'id': 10,
        'grade_id': 1,
        'name': 'رياضيات',
      },
      'chapter': null,
      'lesson': null,
      'is_free': false,
      'price': '9.99',
      'purchase_type': 'non_consumable',
      'is_active': true,
      'questions_count': 10,
      'is_owned': isOwned,
    };

ChallengeSession _challengeSession({
  required int questionCount,
  required int hardThrough,
  List<ChallengeGroup> groups = const [],
  bool timerEnabled = true,
  String questionType = 'text',
  String? optionA,
  String? optionB,
  String? optionC,
  String? optionD,
  String correctAnswer = 'إجابة',
}) {
  return ChallengeSession(
    id: 1,
    grade: const Grade(id: 1, name: 'الأول', sortOrder: 1, isActive: true),
    subject: const Subject(
      id: 1,
      gradeId: 1,
      name: 'رياضيات',
      backgroundTheme: 'math',
    ),
    subjectPart: const SubjectPart(
      id: 1,
      subjectId: 1,
      name: 'الفصل الأول',
      partNumber: 1,
      sortOrder: 1,
    ),
    chapters: const [],
    lessons: const [],
    timerSeconds: 60,
    timerEnabled: timerEnabled,
    status: 'active',
    groups: groups,
    questions: List.generate(
      questionCount,
      (index) {
        final sequence = index + 1;
        return ChallengeQuestionItem(
          id: sequence,
          sequenceNumber: sequence,
          isUsed: false,
          usedAt: null,
          question: Question(
            id: sequence,
            lessonId: 1,
            questionText: 'سؤال $sequence',
            questionType: questionType,
            optionA: optionA,
            optionB: optionB,
            optionC: optionC,
            optionD: optionD,
            correctAnswer: correctAnswer,
            level: sequence <= hardThrough ? 'hard' : 'easy',
          ),
        );
      },
    ),
  );
}
