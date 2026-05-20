import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/setup_provider.dart';
import '../../../core/models/api_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import 'setup_groups_screen.dart';

class SelectQuestionsScreen extends ConsumerStatefulWidget {
  const SelectQuestionsScreen({super.key});

  @override
  ConsumerState<SelectQuestionsScreen> createState() =>
      _SelectQuestionsScreenState();
}

class _SelectQuestionsScreenState extends ConsumerState<SelectQuestionsScreen> {
  String? _initializedLessonKey;

  @override
  Widget build(BuildContext context) {
    final setup = ref.watch(setupProvider);
    final lessonIds = setup.selectedLessons.map((l) => l.id).toList()..sort();
    final lessonKey = lessonIds.join(',');
    final questionsAsync = ref.watch(questionsProvider(lessonKey));
    final lessonNames = {
      for (final lesson in setup.selectedLessons) lesson.id: lesson.name,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('اختر الأسئلة'),
      ),
      body: Column(
        children: [
          const SetupProgressBar(
            currentStep: 6,
            totalSteps: 7,
            label: 'اختيار الأسئلة',
          ),
          Expanded(
            child: questionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => AppStateView(
                icon: Icons.cloud_off_rounded,
                title: 'تعذر تحميل الأسئلة',
                message: e.toString(),
              ),
              data: (questions) {
                if (_initializedLessonKey != lessonKey) {
                  _initializedLessonKey = lessonKey;
                  Future.microtask(() {
                    if (mounted) {
                      ref
                          .read(setupProvider.notifier)
                          .selectAllQuestions(questions);
                    }
                  });
                }

                if (questions.isEmpty) {
                  return const AppStateView(
                    icon: Icons.quiz_rounded,
                    title: 'لا توجد أسئلة',
                    message:
                        'اختر دروساً أخرى أو أضف أسئلة من إدارة المحتوى داخل التطبيق.',
                  );
                }

                final selectedQuestionIds =
                    setup.selectedQuestions.map((q) => q.id).toSet();
                final allSelected =
                    questions.every((q) => selectedQuestionIds.contains(q.id));

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Row(
                        children: [
                          StatusBadge(
                            label:
                                '${setup.selectedQuestions.length} سؤال محدد',
                            color: AppTheme.success,
                            icon: Icons.check_circle_rounded,
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () {
                              ref
                                  .read(setupProvider.notifier)
                                  .selectAllQuestions(
                                      allSelected ? [] : questions);
                            },
                            icon: Icon(
                              allSelected
                                  ? Icons.deselect_rounded
                                  : Icons.select_all_rounded,
                            ),
                            label: Text(
                              allSelected ? 'إلغاء تحديد الكل' : 'تحديد الكل',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: questions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final question = questions[i];
                          final isSelected =
                              selectedQuestionIds.contains(question.id);
                          return _QuestionCheckTile(
                            question: question,
                            lessonName: lessonNames[question.lessonId] ??
                                'درس غير معروف',
                            index: i,
                            isSelected: isSelected,
                            onTap: () => ref
                                .read(setupProvider.notifier)
                                .toggleQuestion(question),
                          );
                        },
                      ),
                    ),
                    _BottomBar(
                      selectedCount: setup.selectedQuestions.length,
                      onNext: setup.selectedQuestions.isEmpty
                          ? null
                          : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const SetupGroupsScreen(),
                                ),
                              ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCheckTile extends StatelessWidget {
  final Question question;
  final String lessonName;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuestionCheckTile({
    required this.question,
    required this.lessonName,
    required this.index,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        question.isHard ? AppTheme.danger : AppTheme.iconAccent(index);
    return Card(
      color: isSelected
          ? color.withValues(alpha: 0.15)
          : color.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? color : color.withValues(alpha: 0.14),
          width: 2,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: AppIconBadge(
          icon: isSelected ? Icons.check_circle_rounded : Icons.quiz_rounded,
          color: color,
          filled: isSelected,
        ),
        title: Text(
          question.questionText,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? color : AppTheme.textDark,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _InfoChip(
                icon: Icons.assignment_rounded,
                label: lessonName,
                color: AppTheme.primary,
              ),
              _InfoChip(
                icon: question.isHard
                    ? Icons.local_fire_department_rounded
                    : Icons.lightbulb_rounded,
                label: question.levelLabel,
                color: question.isHard ? AppTheme.danger : AppTheme.success,
              ),
            ],
          ),
        ),
        trailing: Checkbox(
          value: isSelected,
          onChanged: (_) => onTap(),
          activeColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Tajawal',
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback? onNext;

  const _BottomBar({required this.selectedCount, required this.onNext});

  @override
  Widget build(BuildContext context) {
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
              selectedCount == 0
                  ? 'اختر سؤالاً واحداً على الأقل'
                  : 'تم اختيار $selectedCount سؤال',
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
          ),
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
