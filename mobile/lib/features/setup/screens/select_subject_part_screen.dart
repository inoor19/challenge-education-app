import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/setup_provider.dart';
import '../../../core/models/api_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import 'select_chapters_screen.dart';

class SelectSubjectPartScreen extends ConsumerWidget {
  const SelectSubjectPartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setup = ref.watch(setupProvider);
    final partsAsync =
        ref.watch(subjectPartsProvider(setup.selectedSubject!.id));

    return Scaffold(
      appBar: AppBar(
        title: Text('الأجزاء — ${setup.selectedSubject!.name}'),
      ),
      body: Column(
        children: [
          const SetupProgressBar(
            currentStep: 3,
            totalSteps: 7,
            label: 'اختيار جزء المادة',
          ),
          Expanded(
            child: partsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => AppStateView(
                icon: Icons.cloud_off_rounded,
                title: 'تعذر تحميل أجزاء المادة',
                message: e.toString(),
              ),
              data: (parts) => parts.isEmpty
                  ? const AppStateView(
                      icon: Icons.library_books_rounded,
                      title: 'لا توجد أسئلة في أجزاء هذه المادة',
                      message:
                          'يمكنك إضافة فصول ودروس وأسئلة من إدارة المحتوى داخل التطبيق.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: parts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) {
                        final part = parts[i];
                        return _SubjectPartTile(
                          part: part,
                          index: i,
                          onTap: () {
                            ref
                                .read(setupProvider.notifier)
                                .selectSubjectPart(part);
                            Navigator.of(ctx).push(
                              MaterialPageRoute(
                                builder: (_) => const SelectChaptersScreen(),
                              ),
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

class _SubjectPartTile extends StatelessWidget {
  final SubjectPart part;
  final int index;
  final VoidCallback onTap;

  const _SubjectPartTile({
    required this.part,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.iconAccent(index + 3);
    return Card(
      color: color.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color.withValues(alpha: 0.18)),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: AppIconBadge(icon: Icons.layers_rounded, color: color),
        title: Text(
          part.name,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 18,
            fontWeight: FontWeight.w700,
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
