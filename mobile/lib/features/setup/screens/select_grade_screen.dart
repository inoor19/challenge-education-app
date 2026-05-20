import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/api_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
import '../../packages/screens/packages_screen.dart';
import '../../teacher_content/screens/manage_content_screen.dart';
import '../providers/setup_provider.dart';
import 'select_subject_screen.dart';

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

  void _openContent() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ManageContentScreen()),
    );
  }

  void _openPackages() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PackagesScreen()),
    );
  }

  void _selectGrade(Grade grade) {
    ref.read(setupProvider.notifier).selectGrade(grade);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SelectSubjectScreen()),
    );
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
                onContent: _openContent,
                onPackages: _openPackages,
              ),
            ),
            const SliverToBoxAdapter(
              child: _SetupStepStrip(),
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
                      'اختر الصف الدراسي',
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
                  message: error.toString(),
                  onRetry: () => ref.invalidate(gradesProvider),
                ),
              ),
              data: (grades) => grades.isEmpty
                  ? const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _NoAvailableContent(),
                    )
                  : _GradeGrid(
                      grades: grades,
                      onSelect: _selectGrade,
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
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: AppTheme.accent,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ساحة التحدي التعليمي',
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
              'اختر الصف، جهّز المحتوى، وابدأ جولة تفاعلية لفريقك داخل الحصة.',
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

class _QuickActions extends StatelessWidget {
  final VoidCallback onContent;
  final VoidCallback onPackages;

  const _QuickActions({
    required this.onContent,
    required this.onPackages,
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
              icon: Icons.create_new_folder_outlined,
              title: 'إدارة المحتوى',
              subtitle: 'أضف صفوفاً وأسئلة خاصة',
              color: AppTheme.cardGold,
              onTap: onContent,
            ),
            _ActionCard(
              icon: Icons.shopping_bag_outlined,
              title: 'حزم الأسئلة',
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

class _SetupStepStrip extends StatelessWidget {
  const _SetupStepStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardMint.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.cardMint.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          const StatusBadge(
            label: '1 من 7',
            color: AppTheme.primary,
            icon: Icons.flag_rounded,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'خطوة البداية',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: const LinearProgressIndicator(
                    value: 1 / 7,
                    minHeight: 7,
                    backgroundColor: Colors.white,
                    valueColor: AlwaysStoppedAnimation(AppTheme.cardGold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GradeGrid extends StatelessWidget {
  final List<Grade> grades;
  final ValueChanged<Grade> onSelect;

  const _GradeGrid({required this.grades, required this.onSelect});

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
            final grade = grades[index];
            return _GradeCard(
              grade: grade,
              index: index,
              onTap: () => onSelect(grade),
            );
          },
          childCount: grades.length,
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

  const _GradeCard({
    required this.grade,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.categoryPalette(index);
    final icon = [
      Icons.school_rounded,
      Icons.auto_stories_rounded,
      Icons.science_rounded,
      Icons.explore_rounded,
      Icons.emoji_objects_rounded,
      Icons.local_library_rounded,
    ][index % 6];

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

class _NoAvailableContent extends StatelessWidget {
  const _NoAvailableContent();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 56, color: AppTheme.textMuted),
            const SizedBox(height: 12),
            const Text(
              'لا توجد أسئلة متاحة لهذا الحساب',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const ManageContentScreen()),
                );
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('إضافة محتوى يدوي'),
            ),
          ],
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
