import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/models/api_models.dart';
import '../../../core/providers/api_provider.dart';
import '../../setup/providers/setup_provider.dart';

// ─── Challenge Arena State ────────────────────────────────────────────────────

class ChallengeArenaState {
  final ChallengeSession? session;
  final bool isLoading;
  final String? error;

  // Dice state
  final int? currentDiceValue;
  final bool isDiceRolling;

  // Timer state
  final int timerRemaining;
  final bool timerRunning;

  // Turn state
  final int currentTurnIndex;

  // Active question
  final ChallengeQuestionItem? activeQuestion;

  // UI feedback
  final String? lastAnswerResult; // 'correct' | 'wrong'

  const ChallengeArenaState({
    this.session,
    this.isLoading = false,
    this.error,
    this.currentDiceValue,
    this.isDiceRolling = false,
    this.timerRemaining = 60,
    this.timerRunning = false,
    this.currentTurnIndex = 0,
    this.activeQuestion,
    this.lastAnswerResult,
  });

  ChallengeArenaState copyWith({
    ChallengeSession? session,
    bool? isLoading,
    String? error,
    int? currentDiceValue,
    bool? isDiceRolling,
    int? timerRemaining,
    bool? timerRunning,
    int? currentTurnIndex,
    ChallengeQuestionItem? activeQuestion,
    bool clearActiveQuestion = false,
    bool clearDice = false,
    String? lastAnswerResult,
    bool clearLastAnswer = false,
  }) =>
      ChallengeArenaState(
        session: session ?? this.session,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        currentDiceValue:
            clearDice ? null : currentDiceValue ?? this.currentDiceValue,
        isDiceRolling: isDiceRolling ?? this.isDiceRolling,
        timerRemaining: timerRemaining ?? this.timerRemaining,
        timerRunning: timerRunning ?? this.timerRunning,
        currentTurnIndex: currentTurnIndex ?? this.currentTurnIndex,
        activeQuestion:
            clearActiveQuestion ? null : activeQuestion ?? this.activeQuestion,
        lastAnswerResult:
            clearLastAnswer ? null : lastAnswerResult ?? this.lastAnswerResult,
      );

  List<ChallengeGroup> get groups {
    final sorted = List<ChallengeGroup>.of(session?.groups ?? []);
    sorted.sort((a, b) {
      final order = a.sortOrder.compareTo(b.sortOrder);
      return order == 0 ? a.id.compareTo(b.id) : order;
    });
    return sorted;
  }

  List<ChallengeQuestionItem> get questions => session?.questions ?? [];
  int get totalQuestions => questions.length;
  int get usedQuestions => questions.where((q) => q.isUsed).length;
  bool get allQuestionsUsed =>
      totalQuestions > 0 && usedQuestions >= totalQuestions;

  ChallengeGroup? get currentGroup {
    final sortedGroups = groups;
    if (sortedGroups.isEmpty) return null;
    return sortedGroups[currentTurnIndex % sortedGroups.length];
  }
}

// ─── Challenge Notifier ───────────────────────────────────────────────────────

class ChallengeNotifier extends StateNotifier<ChallengeArenaState> {
  final ApiClient _api;
  Timer? _timerTick;

  ChallengeNotifier(this._api) : super(const ChallengeArenaState());

  @override
  void dispose() {
    _timerTick?.cancel();
    super.dispose();
  }

  // ── Session Setup ───────────────────────────────────────────────────────────

  Future<void> loadChallenge(int id) async {
    state = state.copyWith(isLoading: true);
    try {
      final session = ChallengeSession.fromJson(await _api.getChallenge(id));
      state = ChallengeArenaState(
        session: session,
        timerRemaining: session.timerSeconds,
        currentTurnIndex: _restoredTurnIndex(session),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: AppError.message(
          e,
          fallback: 'تعذر تحميل التحدي المحفوظ. حاول مجدداً.',
        ),
      );
      rethrow;
    }
  }

  Future<void> createChallenge({
    required SetupState setup,
    required List<String> groupNames,
    required int timerSeconds,
    required bool timerEnabled,
  }) async {
    state = state.copyWith(isLoading: true);

    final session = await _api.createChallenge({
      'grade_id': setup.selectedGrade!.id,
      'grade_section': setup.selectedGradeSection!,
      'subject_id': setup.selectedSubject!.id,
      'subject_part_id': setup.selectedSubjectPart!.id,
      'chapter_ids': setup.selectedChapters.map((c) => c.id).toList(),
      'lesson_ids': setup.selectedLessons.map((l) => l.id).toList(),
      'question_ids': setup.selectedQuestions.map((q) => q.id).toList(),
      'timer_seconds': timerSeconds,
      'timer_enabled': timerEnabled,
    });

    final challengeSession = ChallengeSession.fromJson(session);

    // Add groups sequentially
    for (int i = 0; i < groupNames.length; i++) {
      await _api.addGroup(challengeSession.id, groupNames[i], i);
    }

    // Reload with groups
    final fullSession =
        ChallengeSession.fromJson(await _api.getChallenge(challengeSession.id));

    state = ChallengeArenaState(
      session: fullSession,
      timerRemaining: timerSeconds,
    );
  }

  Future<ChallengeSession> updateChallengeSettings({
    required int challengeId,
    required int timerSeconds,
    required bool timerEnabled,
    required List<Map<String, dynamic>> groups,
  }) async {
    final updated = ChallengeSession.fromJson(
      await _api.updateChallenge(challengeId, {
        'timer_seconds': timerSeconds,
        'timer_enabled': timerEnabled,
        'groups': groups,
      }),
    );

    if (state.session?.id == updated.id) {
      state = state.copyWith(
        session: updated,
        timerRemaining: updated.timerSeconds,
      );
    }

    return updated;
  }

  Future<ChallengeSession> updateChallengeSetup({
    required int challengeId,
    required SetupState setup,
  }) async {
    final updated = ChallengeSession.fromJson(
      await _api.updateChallenge(challengeId, {
        'subject_part_id': setup.selectedSubjectPart!.id,
        'chapter_ids': setup.selectedChapters.map((c) => c.id).toList(),
        'lesson_ids': setup.selectedLessons.map((l) => l.id).toList(),
        'question_ids': setup.selectedQuestions.map((q) => q.id).toList(),
      }),
    );

    if (state.session?.id == updated.id) {
      state = state.copyWith(
        session: updated,
        timerRemaining: updated.timerSeconds,
      );
    }

    return updated;
  }

  Future<ChallengeSession> restartChallenge(int challengeId) async {
    state = state.copyWith(isLoading: true);
    try {
      final restarted =
          ChallengeSession.fromJson(await _api.restartChallenge(challengeId));
      state = ChallengeArenaState(
        session: restarted,
        timerRemaining: restarted.timerSeconds,
        currentTurnIndex: _restoredTurnIndex(restarted),
      );
      return restarted;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: AppError.message(
          e,
          fallback: 'تعذر إعادة التنافس. حاول مجدداً.',
        ),
      );
      rethrow;
    }
  }

  Future<void> deleteChallenge(int challengeId) async {
    await _api.deleteChallenge(challengeId);
    if (state.session?.id == challengeId) {
      _stopTimer();
      state = const ChallengeArenaState();
    }
  }

  // ── Dice ────────────────────────────────────────────────────────────────────

  Future<void> rollDice() async {
    if (state.session == null) return;
    state = state.copyWith(isDiceRolling: true);

    try {
      final diceValue = await _api.rollDice(state.session!.id);
      state = state.copyWith(currentDiceValue: diceValue, isDiceRolling: false);
    } catch (e) {
      state = state.copyWith(
        isDiceRolling: false,
        error: AppError.message(
          e,
          fallback: 'تعذر رمي النرد. حاول مجدداً.',
        ),
      );
    }
  }

  // ── Questions ───────────────────────────────────────────────────────────────

  void selectAnsweringGroup(int groupId) {
    final session = state.session;
    if (session == null || state.activeQuestion != null) return;

    final groupIndex = state.groups.indexWhere((group) => group.id == groupId);
    if (groupIndex < 0) return;

    state = state.copyWith(
      session: session.copyWith(currentTurnGroupId: groupId),
      currentTurnIndex: groupIndex,
    );
  }

  void openQuestion(ChallengeQuestionItem question) {
    state = state.copyWith(activeQuestion: question, clearLastAnswer: true);
    if (state.session?.timerEnabled == true) {
      resetAndStartTimer();
    }
  }

  void closeQuestion() {
    state = state.copyWith(clearActiveQuestion: true, clearLastAnswer: true);
    _stopTimer();
  }

  Future<void> markCorrect([int? groupId]) async {
    final q = state.activeQuestion;
    final s = state.session;
    final answeringGroupId = groupId ?? state.currentGroup?.id;
    if (q == null ||
        s == null ||
        answeringGroupId == null ||
        state.currentDiceValue == null) {
      return;
    }

    final result = await _api.markCorrect(
      s.id,
      q.id,
      answeringGroupId,
      state.currentDiceValue!,
    );

    // Update groups locally
    final updatedGroups = (result['groups'] as List)
        .map((g) => ChallengeGroup.fromJson(g))
        .toList();

    final updatedQuestions = state.questions.map((cq) {
      if (cq.id == q.id) {
        return cq.copyWith(
          isUsed: true,
          answerStatus: 'correct',
          awardedPoints: result['points_awarded'] as int?,
          lastDiceValue: state.currentDiceValue,
          selectedGroupId: answeringGroupId,
        );
      }
      return cq;
    }).toList();

    final nextTurnIndex = _nextTurnIndex(answeringGroupId);
    final updatedSession = s.copyWith(
      groups: updatedGroups,
      questions: updatedQuestions,
      currentTurnGroupId: _groupIdAtTurn(nextTurnIndex, updatedGroups),
    );

    _stopTimer();
    state = state.copyWith(
      session: updatedSession,
      lastAnswerResult: 'correct',
      clearDice: true,
      currentTurnIndex: nextTurnIndex,
    );
    await _completeIfAllQuestionsUsed();
  }

  Future<void> markWrong([int? groupId]) async {
    final q = state.activeQuestion;
    final s = state.session;
    final answeringGroupId = groupId ?? state.currentGroup?.id;
    if (q == null ||
        s == null ||
        answeringGroupId == null ||
        state.currentDiceValue == null) {
      return;
    }

    await _api.markWrong(s.id, q.id, answeringGroupId, state.currentDiceValue!);

    final updatedQuestions = state.questions.map((cq) {
      if (cq.id == q.id) {
        return cq.copyWith(
          isUsed: true,
          answerStatus: 'wrong',
          awardedPoints: 0,
          lastDiceValue: state.currentDiceValue,
          selectedGroupId: answeringGroupId,
        );
      }
      return cq;
    }).toList();

    final nextTurnIndex = _nextTurnIndex(answeringGroupId);
    final updatedSession = s.copyWith(
      questions: updatedQuestions,
      currentTurnGroupId: _groupIdAtTurn(nextTurnIndex, state.groups),
    );

    _stopTimer();
    state = state.copyWith(
      session: updatedSession,
      lastAnswerResult: 'wrong',
      clearDice: true,
      currentTurnIndex: nextTurnIndex,
    );
    await _completeIfAllQuestionsUsed();
  }

  // ── Manual Score ────────────────────────────────────────────────────────────

  Future<void> manualAdd(int groupId, int points, {String? note}) async {
    final s = state.session;
    if (s == null) return;
    final result =
        await _api.manualScore(s.id, groupId, 'add', points, null, note);
    _updateGroups(result);
  }

  Future<void> manualSubtract(int groupId, int points, {String? note}) async {
    final s = state.session;
    if (s == null) return;
    final result =
        await _api.manualScore(s.id, groupId, 'subtract', points, null, note);
    _updateGroups(result);
  }

  Future<void> correctScore(int groupId, int newScore, {String? note}) async {
    final s = state.session;
    if (s == null) return;
    final result = await _api.manualScore(
        s.id, groupId, 'correction', null, newScore, note);
    _updateGroups(result);
  }

  void _updateGroups(Map<String, dynamic> result) {
    final s = state.session;
    if (s == null) return;
    final updatedGroups = (result['groups'] as List)
        .map((g) => ChallengeGroup.fromJson(g))
        .toList();

    final updatedSession = s.copyWith(groups: updatedGroups);

    state = state.copyWith(session: updatedSession);
  }

  int _nextTurnIndex(int answeringGroupId) {
    final sortedGroups = state.groups;
    if (sortedGroups.isEmpty) return 0;

    final answeringGroupIndex =
        sortedGroups.indexWhere((group) => group.id == answeringGroupId);
    if (answeringGroupIndex < 0) return state.currentTurnIndex;

    return (answeringGroupIndex + 1) % sortedGroups.length;
  }

  int? _groupIdAtTurn(int turnIndex, List<ChallengeGroup> groups) {
    if (groups.isEmpty) return null;
    final sortedGroups = List<ChallengeGroup>.of(groups)
      ..sort((a, b) {
        final order = a.sortOrder.compareTo(b.sortOrder);
        return order == 0 ? a.id.compareTo(b.id) : order;
      });
    return sortedGroups[turnIndex % sortedGroups.length].id;
  }

  int _restoredTurnIndex(ChallengeSession session) {
    final groups = List<ChallengeGroup>.of(session.groups)
      ..sort((a, b) {
        final order = a.sortOrder.compareTo(b.sortOrder);
        return order == 0 ? a.id.compareTo(b.id) : order;
      });
    if (groups.isEmpty) return 0;

    final savedTurnGroupId = session.currentTurnGroupId;
    if (savedTurnGroupId != null) {
      final savedTurnIndex =
          groups.indexWhere((group) => group.id == savedTurnGroupId);
      if (savedTurnIndex >= 0) return savedTurnIndex;
    }

    final usedQuestions = session.questions
        .where(
            (question) => question.isUsed && question.selectedGroupId != null)
        .toList();
    if (usedQuestions.isEmpty) return 0;

    usedQuestions.sort((a, b) {
      final aUsedAt = DateTime.tryParse(a.usedAt ?? '');
      final bUsedAt = DateTime.tryParse(b.usedAt ?? '');
      if (aUsedAt != null && bUsedAt != null) {
        final dateOrder = bUsedAt.compareTo(aUsedAt);
        if (dateOrder != 0) return dateOrder;
      } else if (aUsedAt != null) {
        return -1;
      } else if (bUsedAt != null) {
        return 1;
      }

      return b.sequenceNumber.compareTo(a.sequenceNumber);
    });

    final lastGroupId = usedQuestions.first.selectedGroupId;
    final lastGroupIndex =
        groups.indexWhere((group) => group.id == lastGroupId);
    if (lastGroupIndex < 0) return 0;
    return (lastGroupIndex + 1) % groups.length;
  }

  // ── Timer ───────────────────────────────────────────────────────────────────

  void pauseTimer() {
    _stopTimer();
  }

  void startTimer() {
    if (state.timerRunning) return;
    state = state.copyWith(timerRunning: true);
    _timerTick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.timerRemaining <= 0) {
        _stopTimer();
        return;
      }
      state = state.copyWith(timerRemaining: state.timerRemaining - 1);
    });
  }

  void _stopTimer() {
    _timerTick?.cancel();
    state = state.copyWith(timerRunning: false);
  }

  void _resetTimer() {
    _stopTimer();
    state = state.copyWith(
      timerRemaining: state.session?.timerSeconds ?? 60,
    );
  }

  void resetTimer() {
    _resetTimer();
  }

  void resetAndStartTimer() {
    _resetTimer();
    startTimer();
  }

  Future<void> completeChallenge() async {
    final s = state.session;
    if (s == null) return;
    _stopTimer();
    final result = await _api.completeChallenge(s.id);
    final status = result['status']?.toString() ?? 'completed';
    state = state.copyWith(session: s.copyWith(status: status));
  }

  Future<void> _completeIfAllQuestionsUsed() async {
    if (state.allQuestionsUsed && state.session?.status != 'completed') {
      try {
        await completeChallenge();
      } catch (e) {
        state = state.copyWith(
          error: AppError.message(
            e,
            fallback: 'تعذر إكمال المنافسة تلقائياً. حاول مجدداً.',
          ),
        );
      }
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final challengeProvider =
    StateNotifierProvider<ChallengeNotifier, ChallengeArenaState>(
  (ref) => ChallengeNotifier(ref.watch(apiClientProvider)),
);

final savedChallengesProvider =
    FutureProvider<List<ChallengeSession>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final data = await api.getChallenges();
  return data.map((j) => ChallengeSession.fromJson(j)).toList();
});
