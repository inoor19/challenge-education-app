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
import 'package:challenge_edu_app/features/packages/providers/package_provider.dart';
import 'package:challenge_edu_app/features/packages/screens/packages_screen.dart';
import 'package:challenge_edu_app/features/packages/services/iap_service.dart';
import 'package:challenge_edu_app/features/setup/providers/setup_provider.dart';
import 'package:challenge_edu_app/features/setup/screens/select_questions_screen.dart';
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
          child: Text('ساحة التحدي التعليمي'),
        ),
      ),
    );

    final textContext = tester.element(find.text('ساحة التحدي التعليمي'));

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

    expect(find.byTooltip('رجوع'), findsNothing);
    expect(find.byIcon(Icons.radio_button_checked_rounded), findsNothing);
    expect(find.text('المجموعة التي تجيب: المجموعة الأولى'), findsOneWidget);

    await tester.tap(find.text('صحيحة'));
    await tester.pumpAndSettle();

    expect(api.lastCorrectGroupId, 1);
    expect(find.text('دور المجموعة الثانية لرمي النرد'), findsOneWidget);
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
    await tester.pumpAndSettle();

    expect(api.lastCorrectGroupId, 1);
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
    await tester.pumpAndSettle();

    expect(api.lastWrongGroupId, 1);
    expect(api.completeCalls, 1);
    expect(find.text('انتهى التحدي'), findsOneWidget);
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

    expect(find.text('حزمة رياضيات الصف الأول'), findsOneWidget);
    expect(find.text('استعراض التفاصيل'), findsOneWidget);

    await tester.tap(find.text('استعراض التفاصيل'));
    await tester.pumpAndSettle();

    expect(find.text('تفاصيل المحتوى'), findsOneWidget);
    expect(find.text('الأول الابتدائي'), findsWidgets);
    expect(find.text('رياضيات'), findsWidgets);
    expect(find.text('الجمع والطرح'), findsOneWidget);
    expect(find.text('جمع الأعداد'), findsOneWidget);
    expect(find.text('12 سؤال'), findsWidgets);
    expect(find.text('الحزمة مجانية ومتاحة'), findsOneWidget);
    expect(find.text('شراء الحزمة'), findsNothing);
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
  final List<dynamic> questionList;
  int? lastCorrectGroupId;
  int? lastWrongGroupId;
  int completeCalls = 0;
  Map<String, dynamic>? lastCreatePayload;

  _FakeApiClient({
    this.groups = const [],
    this.questionList = const [],
  });

  @override
  Future<List<dynamic>> getQuestions(List<int> lessonIds) async => questionList;

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
    return _sessionJson(groups: groups, questions: const []);
  }

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
        'is_free': true,
        'price': null,
        'purchase_type': 'non_consumable',
        'is_active': true,
        'questions_count': 12,
        'is_owned': true,
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
      'timer_seconds': 60,
      'timer_enabled': true,
      'status': 'active',
      'groups': groups.map(_groupJson).toList(),
      'questions': questions,
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

ChallengeSession _challengeSession({
  required int questionCount,
  required int hardThrough,
  List<ChallengeGroup> groups = const [],
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
    timerEnabled: true,
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
