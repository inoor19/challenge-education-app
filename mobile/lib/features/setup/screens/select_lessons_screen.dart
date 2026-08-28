import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_error.dart';
import '../providers/setup_provider.dart';
import '../../../core/models/api_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import 'select_questions_screen.dart';

class SelectLessonsScreen extends ConsumerWidget {
  const SelectLessonsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setup = ref.watch(setupProvider);
    final chapterIds = setup.selectedChapters.map((c) => c.id).toList()..sort();
    final lessonsAsync = ref.watch(lessonsProvider(chapterIds.join(',')));

    return Scaffold(
      appBar: AppBar(
        title: const Text('اختر الدروس'),
      ),
      body: Column(
        children: [
          const SetupProgressBar(
            currentStep: 5,
            totalSteps: 7,
            label: 'اختيار الدروس',
          ),
          Expanded(
            child: lessonsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => AppStateView(
                icon: Icons.cloud_off_rounded,
                title: 'تعذر تحميل الدروس',
                message: AppError.message(
                  e,
                  fallback: 'تعذر تحميل الدروس. حاول مجدداً.',
                ),
              ),
              data: (lessons) => lessons.isEmpty
                  ? const AppStateView(
                      icon: Icons.assignment_rounded,
                      title: 'لا توجد دروس',
                      message:
                          'اختر فصولاً أخرى أو أضف دروساً من صفحة إعداد المنافسة.',
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Row(
                            children: [
                              StatusBadge(
                                label: '${setup.selectedLessons.length} محدد',
                                color: AppTheme.success,
                                icon: Icons.check_circle_rounded,
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () {
                                  if (setup.selectedLessons.length ==
                                      lessons.length) {
                                    ref
                                        .read(setupProvider.notifier)
                                        .selectAllLessons([]);
                                  } else {
                                    ref
                                        .read(setupProvider.notifier)
                                        .selectAllLessons(lessons);
                                  }
                                },
                                icon: Icon(
                                  setup.selectedLessons.length == lessons.length
                                      ? Icons.deselect_rounded
                                      : Icons.select_all_rounded,
                                ),
                                label: Text(
                                  setup.selectedLessons.length == lessons.length
                                      ? 'إلغاء تحديد الكل'
                                      : 'تحديد الكل',
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: lessons.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (ctx, i) {
                              final lesson = lessons[i];
                              final isSelected = setup.selectedLessons
                                  .any((l) => l.id == lesson.id);
                              return _LessonCheckTile(
                                lesson: lesson,
                                index: i,
                                isSelected: isSelected,
                                onTap: () => ref
                                    .read(setupProvider.notifier)
                                    .toggleLesson(lesson),
                              );
                            },
                          ),
                        ),
                        _BottomBar(
                          selectedCount: setup.selectedLessons.length,
                          onNext: setup.selectedLessons.isEmpty
                              ? null
                              : () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const SelectQuestionsScreen()),
                                  ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonCheckTile extends StatelessWidget {
  final Lesson lesson;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;

  const _LessonCheckTile({
    required this.lesson,
    required this.index,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.iconAccent(index + 4);
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
          icon: isSelected
              ? Icons.check_circle_rounded
              : Icons.assignment_rounded,
          color: color,
          filled: isSelected,
        ),
        title: Text(
          lesson.name,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? color : AppTheme.textDark,
          ),
        ),
        trailing: Checkbox(
          value: isSelected,
          onChanged: (_) => onTap(),
          activeColor: color,
        ),
        onTap: onTap,
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
                  ? 'اختر درساً واحداً على الأقل'
                  : 'تم اختيار $selectedCount درس',
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
          ),
          ElevatedButton(
            onPressed: onNext,
            style: ElevatedButton.styleFrom(minimumSize: const Size(120, 48)),
            child: const Text('التالي'),
          ),
        ],
      ),
    );
  }
}
