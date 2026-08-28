import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/models/api_models.dart';
import '../../../core/providers/api_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
import '../../challenge/screens/saved_challenges_screen.dart';
import '../../packages/screens/packages_screen.dart';
import '../providers/setup_provider.dart';
import 'select_challenge_setup_screen.dart';

class SelectGradeScreen extends ConsumerStatefulWidget {
  const SelectGradeScreen({super.key});

  @override
  ConsumerState<SelectGradeScreen> createState() => _SelectGradeScreenState();
}

class _SelectGradeScreenState extends ConsumerState<SelectGradeScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void _openPackages() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PackagesScreen()),
    );
  }

  void _openChallenges() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SavedChallengesScreen()),
    );
  }

  void _selectGrade(Grade grade) {
    ref.read(setupProvider.notifier).selectGrade(grade);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SelectChallengeSetupScreen()),
    );
  }

  Future<void> _addGrade() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _NameInputDialog(
        title: 'إضافة صف',
        label: 'اسم الصف',
      ),
    );

    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return;

    try {
      await ref.read(apiClientProvider).createTeacherGrade({'name': trimmed});
      ref.invalidate(gradesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت إضافة الصف.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppError.message(e, fallback: 'تعذر إضافة الصف. حاول مجدداً.'),
          ),
        ),
      );
    }
  }

  Future<void> _deleteGrade(Grade grade) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الصف'),
        content: Text('هل تريد حذف الصف: ${grade.name}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(apiClientProvider).deleteTeacherGrade(grade.id);
      ref.invalidate(gradesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف الصف.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppError.message(e, fallback: 'تعذر حذف الصف. حاول مجدداً.'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradesAsync = ref.watch(gradesProvider);
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name.trim();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(gradesProvider);
          await ref.read(gradesProvider.future);
        },
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _HomeHeader(
                userName:
                    userName == null || userName.isEmpty ? 'معلمنا' : userName,
                onLogout: _logout,
              ),
            ),
            SliverToBoxAdapter(
              child: _QuickActions(
                onPackages: _openPackages,
                onChallenges: _openChallenges,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.school_rounded,
                      color: AppTheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'اختر الصف الدراسي لإنشاء ساحة المنافسة',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textDark,
                          ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'تحديث',
                      onPressed: () => ref.invalidate(gradesProvider),
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
              ),
            ),
            gradesAsync.when(
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: _ErrorWidget(
                  message: AppError.message(
                    error,
                    fallback: 'تعذر تحميل الصفوف. حاول مجدداً.',
                  ),
                  onRetry: () => ref.invalidate(gradesProvider),
                ),
              ),
              data: (grades) => _GradeGrid(
                grades: grades,
                onSelect: _selectGrade,
                onAdd: _addGrade,
                onDelete: _deleteGrade,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final String userName;
  final VoidCallback onLogout;

  const _HomeHeader({
    required this.userName,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 26),
      decoration: const BoxDecoration(
        color: AppTheme.primaryDark,
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const AppLogo(
                    size: 40,
                    padding: EdgeInsets.all(6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ساحة التنافس',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'لوحة المعلم',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          color: Colors.white.withValues(alpha: 0.76),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: onLogout,
                  tooltip: 'تسجيل الخروج',
                  icon: const Icon(Icons.logout_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.16),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              'مرحباً $userName',
              style: const TextStyle(
                fontFamily: 'Tajawal',
                color: Colors.white,
                fontSize: 31,
                height: 1.16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'اختر الصف، جهّز المحتوى، وابدأ جولة تفاعلية لطلابك داخل الحصة.',
              style: TextStyle(
                fontFamily: 'Tajawal',
                color: Colors.white.withValues(alpha: 0.86),
                fontSize: 16,
                height: 1.55,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
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

class _QuickActions extends StatelessWidget {
  final VoidCallback onPackages;
  final VoidCallback onChallenges;

  const _QuickActions({
    required this.onPackages,
    required this.onChallenges,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 680;
          final cards = [
            _ActionCard(
              icon: Icons.emoji_events_rounded,
              title: 'قائمة ساحة المنافسات',
              subtitle: 'أبدأ أو إستكمل تنافساً محفوظاً',
              color: AppTheme.primary,
              onTap: onChallenges,
            ),
            _ActionCard(
              icon: Icons.shopping_bag_outlined,
              title: 'شراء حزم الأسئلة',
              subtitle: 'استعرض الحزم المتاحة',
              color: AppTheme.cardClay,
              onTap: onPackages,
            ),
          ];

          if (isWide) {
            return Row(
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(child: cards[i]),
                ],
              ],
            );
          }

          return Column(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                cards[i],
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.22)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              AppIconBadge(icon: icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        color: AppTheme.textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppTheme.textMuted,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradeGrid extends StatelessWidget {
  final List<Grade> grades;
  final ValueChanged<Grade> onSelect;
  final VoidCallback onAdd;
  final ValueChanged<Grade> onDelete;

  const _GradeGrid({
    required this.grades,
    required this.onSelect,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossCount = width > 980
        ? 4
        : width > 620
            ? 3
            : 2;

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (ctx, index) {
            if (index >= grades.length) {
              return _AddGradeCard(
                index: index,
                onTap: onAdd,
              );
            }

            final grade = grades[index];
            return _GradeCard(
              grade: grade,
              index: index,
              onTap: () => onSelect(grade),
              onDelete: grade.isPrivate ? () => onDelete(grade) : null,
            );
          },
          childCount: grades.length + 1,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: width > 620 ? 1.65 : 1.18,
        ),
      ),
    );
  }
}

class _GradeCard extends StatelessWidget {
  final Grade grade;
  final int index;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _GradeCard({
    required this.grade,
    required this.index,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.categoryPalette(index);
    const icon = Icons.school_rounded;

    final accentColor = colors.last;

    return Material(
      color: colors.first,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.first,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: accentColor.withValues(alpha: 0.22)),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.iconSurface(accentColor),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: AppTheme.iconBorder(accentColor)),
                    ),
                    child: Icon(
                      icon,
                      color: accentColor,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  if (onDelete != null)
                    IconButton(
                      onPressed: onDelete,
                      tooltip: 'حذف الصف',
                      icon: const Icon(Icons.delete_outline_rounded),
                      color: AppTheme.danger,
                    ),
                  Icon(
                    Icons.arrow_back_rounded,
                    color: accentColor,
                    size: 22,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                grade.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  color: AppTheme.textDark,
                  fontSize: 18,
                  height: 1.25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'انتقل لاختيار المادة',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddGradeCard extends StatelessWidget {
  final int index;
  final VoidCallback onTap;

  const _AddGradeCard({
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.categoryPalette(index);
    final accentColor = colors.last;

    return Material(
      color: colors.first,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.first,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: accentColor.withValues(alpha: 0.22)),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.iconSurface(accentColor),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: AppTheme.iconBorder(accentColor)),
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      color: accentColor,
                      size: 28,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Text(
                'إضافة صف',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  color: AppTheme.textDark,
                  fontSize: 18,
                  height: 1.25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'اضغط لإضافة صف جديد',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorWidget({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return AppStateView(
      icon: Icons.wifi_off_rounded,
      title: 'تعذر تحميل البيانات',
      message: message,
      actionLabel: 'إعادة المحاولة',
      onAction: onRetry,
    );
  }
}
