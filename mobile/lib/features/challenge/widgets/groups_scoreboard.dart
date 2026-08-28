import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/models/api_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../providers/challenge_provider.dart';

class GroupsScoreboard extends ConsumerWidget {
  final List<ChallengeGroup> groups;
  final bool compact;

  const GroupsScoreboard({
    super.key,
    required this.groups,
    required this.compact,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 8 : 12),
      color: AppTheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!compact)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(Icons.leaderboard_rounded,
                      color: AppTheme.accent, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'لوحة النقاط',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      color: AppTheme.textDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          compact
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: groups
                        .map((g) => _CompactGroupChip(group: g, ref: ref))
                        .toList(),
                  ),
                )
              : Column(
                  children: groups
                      .map((g) =>
                          _GroupCard(group: g, isCompact: false, ref: ref))
                      .toList(),
                ),
        ],
      ),
    );
  }
}

class _CompactGroupChip extends StatelessWidget {
  final ChallengeGroup group;
  final WidgetRef ref;
  const _CompactGroupChip({required this.group, required this.ref});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showManualScoreDialog(context, group, ref),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.accent.withValues(alpha: 0.22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              group.name,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                color: AppTheme.textMuted,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '${group.score}',
              style: const TextStyle(
                fontFamily: 'Tajawal',
                color: AppTheme.textDark,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final ChallengeGroup group;
  final bool isCompact;
  final WidgetRef ref;
  const _GroupCard(
      {required this.group, required this.isCompact, required this.ref});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showManualScoreDialog(context, group, ref),
      child: ArenaPanel(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        color: AppTheme.surface,
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.iconBorder(AppTheme.accent)),
              ),
              child: const Icon(Icons.groups_rounded,
                  color: AppTheme.accent, size: 21),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                group.name,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  color: AppTheme.textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${group.score}',
              style: const TextStyle(
                fontFamily: 'Tajawal',
                color: AppTheme.textDark,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              'نقطة',
              style: TextStyle(
                fontFamily: 'Tajawal',
                color: AppTheme.textMuted,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.edit_rounded, color: AppTheme.textMuted, size: 16),
          ],
        ),
      ),
    );
  }
}

void _showManualScoreDialog(
    BuildContext context, ChallengeGroup group, WidgetRef ref) {
  final pointsController = TextEditingController();
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('تعديل نقاط — ${group.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('النقاط الحالية: ${group.score}',
              style: const TextStyle(fontFamily: 'Tajawal', fontSize: 16)),
          const SizedBox(height: 16),
          TextField(
            controller: pointsController,
            keyboardType: TextInputType.number,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(
              labelText: 'عدد النقاط',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('إلغاء'),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            final points = int.tryParse(pointsController.text) ?? 0;
            if (points > 0) {
              try {
                await ref
                    .read(challengeProvider.notifier)
                    .manualSubtract(group.id, points);
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppError.message(
                          e,
                          fallback: 'تعذر خصم النقاط. حاول مجدداً.',
                        ),
                      ),
                    ),
                  );
                }
              }
            }
          },
          icon: const Icon(Icons.remove),
          label: const Text('خصم نقاط'),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            final points = int.tryParse(pointsController.text) ?? 0;
            if (points > 0) {
              try {
                await ref
                    .read(challengeProvider.notifier)
                    .manualAdd(group.id, points);
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppError.message(
                          e,
                          fallback: 'تعذر إضافة النقاط. حاول مجدداً.',
                        ),
                      ),
                    ),
                  );
                }
              }
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('إضافة نقاط'),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
        ),
      ],
    ),
  );
}
