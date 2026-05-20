import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/api_models.dart';
import '../../../core/providers/api_provider.dart';

// ─── Setup State ───────────────────────────────────────────────────────────────

class SetupState {
  final Grade? selectedGrade;
  final Subject? selectedSubject;
  final SubjectPart? selectedSubjectPart;
  final List<Chapter> selectedChapters;
  final List<Lesson> selectedLessons;
  final List<Question> selectedQuestions;

  const SetupState({
    this.selectedGrade,
    this.selectedSubject,
    this.selectedSubjectPart,
    this.selectedChapters = const [],
    this.selectedLessons = const [],
    this.selectedQuestions = const [],
  });

  SetupState copyWith({
    Grade? selectedGrade,
    Subject? selectedSubject,
    SubjectPart? selectedSubjectPart,
    List<Chapter>? selectedChapters,
    List<Lesson>? selectedLessons,
    List<Question>? selectedQuestions,
  }) =>
      SetupState(
        selectedGrade: selectedGrade ?? this.selectedGrade,
        selectedSubject: selectedSubject ?? this.selectedSubject,
        selectedSubjectPart: selectedSubjectPart ?? this.selectedSubjectPart,
        selectedChapters: selectedChapters ?? this.selectedChapters,
        selectedLessons: selectedLessons ?? this.selectedLessons,
        selectedQuestions: selectedQuestions ?? this.selectedQuestions,
      );

  bool get isReadyToChallenge =>
      selectedGrade != null &&
      selectedSubject != null &&
      selectedSubjectPart != null &&
      selectedChapters.isNotEmpty &&
      selectedLessons.isNotEmpty &&
      selectedQuestions.isNotEmpty;
}

// ─── Setup Notifier ────────────────────────────────────────────────────────────

class SetupNotifier extends StateNotifier<SetupState> {
  SetupNotifier() : super(const SetupState());

  void selectGrade(Grade grade) {
    state = SetupState(selectedGrade: grade);
  }

  void selectSubject(Subject subject) {
    state = SetupState(
      selectedGrade: state.selectedGrade,
      selectedSubject: subject,
    );
  }

  void selectSubjectPart(SubjectPart subjectPart) {
    state = state.copyWith(
      selectedSubjectPart: subjectPart,
      selectedChapters: [],
      selectedLessons: [],
      selectedQuestions: [],
    );
  }

  void toggleChapter(Chapter chapter) {
    final current = List<Chapter>.from(state.selectedChapters);
    if (current.any((c) => c.id == chapter.id)) {
      current.removeWhere((c) => c.id == chapter.id);
    } else {
      current.add(chapter);
    }
    state = state.copyWith(
      selectedChapters: current,
      selectedLessons: [],
      selectedQuestions: [],
    );
  }

  void toggleLesson(Lesson lesson) {
    final current = List<Lesson>.from(state.selectedLessons);
    if (current.any((l) => l.id == lesson.id)) {
      current.removeWhere((l) => l.id == lesson.id);
    } else {
      current.add(lesson);
    }
    state = state.copyWith(selectedLessons: current, selectedQuestions: []);
  }

  void selectAllLessons(List<Lesson> lessons) {
    state = state.copyWith(selectedLessons: lessons, selectedQuestions: []);
  }

  void toggleQuestion(Question question) {
    final current = List<Question>.from(state.selectedQuestions);
    if (current.any((q) => q.id == question.id)) {
      current.removeWhere((q) => q.id == question.id);
    } else {
      current.add(question);
    }
    state = state.copyWith(selectedQuestions: current);
  }

  void selectAllQuestions(List<Question> questions) {
    state = state.copyWith(selectedQuestions: questions);
  }

  void reset() {
    state = const SetupState();
  }
}

// ─── Providers ─────────────────────────────────────────────────────────────────

final setupProvider =
    StateNotifierProvider<SetupNotifier, SetupState>((ref) => SetupNotifier());

// Async data providers
final gradesProvider = FutureProvider<List<Grade>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final data = await api.getGrades();
  return data.map((j) => Grade.fromJson(j)).toList();
});

final subjectsProvider =
    FutureProvider.family<List<Subject>, int>((ref, gradeId) async {
  final api = ref.watch(apiClientProvider);
  final data = await api.getSubjects(gradeId);
  return data.map((j) => Subject.fromJson(j)).toList();
});

final chaptersProvider =
    FutureProvider.family<List<Chapter>, String>((ref, key) async {
  final api = ref.watch(apiClientProvider);
  final parts = key.split(':');
  final subjectId = int.parse(parts[0]);
  final subjectPartId = parts.length > 1 ? int.parse(parts[1]) : null;
  final data = await api.getChapters(subjectId, subjectPartId: subjectPartId);
  return data.map((j) => Chapter.fromJson(j)).toList();
});

final subjectPartsProvider =
    FutureProvider.family<List<SubjectPart>, int>((ref, subjectId) async {
  final api = ref.watch(apiClientProvider);
  final data = await api.getSubjectParts(subjectId);
  return data.map((j) => SubjectPart.fromJson(j)).toList();
});

final lessonsProvider =
    FutureProvider.family<List<Lesson>, String>((ref, chapterIdsKey) async {
  final api = ref.watch(apiClientProvider);
  final chapterIds = chapterIdsKey
      .split(',')
      .where((id) => id.isNotEmpty)
      .map(int.parse)
      .toList();
  final data = await api.getLessons(chapterIds);
  return data.map((j) => Lesson.fromJson(j)).toList();
});

final questionsProvider =
    FutureProvider.family<List<Question>, String>((ref, lessonIdsKey) async {
  final api = ref.watch(apiClientProvider);
  final lessonIds = lessonIdsKey
      .split(',')
      .where((id) => id.isNotEmpty)
      .map(int.parse)
      .toList();
  final data = await api.getQuestions(lessonIds);
  return data.map((j) => Question.fromJson(j)).toList();
});
