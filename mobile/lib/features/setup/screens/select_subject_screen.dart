import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/setup_provider.dart';
import '../../../core/models/api_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import 'select_subject_part_screen.dart';

class SelectSubjectScreen extends ConsumerWidget {
  const SelectSubjectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setup = ref.watch(setupProvider);
    final subjectsAsync = ref.watch(subjectsProvider(setup.selectedGrade!.id));

    return Scaffold(
      appBar: AppBar(
        title: Text('المواد — ${setup.selectedGrade!.name}'),
      ),
      body: Column(
        children: [
          const SetupProgressBar(
            currentStep: 2,
            totalSteps: 7,
            label: 'اختيار المادة',
          ),
          Expanded(
            child: subjectsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => AppStateView(
                icon: Icons.cloud_off_rounded,
                title: 'تعذر تحميل المواد',
                message: e.toString(),
              ),
              data: (subjects) => subjects.isEmpty
                  ? const AppStateView(
                      icon: Icons.menu_book_rounded,
                      title: 'لا توجد مواد متاحة',
                      message: 'لا توجد مواد مرتبطة بهذا الصف حالياً.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: subjects.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) {
                        final subject = subjects[i];
                        return _SubjectTile(
                          subject: subject,
                          index: i,
                          onTap: () {
                            ref
                                .read(setupProvider.notifier)
                                .selectSubject(subject);
                            Navigator.of(ctx).push(
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const SelectSubjectPartScreen()),
                            );
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectTile extends StatelessWidget {
  final Subject subject;
  final int index;
  final VoidCallback onTap;
  const _SubjectTile({
    required this.subject,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.iconAccent(index + 1);
    final icons = [
      Icons.auto_stories_rounded,
      Icons.calculate_rounded,
      Icons.science_rounded,
      Icons.translate_rounded,
      Icons.public_rounded,
      Icons.eco_rounded,
    ];

    return Card(
      color: color.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color.withValues(alpha: 0.18)),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: AppIconBadge(
          icon: icons[index % icons.length],
          color: color,
        ),
        title: Text(
          subject.name,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: color,
        ),
        onTap: onTap,
      ),
    );
  }
}
