import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/setup_provider.dart';
import '../../../core/models/api_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import 'select_lessons_screen.dart';

class SelectChaptersScreen extends ConsumerWidget {
  const SelectChaptersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setup = ref.watch(setupProvider);
    final chaptersAsync = ref.watch(chaptersProvider(
        '${setup.selectedSubject!.id}:${setup.selectedSubjectPart!.id}'));

    return Scaffold(
      appBar: AppBar(
        title: Text('الفصول — ${setup.selectedSubjectPart!.name}'),
      ),
      body: Column(
        children: [
          const SetupProgressBar(
            currentStep: 4,
            totalSteps: 7,
            label: 'اختيار الفصول',
          ),
          Expanded(
            child: chaptersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => AppStateView(
                icon: Icons.cloud_off_rounded,
                title: 'تعذر تحميل الفصول',
                message: e.toString(),
              ),
              data: (chapters) => chapters.isEmpty
                  ? const AppStateView(
                      icon: Icons.view_list_rounded,
                      title: 'لا توجد فصول',
                      message:
                          'يمكنك إضافة فصول لهذا الجزء من إدارة المحتوى داخل التطبيق.',
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: chapters.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (ctx, i) {
                              final chapter = chapters[i];
                              final isSelected = setup.selectedChapters
                                  .any((c) => c.id == chapter.id);
                              return _ChapterCheckTile(
                                chapter: chapter,
                                index: i,
                                isSelected: isSelected,
                                onTap: () {
                                  ref
                                      .read(setupProvider.notifier)
                                      .toggleChapter(chapter);
                                },
                              );
                            },
                          ),
                        ),
                        _BottomBar(
                          selectedCount: setup.selectedChapters.length,
                          onNext: setup.selectedChapters.isEmpty
                              ? null
                              : () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const SelectLessonsScreen()),
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

class _ChapterCheckTile extends StatelessWidget {
  final Chapter chapter;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;
  const _ChapterCheckTile({
    required this.chapter,
    required this.index,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.iconAccent(index + 2);
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
              : Icons.view_module_rounded,
          color: color,
          filled: isSelected,
        ),
        title: Text(
          chapter.name,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? color : AppTheme.textDark,
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
                  ? 'اختر فصلاً واحداً على الأقل'
                  : 'تم اختيار $selectedCount فصل',
              style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14),
            ),
          ),
          ElevatedButton(
            onPressed: onNext,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(120, 48),
            ),
            child: const Text('التالي'),
          ),
        ],
      ),
    );
  }
}
