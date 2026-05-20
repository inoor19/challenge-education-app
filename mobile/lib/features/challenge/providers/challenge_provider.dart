import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
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

  Future<void> createChallenge({
    required SetupState setup,
    required List<String> groupNames,
    required int timerSeconds,
    required bool timerEnabled,
  }) async {
    state = state.copyWith(isLoading: true);

    final session = await _api.createChallenge({
      'grade_id': setup.selectedGrade!.id,
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
        error: 'تعذر رمي النرد من الخادم. حاول مجدداً.',
      );
    }
  }

  // ── Questions ───────────────────────────────────────────────────────────────

  void openQuestion(ChallengeQuestionItem question) {
    state = state.copyWith(activeQuestion: question, clearLastAnswer: true);
    if (state.session?.timerEnabled == true) {
      _resetTimer();
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

    final updatedSession = s.copyWith(
      groups: updatedGroups,
      questions: updatedQuestions,
    );

    _stopTimer();
    state = state.copyWith(
      session: updatedSession,
      lastAnswerResult: 'correct',
      clearActiveQuestion: true,
      clearDice: true,
      currentTurnIndex: _nextTurnIndex(),
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

    final updatedSession = s.copyWith(questions: updatedQuestions);

    _stopTimer();
    state = state.copyWith(
      session: updatedSession,
      lastAnswerResult: 'wrong',
      clearActiveQuestion: true,
      clearDice: true,
      currentTurnIndex: _nextTurnIndex(),
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

  int _nextTurnIndex() {
    final groupCount = state.groups.length;
    if (groupCount == 0) return 0;
    return (state.currentTurnIndex + 1) % groupCount;
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
      await completeChallenge();
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final challengeProvider =
    StateNotifierProvider<ChallengeNotifier, ChallengeArenaState>(
  (ref) => ChallengeNotifier(ref.watch(apiClientProvider)),
);
