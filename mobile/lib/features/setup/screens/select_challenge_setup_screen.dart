import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/models/api_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/providers/api_provider.dart';
import '../../challenge/providers/challenge_provider.dart';
import '../../packages/screens/packages_screen.dart';
import '../providers/setup_provider.dart';
import 'setup_groups_screen.dart';

class SelectChallengeSetupScreen extends ConsumerStatefulWidget {
  final ChallengeSession? editChallenge;

  const SelectChallengeSetupScreen({
    super.key,
    this.editChallenge,
  });

  @override
  ConsumerState<SelectChallengeSetupScreen> createState() =>
      _SelectChallengeSetupScreenState();
}

class _SelectChallengeSetupScreenState
    extends ConsumerState<SelectChallengeSetupScreen> {
  String? _initializedLessonKey;
  bool _prefilled = false;
  bool _isSavingEdit = false;

  bool get _isEditing => widget.editChallenge != null;

  void _openPackages({int? initialSubjectId, String? initialSubjectName}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PackagesScreen(
          initialSubjectId: initialSubjectId,
          initialSubjectName: initialSubjectName,
        ),
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<String?> _askForName({
    required String title,
    required String label,
  }) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _NameInputDialog(
        title: title,
        label: label,
      ),
    );
    return result?.trim().isEmpty == true ? null : result;
  }

  Future<void> _addSubject() async {
    final setup = ref.read(setupProvider);
    final grade = setup.selectedGrade;
    if (grade == null) return;

    final name = await _askForName(
      title: 'إضافة مادة',
      label: 'اسم المادة',
    );
    if (name == null) return;

    try {
      final api = ref.read(apiClientProvider);
      final created = Subject.fromJson(
          await api.createTeacherSubject({'grade_id': grade.id, 'name': name}));
      _initializedLessonKey = null;
      ref.read(setupProvider.notifier).selectSubject(created);
      ref.invalidate(subjectsProvider(grade.id));
      _showMessage('تمت إضافة المادة.');
    } catch (e) {
      _showMessage(
        AppError.message(e, fallback: 'تعذر إضافة المادة. حاول مجدداً.'),
      );
    }
  }

  Future<void> _addSubjectPart() async {
    final setup = ref.read(setupProvider);
    final subject = setup.selectedSubject;
    if (subject == null) return;

    final name = await _askForName(
      title: 'إضافة جزء',
      label: 'اسم الجزء',
    );
    if (name == null) return;

    try {
      final api = ref.read(apiClientProvider);
      final created = SubjectPart.fromJson(await api.createTeacherSubjectPart({
        'subject_id': subject.id,
        'name': name,
      }));
      _initializedLessonKey = null;
      ref.read(setupProvider.notifier).selectSubjectPart(created);
      ref.invalidate(subjectPartsProvider(subject.id));
      _showMessage('تمت إضافة الجزء.');
    } catch (e) {
      _showMessage(
        AppError.message(e, fallback: 'تعذر إضافة الجزء. حاول مجدداً.'),
      );
    }
  }

  Future<void> _addChapter() async {
    final setup = ref.read(setupProvider);
    final subject = setup.selectedSubject;
    final part = setup.selectedSubjectPart;
    if (subject == null || part == null) return;

    final name = await _askForName(
      title: 'إضافة فصل',
      label: 'اسم الفصل',
    );
    if (name == null) return;

    try {
      final api = ref.read(apiClientProvider);
      final created = Chapter.fromJson(await api.createTeacherChapter({
        'subject_id': subject.id,
        'subject_part_id': part.id,
        'name': name,
      }));

      _initializedLessonKey = null;
      ref.read(setupProvider.notifier).selectChapters([
        ...setup.selectedChapters,
        created,
      ]);

      ref.invalidate(chaptersProvider('${subject.id}:${part.id}'));
      _showMessage('تمت إضافة الفصل.');
    } catch (e) {
      _showMessage(
        AppError.message(e, fallback: 'تعذر إضافة الفصل. حاول مجدداً.'),
      );
    }
  }

  Future<void> _addLesson() async {
    final setup = ref.read(setupProvider);
    if (setup.selectedChapters.isEmpty) return;

    // Choose a chapter from selected ones (especially when multiple selected)
    final selectedChapterId = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('اختر الفصل لإضافة درس'),
        children: [
          for (final chapter in setup.selectedChapters)
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(chapter.id),
              child: Text(chapter.name),
            ),
        ],
      ),
    );
    if (selectedChapterId == null) return;

    final name = await _askForName(
      title: 'إضافة درس',
      label: 'اسم الدرس',
    );
    if (name == null) return;

    try {
      final api = ref.read(apiClientProvider);
      final created = Lesson.fromJson(await api.createTeacherLesson({
        'chapter_id': selectedChapterId,
        'name': name,
      }));

      _initializedLessonKey = null;
      ref.read(setupProvider.notifier).selectLessons([
        ...setup.selectedLessons,
        created,
      ]);

      final chapterIds = ref
          .read(setupProvider)
          .selectedChapters
          .map((c) => c.id)
          .toList()
        ..sort();
      ref.invalidate(lessonsProvider(chapterIds.join(',')));
      _showMessage('تمت إضافة الدرس.');
    } catch (e) {
      _showMessage(
        AppError.message(e, fallback: 'تعذر إضافة الدرس. حاول مجدداً.'),
      );
    }
  }

  Future<void> _addQuestion() async {
    final setup = ref.read(setupProvider);
    if (setup.selectedLessons.isEmpty) return;

    final selectedLessonId = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('اختر الدرس لإضافة سؤال'),
        children: [
          for (final lesson in setup.selectedLessons)
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(lesson.id),
              child: Text(lesson.name),
            ),
        ],
      ),
    );
    if (selectedLessonId == null) return;

    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _QuestionInputDialog(),
    );

    try {
      if (payload == null) return;
      final text = (payload['question_text'] as String? ?? '').trim();
      final correct = (payload['correct_answer'] as String? ?? '').trim();
      final questionType = payload['question_type'] as String?;
      if (text.isEmpty || (questionType != 'text' && correct.isEmpty)) {
        _showMessage(
          questionType == 'text'
              ? 'نص السؤال مطلوب.'
              : 'نص السؤال والإجابة الصحيحة مطلوبان.',
        );
        return;
      }

      final api = ref.read(apiClientProvider);
      await api.createTeacherQuestion({
        'lesson_id': selectedLessonId,
        'question_text': text,
        'question_type': questionType,
        if (questionType == 'multiple_choice') ...{
          'option_a': payload['option_a'],
          'option_b': payload['option_b'],
          'option_c': payload['option_c'],
          'option_d': payload['option_d'],
        },
        'correct_answer': correct,
        'level': payload['level'],
      });

      _initializedLessonKey = null;
      final lessonIds = ref
          .read(setupProvider)
          .selectedLessons
          .map((l) => l.id)
          .toList()
        ..sort();
      ref.invalidate(questionsProvider(lessonIds.join(',')));
      _showMessage('تمت إضافة السؤال.');
    } catch (e) {
      _showMessage(
        AppError.message(e, fallback: 'تعذر إضافة السؤال. حاول مجدداً.'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final setup = ref.watch(setupProvider);
    final grade = setup.selectedGrade;

    if (_isEditing && !_prefilled) {
      final session = widget.editChallenge!;
      Future.microtask(() {
        ref.read(setupProvider.notifier).loadFromChallenge(session);
        if (mounted) {
          setState(() {
            _initializedLessonKey = null;
            _prefilled = true;
          });
        }
      });
    }

    if (grade == null) {
      return const Scaffold(
        body: AppStateView(
          icon: Icons.school_rounded,
          title: 'اختر الصف أولاً',
          message: 'ارجع للشاشة الرئيسية واختر الصف الدراسي لبدء الإعداد.',
        ),
      );
    }

    final subjectsAsync = setup.selectedGradeSection == null
        ? null
        : ref.watch(subjectsProvider(grade.id));
    final gradeSuggestionsAsync = setup.selectedGradeSection == null
        ? null
        : ref.watch(packageSuggestionsProvider('grade:${grade.id}'));
    final subjectSuggestionsAsync = setup.selectedSubject == null
        ? null
        : ref.watch(
            packageSuggestionsProvider('subject:${setup.selectedSubject!.id}'),
          );
    final partsAsync = setup.selectedSubject == null
        ? null
        : ref.watch(subjectPartsProvider(setup.selectedSubject!.id));
    final chaptersAsync =
        setup.selectedSubject == null || setup.selectedSubjectPart == null
            ? null
            : ref.watch(chaptersProvider(
                '${setup.selectedSubject!.id}:${setup.selectedSubjectPart!.id}',
              ));
    final chapterIds = setup.selectedChapters.map((c) => c.id).toList()..sort();
    final lessonsAsync = setup.selectedChapters.isEmpty
        ? null
        : ref.watch(lessonsProvider(chapterIds.join(',')));
    final lessonIds = setup.selectedLessons.map((l) => l.id).toList()..sort();
    final lessonKey = lessonIds.join(',');
    final questionsAsync = setup.selectedLessons.isEmpty
        ? null
        : ref.watch(questionsProvider(lessonKey));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing
              ? 'تعديل الأسئلة — ${grade.name}'
              : 'إعداد المنافسة — ${grade.name}',
        ),
      ),
      body: Column(
        children: [
          AppPageHeader(
            icon: Icons.tune_rounded,
            title: _isEditing ? 'تعديل الأسئلة' : 'إعداد المنافسة',
            subtitle: setup.selectedGradeSection == null
                ? grade.name
                : '${grade.name} (${setup.selectedGradeSection})',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_isEditing)
                  _LockedChallengeContextSection(
                    gradeName: grade.name,
                    gradeSection: setup.selectedGradeSection,
                    subjectName: setup.selectedSubject?.name,
                  )
                else
                  _GradeSectionSection(
                    selectedSection: setup.selectedGradeSection,
                    onSelected: (section) {
                      _initializedLessonKey = null;
                      ref
                          .read(setupProvider.notifier)
                          .selectGradeSection(section);
                    },
                  ),
                if (!_isEditing && setup.selectedGradeSection != null)
                  _SubjectsSelectionSection(
                    asyncValue: subjectsAsync!,
                    suggestionsAsync: gradeSuggestionsAsync!,
                    selectedItem: setup.selectedSubject,
                    onRetry: () => ref.invalidate(subjectsProvider(grade.id)),
                    onBuyPackages: _openPackages,
                    onAdd: _addSubject,
                    onSelected: (subject) {
                      _initializedLessonKey = null;
                      ref.read(setupProvider.notifier).selectSubject(subject);
                    },
                  ),
                if (setup.selectedSubject != null)
                  _AsyncSingleSelectionSection<SubjectPart>(
                    title: 'الأجزاء',
                    icon: Icons.layers_rounded,
                    asyncValue: partsAsync!,
                    selectedItem: setup.selectedSubjectPart,
                    idOf: (part) => part.id,
                    itemLabel: (part) => part.name,
                    itemIcon: (_) => Icons.layers_rounded,
                    itemKeyPrefix: 'setup-part-card',
                    emptyMessage: 'لا توجد أجزاء متاحة لهذه المادة.',
                    extraGridChildren: [
                      _AddSelectionCard(
                        label: 'إضافة جزء',
                        onTap: _addSubjectPart,
                      ),
                    ],
                    onRetry: () => ref.invalidate(
                      subjectPartsProvider(setup.selectedSubject!.id),
                    ),
                    onSelected: (part) {
                      _initializedLessonKey = null;
                      ref.read(setupProvider.notifier).selectSubjectPart(part);
                    },
                  ),
                if (setup.selectedSubjectPart != null)
                  _AsyncMultiSelectionSection<Chapter>(
                    title: 'الفصول',
                    icon: Icons.view_module_rounded,
                    asyncValue: chaptersAsync!,
                    selectedItems: setup.selectedChapters,
                    idOf: (chapter) => chapter.id,
                    itemLabel: (chapter) => chapter.name,
                    itemIcon: (_) => Icons.view_module_rounded,
                    itemKeyPrefix: 'setup-chapter-card',
                    emptyMessage: 'لا توجد فصول لهذا الجزء.',
                    selectedCountLabel: (count) => 'تم اختيار $count فصل',
                    extraGridChildren: [
                      _AddSelectionCard(
                        label: 'إضافة فصل',
                        onTap: _addChapter,
                      ),
                    ],
                    onRetry: () => ref.invalidate(chaptersProvider(
                      '${setup.selectedSubject!.id}:${setup.selectedSubjectPart!.id}',
                    )),
                    onChanged: (chapters) {
                      _initializedLessonKey = null;
                      ref.read(setupProvider.notifier).selectChapters(chapters);
                    },
                  ),
                if (setup.selectedChapters.isNotEmpty)
                  _AsyncMultiSelectionSection<Lesson>(
                    title: 'الدروس',
                    icon: Icons.assignment_rounded,
                    asyncValue: lessonsAsync!,
                    selectedItems: setup.selectedLessons,
                    idOf: (lesson) => lesson.id,
                    itemLabel: (lesson) => lesson.name,
                    itemIcon: (_) => Icons.assignment_rounded,
                    itemKeyPrefix: 'setup-lesson-card',
                    emptyMessage: 'لا توجد دروس للفصول المحددة.',
                    selectedCountLabel: (count) => 'تم اختيار $count درس',
                    extraGridChildren: [
                      _AddSelectionCard(
                        label: 'إضافة درس',
                        onTap: _addLesson,
                      ),
                    ],
                    onRetry: () => ref.invalidate(
                      lessonsProvider(chapterIds.join(',')),
                    ),
                    onChanged: (lessons) {
                      _initializedLessonKey = null;
                      ref.read(setupProvider.notifier).selectLessons(lessons);
                    },
                  ),
                if (setup.selectedLessons.isNotEmpty)
                  _QuestionsSection(
                    questionsAsync: questionsAsync!,
                    lessonKey: lessonKey,
                    initializedLessonKey: _initializedLessonKey,
                    selectedQuestions: setup.selectedQuestions,
                    suggestionsAsync: subjectSuggestionsAsync!,
                    onBuyPackages: () => _openPackages(
                      initialSubjectId: setup.selectedSubject!.id,
                      initialSubjectName: setup.selectedSubject!.name,
                    ),
                    onAddQuestion: _addQuestion,
                    onInitialized: (key) {
                      if (mounted) {
                        setState(() => _initializedLessonKey = key);
                      }
                    },
                    onRetry: () => ref.invalidate(questionsProvider(lessonKey)),
                    onChanged: (questions) => ref
                        .read(setupProvider.notifier)
                        .selectAllQuestions(questions),
                  ),
              ],
            ),
          ),
          _isEditing
              ? _EditBottomBar(
                  isSaving: _isSavingEdit,
                  enabled: setup.isReadyToChallenge && !_isSavingEdit,
                  setup: setup,
                  onSave: () async {
                    if (_isSavingEdit) return;
                    setState(() => _isSavingEdit = true);
                    try {
                      await ref
                          .read(challengeProvider.notifier)
                          .updateChallengeSetup(
                            challengeId: widget.editChallenge!.id,
                            setup: setup,
                          );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم حفظ التعديل.')),
                        );
                        Navigator.of(context).pop(true);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppError.message(
                                e,
                                fallback: 'تعذر حفظ التعديل. حاول مجدداً.',
                              ),
                            ),
                          ),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isSavingEdit = false);
                    }
                  },
                )
              : _BottomBar(
                  setup: setup,
                  onNext: setup.isReadyToChallenge
                      ? () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SetupGroupsScreen(),
                            ),
                          )
                      : null,
                ),
        ],
      ),
    );
  }
}

class _QuestionsSection extends StatelessWidget {
  final AsyncValue<List<Question>> questionsAsync;
  final String lessonKey;
  final String? initializedLessonKey;
  final List<Question> selectedQuestions;
  final AsyncValue<List<QuestionPackage>> suggestionsAsync;
  final VoidCallback onBuyPackages;
  final VoidCallback onAddQuestion;
  final ValueChanged<String> onInitialized;
  final VoidCallback onRetry;
  final ValueChanged<List<Question>> onChanged;

  const _QuestionsSection({
    required this.questionsAsync,
    required this.lessonKey,
    required this.initializedLessonKey,
    required this.selectedQuestions,
    required this.suggestionsAsync,
    required this.onBuyPackages,
    required this.onAddQuestion,
    required this.onInitialized,
    required this.onRetry,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return questionsAsync.when(
      loading: () => const _LoadingSection(
        title: 'الأسئلة',
        icon: Icons.quiz_rounded,
      ),
      error: (e, _) => _ErrorSection(
        title: 'الأسئلة',
        icon: Icons.quiz_rounded,
        message: AppError.message(
          e,
          fallback: 'تعذر تحميل الأسئلة. حاول مجدداً.',
        ),
        onRetry: onRetry,
      ),
      data: (questions) {
        if (initializedLessonKey != lessonKey) {
          Future.microtask(() {
            onChanged(questions);
            onInitialized(lessonKey);
          });
        }

        final suggestionCards = suggestionsAsync.maybeWhen(
          data: (suggestions) => suggestions.isEmpty
              ? const <Widget>[]
              : <Widget>[
                  _PackageSuggestionCard(onPressed: onBuyPackages),
                ],
          orElse: () => const <Widget>[],
        );

        return _MultiSelectionSection<Question>(
          title: 'الأسئلة',
          icon: Icons.quiz_rounded,
          items: questions,
          selectedItems: selectedQuestions,
          idOf: (question) => question.id,
          itemLabel: (question) => question.questionText,
          itemIcon: (question) => question.isHard
              ? Icons.local_fire_department_rounded
              : Icons.lightbulb_rounded,
          itemKeyPrefix: 'setup-question-card',
          emptyMessage: 'لا توجد أسئلة لهذه الدروس.',
          selectedCountLabel: (count) => '$count سؤال محدد',
          extraGridChildren: [
            _AddSelectionCard(label: 'إضافة سؤال', onTap: onAddQuestion),
            ...suggestionCards,
          ],
          onChanged: onChanged,
        );
      },
    );
  }
}

class _SubjectsSelectionSection extends StatelessWidget {
  final AsyncValue<List<Subject>> asyncValue;
  final AsyncValue<List<QuestionPackage>> suggestionsAsync;
  final Subject? selectedItem;
  final VoidCallback onRetry;
  final VoidCallback onBuyPackages;
  final VoidCallback onAdd;
  final ValueChanged<Subject> onSelected;

  const _SubjectsSelectionSection({
    required this.asyncValue,
    required this.suggestionsAsync,
    required this.selectedItem,
    required this.onRetry,
    required this.onBuyPackages,
    required this.onAdd,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return asyncValue.when(
      loading: () => const _LoadingSection(
        title: 'المواد',
        icon: Icons.menu_book_rounded,
      ),
      error: (e, _) => _ErrorSection(
        title: 'المواد',
        icon: Icons.menu_book_rounded,
        message: AppError.message(
          e,
          fallback: 'تعذر تحميل المواد. حاول مجدداً.',
        ),
        onRetry: onRetry,
      ),
      data: (subjects) {
        final suggestionCards = suggestionsAsync.maybeWhen(
          data: (suggestions) => suggestions.isEmpty
              ? const <Widget>[]
              : <Widget>[
                  _PackageSuggestionCard(onPressed: onBuyPackages),
                ],
          orElse: () => const <Widget>[],
        );

        if (subjects.isEmpty && suggestionCards.isNotEmpty) {
          return _PurchasePromptSection(onBuyPackages: onBuyPackages);
        }

        return _SingleSelectionSection<Subject>(
          title: 'المواد',
          icon: Icons.menu_book_rounded,
          items: subjects,
          selectedItem: selectedItem,
          idOf: (subject) => subject.id,
          itemLabel: (subject) => subject.name,
          itemIcon: (_) => Icons.auto_stories_rounded,
          itemKeyPrefix: 'setup-subject-card',
          emptyMessage: 'لا توجد مواد متاحة لهذا الصف.',
          extraGridChildren: [
            _AddSelectionCard(label: 'إضافة مادة', onTap: onAdd),
            ...suggestionCards,
          ],
          onSelected: onSelected,
        );
      },
    );
  }
}

class _PurchasePromptSection extends StatelessWidget {
  final VoidCallback onBuyPackages;

  const _PurchasePromptSection({required this.onBuyPackages});

  @override
  Widget build(BuildContext context) {
    return _SetupCard(
      icon: Icons.shopping_bag_rounded,
      title: 'شراء حزم الأسئلة',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'لا توجد أسئلة متاحة لهذا الصف حالياً. يمكنك شراء حزمة أسئلة لفتح محتوى جديد.',
            style: TextStyle(
              fontFamily: 'Tajawal',
              color: AppTheme.textDark,
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            key: const ValueKey('setup-buy-packages-empty-subjects'),
            onPressed: onBuyPackages,
            icon: const Icon(Icons.add_shopping_cart_rounded),
            label: const Text('شراء حزم الأسئلة'),
          ),
        ],
      ),
    );
  }
}

class _GradeSectionSection extends StatelessWidget {
  static const sections = ['أ', 'ب', 'ج'];

  final String? selectedSection;
  final ValueChanged<String> onSelected;

  const _GradeSectionSection({
    required this.selectedSection,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final sectionColor =
        AppTheme.iconAccent(Icons.meeting_room_rounded.codePoint);

    return _SetupCard(
      icon: Icons.meeting_room_rounded,
      title: 'الشعبة',
      trailing: selectedSection == null
          ? null
          : const StatusBadge(
              label: 'تم الاختيار',
              color: AppTheme.success,
              icon: Icons.check_circle_rounded,
            ),
      child: _SelectionGrid(
        children: [
          for (final section in sections)
            _SelectionCard(
              key: ValueKey('setup-section-card-$section'),
              label: '$section',
              icon: Icons.groups_2_rounded,
              color: sectionColor,
              isSelected: selectedSection == section,
              onTap: () => onSelected(section),
            ),
        ],
      ),
    );
  }
}

class _LockedChallengeContextSection extends StatelessWidget {
  final String gradeName;
  final String? gradeSection;
  final String? subjectName;

  const _LockedChallengeContextSection({
    required this.gradeName,
    required this.gradeSection,
    required this.subjectName,
  });

  @override
  Widget build(BuildContext context) {
    final pieces = [
      gradeSection == null ? gradeName : '$gradeName ($gradeSection)',
      if (subjectName != null) subjectName!,
    ];

    return _SetupCard(
      icon: Icons.lock_rounded,
      title: 'نطاق التعديل',
      trailing: const StatusBadge(
        label: 'ثابت',
        color: AppTheme.textMuted,
        icon: Icons.lock_rounded,
      ),
      child: Text(
        pieces.join(' - '),
        style: const TextStyle(
          fontFamily: 'Tajawal',
          color: AppTheme.textDark,
          fontWeight: FontWeight.w900,
          height: 1.5,
        ),
      ),
    );
  }
}

class _AsyncSingleSelectionSection<T> extends StatelessWidget {
  final String title;
  final IconData icon;
  final AsyncValue<List<T>> asyncValue;
  final T? selectedItem;
  final int Function(T item) idOf;
  final String Function(T item) itemLabel;
  final IconData Function(T item) itemIcon;
  final String itemKeyPrefix;
  final String emptyMessage;
  final VoidCallback onRetry;
  final ValueChanged<T> onSelected;
  final List<Widget> extraGridChildren;

  const _AsyncSingleSelectionSection({
    required this.title,
    required this.icon,
    required this.asyncValue,
    required this.selectedItem,
    required this.idOf,
    required this.itemLabel,
    required this.itemIcon,
    required this.itemKeyPrefix,
    required this.emptyMessage,
    required this.onRetry,
    required this.onSelected,
    this.extraGridChildren = const [],
  });

  @override
  Widget build(BuildContext context) {
    return asyncValue.when(
      loading: () => _LoadingSection(title: title, icon: icon),
      error: (e, _) => _ErrorSection(
        title: title,
        icon: icon,
        message: AppError.message(
          e,
          fallback: 'تعذر تحميل البيانات. حاول مجدداً.',
        ),
        onRetry: onRetry,
      ),
      data: (items) => _SingleSelectionSection<T>(
        title: title,
        icon: icon,
        items: items,
        selectedItem: selectedItem,
        idOf: idOf,
        itemLabel: itemLabel,
        itemIcon: itemIcon,
        itemKeyPrefix: itemKeyPrefix,
        emptyMessage: emptyMessage,
        extraGridChildren: extraGridChildren,
        onSelected: onSelected,
      ),
    );
  }
}

class _AsyncMultiSelectionSection<T> extends StatelessWidget {
  final String title;
  final IconData icon;
  final AsyncValue<List<T>> asyncValue;
  final List<T> selectedItems;
  final int Function(T item) idOf;
  final String Function(T item) itemLabel;
  final IconData Function(T item) itemIcon;
  final String itemKeyPrefix;
  final String emptyMessage;
  final String Function(int count) selectedCountLabel;
  final VoidCallback onRetry;
  final ValueChanged<List<T>> onChanged;
  final List<Widget> extraGridChildren;

  const _AsyncMultiSelectionSection({
    required this.title,
    required this.icon,
    required this.asyncValue,
    required this.selectedItems,
    required this.idOf,
    required this.itemLabel,
    required this.itemIcon,
    required this.itemKeyPrefix,
    required this.emptyMessage,
    required this.selectedCountLabel,
    required this.onRetry,
    required this.onChanged,
    this.extraGridChildren = const [],
  });

  @override
  Widget build(BuildContext context) {
    return asyncValue.when(
      loading: () => _LoadingSection(title: title, icon: icon),
      error: (e, _) => _ErrorSection(
        title: title,
        icon: icon,
        message: AppError.message(
          e,
          fallback: 'تعذر تحميل البيانات. حاول مجدداً.',
        ),
        onRetry: onRetry,
      ),
      data: (items) => _MultiSelectionSection<T>(
        title: title,
        icon: icon,
        items: items,
        selectedItems: selectedItems,
        idOf: idOf,
        itemLabel: itemLabel,
        itemIcon: itemIcon,
        itemKeyPrefix: itemKeyPrefix,
        emptyMessage: emptyMessage,
        selectedCountLabel: selectedCountLabel,
        extraGridChildren: extraGridChildren,
        onChanged: onChanged,
      ),
    );
  }
}

class _SingleSelectionSection<T> extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<T> items;
  final T? selectedItem;
  final int Function(T item) idOf;
  final String Function(T item) itemLabel;
  final IconData Function(T item) itemIcon;
  final String itemKeyPrefix;
  final String emptyMessage;
  final ValueChanged<T> onSelected;
  final List<Widget> extraGridChildren;

  const _SingleSelectionSection({
    required this.title,
    required this.icon,
    required this.items,
    required this.selectedItem,
    required this.idOf,
    required this.itemLabel,
    required this.itemIcon,
    required this.itemKeyPrefix,
    required this.emptyMessage,
    required this.onSelected,
    this.extraGridChildren = const [],
  });

  @override
  Widget build(BuildContext context) {
    final currentItem = selectedItem;
    final selectedId = currentItem == null ? null : idOf(currentItem);
    final sectionColor = AppTheme.iconAccent(icon.codePoint);

    return _SetupCard(
      icon: icon,
      title: title,
      trailing: selectedId == null
          ? null
          : StatusBadge(
              label: 'تم الاختيار',
              color: AppTheme.success,
              icon: Icons.check_circle_rounded,
            ),
      child: items.isEmpty && extraGridChildren.isEmpty
          ? _EmptyLine(message: emptyMessage)
          : _SelectionGrid(
              children: [
                for (var index = 0; index < items.length; index++)
                  _SelectionCard(
                    key: ValueKey('$itemKeyPrefix-${idOf(items[index])}'),
                    label: itemLabel(items[index]),
                    icon: itemIcon(items[index]),
                    color: sectionColor,
                    isSelected: selectedId == idOf(items[index]),
                    onTap: () => onSelected(items[index]),
                  ),
                ...extraGridChildren,
              ],
            ),
    );
  }
}

class _MultiSelectionSection<T> extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<T> items;
  final List<T> selectedItems;
  final int Function(T item) idOf;
  final String Function(T item) itemLabel;
  final IconData Function(T item) itemIcon;
  final String itemKeyPrefix;
  final String emptyMessage;
  final String Function(int count) selectedCountLabel;
  final List<Widget> extraGridChildren;
  final ValueChanged<List<T>> onChanged;

  const _MultiSelectionSection({
    required this.title,
    required this.icon,
    required this.items,
    required this.selectedItems,
    required this.idOf,
    required this.itemLabel,
    required this.itemIcon,
    required this.itemKeyPrefix,
    required this.emptyMessage,
    required this.selectedCountLabel,
    this.extraGridChildren = const [],
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selectedIds = selectedItems.map(idOf).toSet();
    final selectedCount =
        items.where((item) => selectedIds.contains(idOf(item))).length;
    final allSelected = items.isNotEmpty && selectedCount == items.length;
    final sectionColor = AppTheme.iconAccent(icon.codePoint);

    return _SetupCard(
      icon: icon,
      title: title,
      trailing: items.isEmpty
          ? null
          : TextButton.icon(
              key: ValueKey('$itemKeyPrefix-toggle-all'),
              onPressed: () => onChanged(allSelected ? [] : items),
              icon: Icon(
                allSelected ? Icons.deselect_rounded : Icons.select_all_rounded,
              ),
              label: Text(allSelected ? 'إلغاء تحديد الكل' : 'تحديد الكل'),
            ),
      footer: selectedCount == 0
          ? null
          : StatusBadge(
              label: selectedCountLabel(selectedCount),
              color: AppTheme.success,
              icon: Icons.check_circle_rounded,
            ),
      child: items.isEmpty && extraGridChildren.isEmpty
          ? _EmptyLine(message: emptyMessage)
          : _SelectionGrid(
              children: [
                for (var index = 0; index < items.length; index++)
                  _SelectionCard(
                    key: ValueKey('$itemKeyPrefix-${idOf(items[index])}'),
                    label: itemLabel(items[index]),
                    icon: itemIcon(items[index]),
                    color: sectionColor,
                    isSelected: selectedIds.contains(idOf(items[index])),
                    onTap: () {
                      final next = <T>[...selectedItems];
                      final item = items[index];
                      final itemId = idOf(item);
                      if (selectedIds.contains(itemId)) {
                        next.removeWhere(
                            (selected) => idOf(selected) == itemId);
                      } else {
                        next.add(item);
                      }
                      onChanged(next);
                    },
                  ),
                ...extraGridChildren,
              ],
            ),
    );
  }
}

class _PackageSuggestionCard extends StatelessWidget {
  final VoidCallback onPressed;

  const _PackageSuggestionCard({
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    const color = AppTheme.cardGold;

    return Material(
      key: const ValueKey('setup-question-package-suggestions'),
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minHeight: 82),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.32)),
          ),
          child: Row(
            children: [
              const AppIconBadge(
                icon: Icons.add_rounded,
                color: color,
                size: 42,
                iconSize: 24,
                filled: true,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'شراء أسئلة إضافية لهذه المادة',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.w900,
                        height: 1.25,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'يفتح قائمة حزم المادة',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        color: AppTheme.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionGrid extends StatelessWidget {
  final List<Widget> children;

  const _SelectionGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 760
            ? 3
            : constraints.maxWidth > 520
                ? 2
                : 1;
        final width = (constraints.maxWidth - (columns - 1) * 10) / columns;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

class _SelectionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectionCard({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? color.withValues(alpha: 0.15) : AppTheme.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minHeight: 82),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : color.withValues(alpha: 0.18),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              AppIconBadge(
                icon: isSelected ? Icons.check_circle_rounded : icon,
                color: color,
                size: 42,
                iconSize: 23,
                filled: isSelected,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    color: isSelected ? color : AppTheme.textDark,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddSelectionCard extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AddSelectionCard({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.cardGold;
    return _SelectionCard(
      label: label,
      icon: Icons.add_rounded,
      color: color,
      isSelected: false,
      onTap: onTap,
    );
  }
}

class _NameInputDialog extends StatefulWidget {
  final String title;
  final String label;

  const _NameInputDialog({
    required this.title,
    required this.label,
  });

  @override
  State<_NameInputDialog> createState() => _NameInputDialogState();
}

class _NameInputDialogState extends State<_NameInputDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close(String? value) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(labelText: widget.label),
        autofocus: true,
        onSubmitted: (value) => _close(value.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => _close(null),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () => _close(_controller.text.trim()),
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}

class _QuestionInputDialog extends StatefulWidget {
  const _QuestionInputDialog();

  @override
  State<_QuestionInputDialog> createState() => _QuestionInputDialogState();
}

class _QuestionInputDialogState extends State<_QuestionInputDialog> {
  final _questionText = TextEditingController();
  final _optionA = TextEditingController();
  final _optionB = TextEditingController();
  final _optionC = TextEditingController();
  final _optionD = TextEditingController();
  String _questionType = 'multiple_choice';
  String _level = 'easy';
  String _trueFalseAnswer = 'صح';
  String _correctOptionKey = 'option_a';
  String? _error;

  @override
  void dispose() {
    _questionText.dispose();
    _optionA.dispose();
    _optionB.dispose();
    _optionC.dispose();
    _optionD.dispose();
    super.dispose();
  }

  void _close(Map<String, dynamic>? payload) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(payload);
  }

  String _selectedCorrectAnswer() {
    if (_questionType == 'true_false') {
      return _trueFalseAnswer;
    }

    if (_questionType == 'multiple_choice') {
      return switch (_correctOptionKey) {
        'option_a' => _optionA.text.trim(),
        'option_b' => _optionB.text.trim(),
        'option_c' => _optionC.text.trim(),
        'option_d' => _optionD.text.trim(),
        _ => '',
      };
    }

    return '';
  }

  void _save() {
    final correctAnswer = _selectedCorrectAnswer();
    if (_questionType == 'multiple_choice' && correctAnswer.isEmpty) {
      setState(() {
        _error = 'اختر إجابة صحيحة من الخيارات المكتوبة.';
      });
      return;
    }

    _close({
      'question_text': _questionText.text.trim(),
      'question_type': _questionType,
      'option_a': _optionA.text.trim(),
      'option_b': _optionB.text.trim(),
      'option_c': _optionC.text.trim(),
      'option_d': _optionD.text.trim(),
      'correct_answer': correctAnswer,
      'level': _level,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة سؤال'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _questionType,
              items: const [
                DropdownMenuItem(
                  value: 'multiple_choice',
                  child: Text('اختيار من متعدد'),
                ),
                DropdownMenuItem(value: 'true_false', child: Text('صح/خطأ')),
                DropdownMenuItem(
                    value: 'text', child: Text('نصي (تصحيح يدوي)')),
              ],
              onChanged: (value) => setState(() {
                _questionType = value ?? 'multiple_choice';
                _error = null;
              }),
              decoration: const InputDecoration(labelText: 'نوع السؤال'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _level,
              items: const [
                DropdownMenuItem(value: 'easy', child: Text('سهل')),
                DropdownMenuItem(value: 'hard', child: Text('صعب')),
              ],
              onChanged: (value) => setState(() {
                _level = value ?? 'easy';
              }),
              decoration: const InputDecoration(labelText: 'المستوى'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _questionText,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'نص السؤال'),
            ),
            const SizedBox(height: 10),
            if (_questionType == 'multiple_choice') ...[
              TextField(
                controller: _optionA,
                decoration: const InputDecoration(labelText: 'الخيار A'),
              ),
              _CorrectOptionCheckbox(
                key: const ValueKey('question-correct-option-a'),
                label: 'الخيار A هو الإجابة الصحيحة',
                value: _correctOptionKey == 'option_a',
                onChanged: () => setState(() {
                  _correctOptionKey = 'option_a';
                  _error = null;
                }),
              ),
              TextField(
                controller: _optionB,
                decoration: const InputDecoration(labelText: 'الخيار B'),
              ),
              _CorrectOptionCheckbox(
                key: const ValueKey('question-correct-option-b'),
                label: 'الخيار B هو الإجابة الصحيحة',
                value: _correctOptionKey == 'option_b',
                onChanged: () => setState(() {
                  _correctOptionKey = 'option_b';
                  _error = null;
                }),
              ),
              TextField(
                controller: _optionC,
                decoration: const InputDecoration(labelText: 'الخيار C'),
              ),
              _CorrectOptionCheckbox(
                key: const ValueKey('question-correct-option-c'),
                label: 'الخيار C هو الإجابة الصحيحة',
                value: _correctOptionKey == 'option_c',
                onChanged: () => setState(() {
                  _correctOptionKey = 'option_c';
                  _error = null;
                }),
              ),
              TextField(
                controller: _optionD,
                decoration: const InputDecoration(labelText: 'الخيار D'),
              ),
              _CorrectOptionCheckbox(
                key: const ValueKey('question-correct-option-d'),
                label: 'الخيار D هو الإجابة الصحيحة',
                value: _correctOptionKey == 'option_d',
                onChanged: () => setState(() {
                  _correctOptionKey = 'option_d';
                  _error = null;
                }),
              ),
            ] else if (_questionType == 'true_false') ...[
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  key: const ValueKey('question-correct-true-false'),
                  segments: const [
                    ButtonSegment(value: 'صح', label: Text('صح')),
                    ButtonSegment(value: 'خطأ', label: Text('خطأ')),
                  ],
                  selected: {_trueFalseAnswer},
                  onSelectionChanged: (values) => setState(() {
                    _trueFalseAnswer = values.first;
                    _error = null;
                  }),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: AppTheme.danger),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => _close(null),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}

class _CorrectOptionCheckbox extends StatelessWidget {
  final String label;
  final bool value;
  final VoidCallback onChanged;

  const _CorrectOptionCheckbox({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: (_) => onChanged(),
      title: Text(label),
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
      contentPadding: EdgeInsets.zero,
      activeColor: AppTheme.success,
      checkColor: Colors.white,
      side: const BorderSide(color: AppTheme.textDark, width: 2),
      checkboxShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _SetupCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;
  final Widget? footer;

  const _SetupCard({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.iconAccent(icon.codePoint);
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: color.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color.withValues(alpha: 0.16)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                AppIconBadge(
                  icon: icon,
                  color: color,
                  size: 40,
                  iconSize: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 12),
            child,
            if (footer != null) ...[
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerRight, child: footer!),
            ],
          ],
        ),
      ),
    );
  }
}

class _LoadingSection extends StatelessWidget {
  final String title;
  final IconData icon;

  const _LoadingSection({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return _SetupCard(
      title: title,
      icon: icon,
      child: const LinearProgressIndicator(minHeight: 3),
    );
  }
}

class _ErrorSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final String message;
  final VoidCallback onRetry;

  const _ErrorSection({
    required this.title,
    required this.icon,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return _SetupCard(
      title: title,
      icon: icon,
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                color: AppTheme.danger,
              ),
            ),
          ),
          IconButton(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'إعادة المحاولة',
          ),
        ],
      ),
    );
  }
}

class _EmptyLine extends StatelessWidget {
  final String message;

  const _EmptyLine({required this.message});

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: const TextStyle(
        fontFamily: 'Tajawal',
        color: AppTheme.textMuted,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final SetupState setup;
  final VoidCallback? onNext;

  const _BottomBar({required this.setup, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final details = [
      if (setup.selectedSubject != null) setup.selectedSubject!.name,
      if (setup.selectedSubjectPart != null) setup.selectedSubjectPart!.name,
      if (setup.selectedChapters.isNotEmpty)
        '${setup.selectedChapters.length} فصل',
      if (setup.selectedLessons.isNotEmpty)
        '${setup.selectedLessons.length} درس',
      if (setup.selectedQuestions.isNotEmpty)
        '${setup.selectedQuestions.length} سؤال',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              details.isEmpty ? 'أكمل اختيارات التحدي' : details.join(' • '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                color: AppTheme.textDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: onNext,
            style: ElevatedButton.styleFrom(minimumSize: const Size(120, 48)),
            child: const Text('إعداد الفرق'),
          ),
        ],
      ),
    );
  }
}

class _EditBottomBar extends StatelessWidget {
  final SetupState setup;
  final bool enabled;
  final bool isSaving;
  final VoidCallback onSave;

  const _EditBottomBar({
    required this.setup,
    required this.enabled,
    required this.isSaving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final details = [
      if (setup.selectedSubject != null) setup.selectedSubject!.name,
      if (setup.selectedSubjectPart != null) setup.selectedSubjectPart!.name,
      if (setup.selectedChapters.isNotEmpty)
        '${setup.selectedChapters.length} فصل',
      if (setup.selectedLessons.isNotEmpty)
        '${setup.selectedLessons.length} درس',
      if (setup.selectedQuestions.isNotEmpty)
        '${setup.selectedQuestions.length} سؤال',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              details.isEmpty ? 'أكمل اختيارات التحدي' : details.join(' • '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                color: AppTheme.textDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: enabled ? onSave : null,
            icon: isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.save_rounded),
            style: ElevatedButton.styleFrom(minimumSize: const Size(140, 48)),
            label: Text(isSaving ? 'جارٍ الحفظ...' : 'حفظ التعديل'),
          ),
        ],
      ),
    );
  }
}
