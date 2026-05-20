import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/api_models.dart';
import '../../../core/providers/api_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';

class ManageContentScreen extends ConsumerStatefulWidget {
  const ManageContentScreen({super.key});

  @override
  ConsumerState<ManageContentScreen> createState() =>
      _ManageContentScreenState();
}

class _ManageContentScreenState extends ConsumerState<ManageContentScreen> {
  final _gradeName = TextEditingController();
  final _subjectName = TextEditingController();
  final _chapterName = TextEditingController();
  final _lessonName = TextEditingController();
  final _questionText = TextEditingController();
  final _optionA = TextEditingController();
  final _optionB = TextEditingController();
  final _optionC = TextEditingController();
  final _optionD = TextEditingController();
  final _correctAnswer = TextEditingController();
  final _explanation = TextEditingController();

  List<Grade> _grades = [];
  List<Subject> _subjects = [];
  List<SubjectPart> _parts = [];
  List<Chapter> _chapters = [];
  List<Lesson> _lessons = [];
  List<Question> _questions = [];

  int? _gradeId;
  int? _subjectId;
  int? _partId;
  int? _chapterId;
  int? _lessonId;
  String _questionType = 'multiple_choice';
  String _level = 'easy';
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  @override
  void dispose() {
    _gradeName.dispose();
    _subjectName.dispose();
    _chapterName.dispose();
    _lessonName.dispose();
    _questionText.dispose();
    _optionA.dispose();
    _optionB.dispose();
    _optionC.dispose();
    _optionD.dispose();
    _correctAnswer.dispose();
    _explanation.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    final api = ref.read(apiClientProvider);
    try {
      final grades =
          (await api.getTeacherGrades()).map((j) => Grade.fromJson(j)).toList();
      final subjects = (await api.getTeacherSubjects())
          .map((j) => Subject.fromJson(j))
          .toList();
      final chapters = (await api.getTeacherChapters())
          .map((j) => Chapter.fromJson(j))
          .toList();
      final lessons = (await api.getTeacherLessons())
          .map((j) => Lesson.fromJson(j))
          .toList();
      final questions = (await api.getTeacherQuestions())
          .map((j) => Question.fromJson(j))
          .toList();

      if (!mounted) return;
      setState(() {
        _grades = grades;
        _subjects = subjects;
        _chapters = chapters;
        _lessons = lessons;
        _questions = questions;
        _gradeId ??= grades.isNotEmpty ? grades.first.id : null;
        _subjectId ??= subjects.isNotEmpty ? subjects.first.id : null;
        _chapterId ??= chapters.isNotEmpty ? chapters.first.id : null;
        _lessonId ??= lessons.isNotEmpty ? lessons.first.id : null;
        _isLoading = false;
      });
      if (_subjectId != null) {
        await _loadParts(_subjectId!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('تعذر تحميل المحتوى: $e');
    }
  }

  Future<void> _loadParts(int subjectId) async {
    final api = ref.read(apiClientProvider);
    final parts = (await api.getSubjectParts(subjectId, includeEmpty: true))
        .map((j) => SubjectPart.fromJson(j))
        .toList();
    if (!mounted) return;
    setState(() {
      _parts = parts;
      _partId = parts.isNotEmpty ? parts.first.id : null;
    });
  }

  Future<void> _save(Future<void> Function() action) async {
    setState(() => _isSaving = true);
    try {
      await action();
      await _loadAll();
      _showMessage('تم الحفظ بنجاح.');
    } catch (e) {
      _showMessage('تعذر الحفظ: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subjectChapters =
        _chapters.where((chapter) => chapter.subjectId == _subjectId).toList();
    final chapterLessons =
        _lessons.where((lesson) => lesson.chapterId == _chapterId).toList();
    final lessonQuestions =
        _questions.where((question) => question.lessonId == _lessonId).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المحتوى'),
        actions: [
          IconButton(
            onPressed: _loadAll,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const AppPageHeader(
                  icon: Icons.create_new_folder_rounded,
                  title: 'محتواك التعليمي',
                  subtitle:
                      'أضف الصفوف والمواد والفصول والدروس والأسئلة لاستخدامك داخل التحديات.',
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'إضافة صف',
                  icon: Icons.school_rounded,
                  children: [
                    _TextField(controller: _gradeName, label: 'اسم الصف'),
                    _SaveButton(
                      isSaving: _isSaving,
                      label: 'حفظ الصف',
                      onPressed: () => _save(() async {
                        if (_gradeName.text.trim().isEmpty) return;
                        await ref.read(apiClientProvider).createTeacherGrade({
                          'name': _gradeName.text.trim(),
                        });
                        _gradeName.clear();
                      }),
                    ),
                  ],
                ),
                _SectionCard(
                  title: 'إضافة مادة',
                  icon: Icons.menu_book_rounded,
                  children: [
                    _Dropdown<int>(
                      value: _gradeId,
                      label: 'الصف',
                      items: _grades
                          .map((grade) => DropdownMenuItem(
                              value: grade.id, child: Text(grade.name)))
                          .toList(),
                      onChanged: (value) => setState(() => _gradeId = value),
                    ),
                    _TextField(controller: _subjectName, label: 'اسم المادة'),
                    _SaveButton(
                      isSaving: _isSaving,
                      label: 'حفظ المادة',
                      onPressed: _gradeId == null
                          ? null
                          : () => _save(() async {
                                if (_subjectName.text.trim().isEmpty) return;
                                await ref
                                    .read(apiClientProvider)
                                    .createTeacherSubject({
                                  'grade_id': _gradeId,
                                  'name': _subjectName.text.trim(),
                                });
                                _subjectName.clear();
                              }),
                    ),
                  ],
                ),
                _SectionCard(
                  title: 'إضافة فصل',
                  icon: Icons.layers_rounded,
                  children: [
                    _Dropdown<int>(
                      value: _subjectId,
                      label: 'المادة',
                      items: _subjects
                          .map((subject) => DropdownMenuItem(
                              value: subject.id, child: Text(subject.name)))
                          .toList(),
                      onChanged: (value) async {
                        if (value == null) return;
                        setState(() => _subjectId = value);
                        await _loadParts(value);
                      },
                    ),
                    _Dropdown<int>(
                      value: _partId,
                      label: 'جزء المادة',
                      items: _parts
                          .map((part) => DropdownMenuItem(
                              value: part.id, child: Text(part.name)))
                          .toList(),
                      onChanged: (value) => setState(() => _partId = value),
                    ),
                    _TextField(controller: _chapterName, label: 'اسم الفصل'),
                    _SaveButton(
                      isSaving: _isSaving,
                      label: 'حفظ الفصل',
                      onPressed: _partId == null
                          ? null
                          : () => _save(() async {
                                if (_chapterName.text.trim().isEmpty) return;
                                await ref
                                    .read(apiClientProvider)
                                    .createTeacherChapter({
                                  'subject_part_id': _partId,
                                  'name': _chapterName.text.trim(),
                                });
                                _chapterName.clear();
                              }),
                    ),
                    _CountLine(
                        label: 'الفصول الحالية', count: subjectChapters.length),
                  ],
                ),
                _SectionCard(
                  title: 'إضافة درس',
                  icon: Icons.article_rounded,
                  children: [
                    _Dropdown<int>(
                      value: _chapterId,
                      label: 'الفصل',
                      items: _chapters
                          .map((chapter) => DropdownMenuItem(
                              value: chapter.id, child: Text(chapter.name)))
                          .toList(),
                      onChanged: (value) => setState(() => _chapterId = value),
                    ),
                    _TextField(controller: _lessonName, label: 'اسم الدرس'),
                    _SaveButton(
                      isSaving: _isSaving,
                      label: 'حفظ الدرس',
                      onPressed: _chapterId == null
                          ? null
                          : () => _save(() async {
                                if (_lessonName.text.trim().isEmpty) return;
                                await ref
                                    .read(apiClientProvider)
                                    .createTeacherLesson({
                                  'chapter_id': _chapterId,
                                  'name': _lessonName.text.trim(),
                                });
                                _lessonName.clear();
                              }),
                    ),
                    _CountLine(
                        label: 'دروس الفصل المحدد',
                        count: chapterLessons.length),
                  ],
                ),
                _SectionCard(
                  title: 'إضافة سؤال',
                  icon: Icons.quiz_rounded,
                  children: [
                    _Dropdown<int>(
                      value: _lessonId,
                      label: 'الدرس',
                      items: _lessons
                          .map((lesson) => DropdownMenuItem(
                              value: lesson.id, child: Text(lesson.name)))
                          .toList(),
                      onChanged: (value) => setState(() => _lessonId = value),
                    ),
                    _TextField(
                      controller: _questionText,
                      label: 'نص السؤال',
                      maxLines: 3,
                    ),
                    _Dropdown<String>(
                      value: _questionType,
                      label: 'نوع السؤال',
                      items: const [
                        DropdownMenuItem(
                            value: 'multiple_choice',
                            child: Text('اختيار من متعدد')),
                        DropdownMenuItem(
                            value: 'true_false', child: Text('صح أو خطأ')),
                        DropdownMenuItem(value: 'text', child: Text('نصي')),
                      ],
                      onChanged: (value) => setState(
                          () => _questionType = value ?? _questionType),
                    ),
                    _Dropdown<String>(
                      value: _level,
                      label: 'المستوى',
                      items: const [
                        DropdownMenuItem(value: 'easy', child: Text('سهل')),
                        DropdownMenuItem(value: 'hard', child: Text('صعب')),
                      ],
                      onChanged: (value) =>
                          setState(() => _level = value ?? _level),
                    ),
                    if (_questionType == 'multiple_choice') ...[
                      _TextField(controller: _optionA, label: 'الاختيار الأول'),
                      _TextField(
                          controller: _optionB, label: 'الاختيار الثاني'),
                      _TextField(
                          controller: _optionC, label: 'الاختيار الثالث'),
                      _TextField(
                          controller: _optionD, label: 'الاختيار الرابع'),
                    ],
                    _TextField(
                      controller: _correctAnswer,
                      label: 'الإجابة الصحيحة',
                    ),
                    _TextField(
                      controller: _explanation,
                      label: 'الشرح أو الملاحظة',
                      maxLines: 2,
                    ),
                    _SaveButton(
                      isSaving: _isSaving,
                      label: 'حفظ السؤال',
                      onPressed: _lessonId == null
                          ? null
                          : () => _save(() async {
                                if (_questionText.text.trim().isEmpty ||
                                    _correctAnswer.text.trim().isEmpty) {
                                  return;
                                }
                                await ref
                                    .read(apiClientProvider)
                                    .createTeacherQuestion({
                                  'lesson_id': _lessonId,
                                  'question_text': _questionText.text.trim(),
                                  'question_type': _questionType,
                                  'level': _level,
                                  'option_a': _optionA.text.trim().isEmpty
                                      ? null
                                      : _optionA.text.trim(),
                                  'option_b': _optionB.text.trim().isEmpty
                                      ? null
                                      : _optionB.text.trim(),
                                  'option_c': _optionC.text.trim().isEmpty
                                      ? null
                                      : _optionC.text.trim(),
                                  'option_d': _optionD.text.trim().isEmpty
                                      ? null
                                      : _optionD.text.trim(),
                                  'correct_answer': _correctAnswer.text.trim(),
                                  'explanation':
                                      _explanation.text.trim().isEmpty
                                          ? null
                                          : _explanation.text.trim(),
                                });
                                _questionText.clear();
                                _optionA.clear();
                                _optionB.clear();
                                _optionC.clear();
                                _optionD.clear();
                                _correctAnswer.clear();
                                _explanation.clear();
                              }),
                    ),
                    _CountLine(
                        label: 'أسئلة الدرس المحدد',
                        count: lessonQuestions.length),
                  ],
                ),
              ],
            ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
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
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;

  const _TextField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  final T? value;
  final String label;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _Dropdown({
    required this.value,
    required this.label,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final validValue = items.any((item) => item.value == value) ? value : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<T>(
        initialValue: validValue,
        items: items,
        onChanged: items.isEmpty ? null : onChanged,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool isSaving;
  final String label;
  final VoidCallback? onPressed;

  const _SaveButton({
    required this.isSaving,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ElevatedButton.icon(
        onPressed: isSaving ? null : onPressed,
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
        label: Text(label),
      ),
    );
  }
}

class _CountLine extends StatelessWidget {
  final String label;
  final int count;

  const _CountLine({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: StatusBadge(
        label: '$label: $count',
        color: AppTheme.cardTeal,
        icon: Icons.check_circle_outline_rounded,
      ),
    );
  }
}
