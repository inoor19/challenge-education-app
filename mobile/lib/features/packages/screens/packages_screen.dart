import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/api_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../providers/package_provider.dart';

class PackagesScreen extends ConsumerStatefulWidget {
  const PackagesScreen({super.key});

  @override
  ConsumerState<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends ConsumerState<PackagesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(packageProvider.notifier).loadPackages());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(packageProvider);

    ref.listen(packageProvider, (prev, next) {
      final message = next.error ?? next.successMessage;
      if (message != null && message != (prev?.error ?? prev?.successMessage)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor:
                next.error == null ? AppTheme.success : AppTheme.danger,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('حزم الأسئلة'),
        actions: [
          IconButton(
            onPressed: state.isPurchasing
                ? null
                : () => ref.read(packageProvider.notifier).restore(),
            icon: const Icon(Icons.restore_rounded),
            tooltip: 'استعادة المشتريات',
          ),
          IconButton(
            onPressed: state.isLoading
                ? null
                : () => ref.read(packageProvider.notifier).loadPackages(),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: state.isLoading
          ? const _LoadingPackages()
          : state.packages.isEmpty
              ? const _EmptyPackages()
              : Column(
                  children: [
                    const AppPageHeader(
                      icon: Icons.inventory_2_rounded,
                      title: 'حزم الأسئلة',
                      subtitle:
                          'استعرض تفاصيل الحزمة قبل الشراء وافتح محتوى جديداً للتحديات.',
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.packages.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final package = state.packages[index];
                          return _PackageCard(
                            package: package,
                            index: index,
                            onDetails: () => _showPackageDetails(package),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  void _showPackageDetails(QuestionPackage package) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final state = ref.watch(packageProvider);
            final freshPackage = state.packages.firstWhere(
              (item) => item.id == package.id,
              orElse: () => package,
            );

            return Directionality(
              textDirection: TextDirection.rtl,
              child: _PackageDetailsSheet(
                package: freshPackage,
                isPurchasing: state.isPurchasing,
                onBuy: () =>
                    ref.read(packageProvider.notifier).buy(freshPackage),
              ),
            );
          },
        );
      },
    );
  }
}

class _LoadingPackages extends StatelessWidget {
  const _LoadingPackages();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppTheme.primary),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final QuestionPackage package;
  final int index;
  final VoidCallback onDetails;

  const _PackageCard({
    required this.package,
    required this.index,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final owned = package.isOwned || package.isFree;
    final subtitle = _packageSummary(package);
    final color = owned ? AppTheme.success : AppTheme.iconAccent(index + 3);

    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onDetails,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.10),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppIconBadge(
                    icon: owned
                        ? Icons.verified_rounded
                        : Icons.shopping_bag_rounded,
                    color: color,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          package.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            color: AppTheme.textDark,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _StatusBadge(package: package),
                ],
              ),
              if (package.description?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Text(
                  package.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    color: AppTheme.textDark,
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _InfoPill(
                    icon: Icons.quiz_rounded,
                    label: '${package.questionsCount} سؤال',
                    color: color,
                  ),
                  TextButton.icon(
                    onPressed: onDetails,
                    icon: const Icon(Icons.visibility_rounded, size: 18),
                    label: const Text('استعراض التفاصيل'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PackageDetailsSheet extends StatelessWidget {
  final QuestionPackage package;
  final bool isPurchasing;
  final VoidCallback onBuy;

  const _PackageDetailsSheet({
    required this.package,
    required this.isPurchasing,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final owned = package.isOwned || package.isFree;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                18,
                20,
                20 + MediaQuery.paddingOf(context).bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.24),
                          ),
                        ),
                        child: const Icon(
                          Icons.inventory_2_rounded,
                          color: AppTheme.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              package.title,
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                color: AppTheme.textDark,
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _StatusBadge(package: package),
                                _InfoPill(
                                  icon: Icons.quiz_rounded,
                                  label: '${package.questionsCount} سؤال',
                                  color: AppTheme.cardTeal,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (package.description?.isNotEmpty == true) ...[
                    const SizedBox(height: 18),
                    _DetailPanel(
                      title: 'وصف الحزمة',
                      child: Text(
                        package.description!,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          color: AppTheme.textDark,
                          height: 1.6,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  _DetailPanel(
                    title: 'تفاصيل المحتوى',
                    child: Column(
                      children: [
                        _DetailRow(
                          icon: Icons.school_rounded,
                          label: 'الصف',
                          value: package.grade?.name ?? 'غير محدد',
                          color: AppTheme.cardGold,
                        ),
                        _DetailRow(
                          icon: Icons.menu_book_rounded,
                          label: 'المادة',
                          value: package.subject?.name ?? 'غير محدد',
                          color: AppTheme.cardTeal,
                        ),
                        _DetailRow(
                          icon: Icons.view_module_rounded,
                          label: 'الفصل',
                          value: package.chapter?.name ?? 'غير محدد',
                          color: AppTheme.cardClay,
                        ),
                        _DetailRow(
                          icon: Icons.article_rounded,
                          label: 'الدرس',
                          value: package.lesson?.name ?? 'غير محدد',
                          color: AppTheme.cardOlive,
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _DetailPanel(
                    title: 'الشراء',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.payments_rounded,
                              color: AppTheme.primary,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _priceLabel(package),
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  color: AppTheme.textDark,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (owned)
                          OutlinedButton.icon(
                            onPressed: null,
                            icon: const Icon(Icons.check_circle_rounded),
                            label: Text(package.isFree
                                ? 'الحزمة مجانية ومتاحة'
                                : 'الحزمة مشتراة ومتاحة'),
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: isPurchasing ? null : onBuy,
                            icon: isPurchasing
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.shopping_bag_rounded),
                            label: Text(isPurchasing
                                ? 'جارٍ إتمام الشراء'
                                : 'شراء الحزمة'),
                          ),
                      ],
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

class _DetailPanel extends StatelessWidget {
  final String title;
  final Widget child;

  const _DetailPanel({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              color: AppTheme.textDark,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool showDivider;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.iconSurface(color),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.iconBorder(color)),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      color: AppTheme.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (showDivider)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: AppTheme.border),
          ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoPill({
    required this.icon,
    required this.label,
    this.color = AppTheme.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              color: AppTheme.textDark,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final QuestionPackage package;
  const _StatusBadge({required this.package});

  @override
  Widget build(BuildContext context) {
    final label = package.isFree
        ? 'مجانية'
        : package.isOwned
            ? 'مشتراة'
            : 'مقفلة';
    final color = package.isFree || package.isOwned
        ? AppTheme.success
        : AppTheme.secondary;

    return StatusBadge(
      label: label,
      color: color,
      icon: package.isFree || package.isOwned
          ? Icons.check_circle_rounded
          : Icons.lock_rounded,
    );
  }
}

class _EmptyPackages extends StatelessWidget {
  const _EmptyPackages();

  @override
  Widget build(BuildContext context) {
    return const AppStateView(
      icon: Icons.inventory_2_rounded,
      title: 'لا توجد حزم متاحة حالياً',
      message: 'ستظهر هنا حزم الأسئلة عند توفرها لهذا الحساب.',
    );
  }
}

String _packageSummary(QuestionPackage package) {
  return [
    if (package.grade != null) package.grade!.name,
    if (package.subject != null) package.subject!.name,
    if (package.chapter != null) package.chapter!.name,
  ].join(' · ');
}

String _priceLabel(QuestionPackage package) {
  if (package.isFree) return 'مجانية';
  if (package.price == null || package.price!.isEmpty) return 'السعر غير محدد';
  return '${package.price} ر.س';
}
