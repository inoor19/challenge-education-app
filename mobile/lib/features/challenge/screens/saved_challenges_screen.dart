import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/models/api_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../providers/challenge_provider.dart';
import 'challenge_arena_screen.dart';
import '../../setup/screens/select_challenge_setup_screen.dart';
import '../../setup/screens/select_grade_screen.dart';

class SavedChallengesScreen extends ConsumerWidget {
  const SavedChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengesAsync = ref.watch(savedChallengesProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const SelectGradeScreen()),
            (route) => false,
          ),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'رجوع',
        ),
        title: const Text('قائمة المنافسات'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(savedChallengesProvider),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: challengesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppStateView(
          icon: Icons.cloud_off_rounded,
          title: 'تعذر تحميل التحديات',
          message: AppError.message(
            e,
            fallback: 'تعذر تحميل التحديات المحفوظة. حاول مجدداً.',
          ),
          actionLabel: 'إعادة المحاولة',
          onAction: () => ref.invalidate(savedChallengesProvider),
        ),
        data: (challenges) => challenges.isEmpty
            ? const AppStateView(
                icon: Icons.history_rounded,
                title: 'لا توجد تحديات محفوظة',
                message: 'بعد إنشاء تحدي جديد سيظهر هنا ويمكنك الرجوع إليه.',
              )
            : RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(savedChallengesProvider);
                  await ref.read(savedChallengesProvider.future);
                },
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: challenges.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _ChallengeCard(
                    challenge: challenges[index],
                    index: index,
                    onOpen: () =>
                        _openChallenge(context, ref, challenges[index]),
                    onEdit: () =>
                        _editChallenge(context, ref, challenges[index]),
                    onEditQuestions: () => _editChallengeQuestions(
                        context, ref, challenges[index]),
                    onRestart: () =>
                        _restartChallenge(context, ref, challenges[index]),
                    onDelete: () =>
                        _deleteChallenge(context, ref, challenges[index]),
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _openChallenge(
    BuildContext context,
    WidgetRef ref,
    ChallengeSession challenge,
  ) async {
    try {
      await ref.read(challengeProvider.notifier).loadChallenge(challenge.id);
      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ChallengeArenaScreen()),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppError.message(e, fallback: 'تعذر فتح التحدي. حاول مجدداً.'),
            ),
          ),
        );
      }
    }
  }

  Future<void> _editChallenge(
    BuildContext context,
    WidgetRef ref,
    ChallengeSession challenge,
  ) async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => _EditChallengeDialog(challenge: challenge),
    );

    if (changed == true) {
      ref.invalidate(savedChallengesProvider);
    }
  }

  Future<void> _restartChallenge(
    BuildContext context,
    WidgetRef ref,
    ChallengeSession challenge,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إعادة التنافس'),
        content: const Text(
          'سيتم إعادة نفس المنافسة للّعب من جديد مع الحفاظ على نقاط المجموعات الحالية.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('إعادة'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(challengeProvider.notifier).restartChallenge(challenge.id);
      ref.invalidate(savedChallengesProvider);
      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ChallengeArenaScreen()),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppError.message(
                e,
                fallback: 'تعذر إعادة التنافس. حاول مجدداً.',
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> _editChallengeQuestions(
    BuildContext context,
    WidgetRef ref,
    ChallengeSession challenge,
  ) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SelectChallengeSetupScreen(editChallenge: challenge),
      ),
    );

    if (changed == true) {
      ref.invalidate(savedChallengesProvider);
    }
  }

  Future<void> _deleteChallenge(
    BuildContext context,
    WidgetRef ref,
    ChallengeSession challenge,
  ) async {
    final title = _challengeTitle(challenge);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المنافسة'),
        content: Text('هل تريد حذف المنافسة: $title؟ لا يمكن التراجع عن ذلك.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(challengeProvider.notifier).deleteChallenge(challenge.id);
      ref.invalidate(savedChallengesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف المنافسة.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppError.message(
                e,
                fallback: 'تعذر حذف المنافسة. حاول مجدداً.',
              ),
            ),
          ),
        );
      }
    }
  }

  String _challengeTitle(ChallengeSession challenge) {
    final subject = challenge.subject?.name ?? 'منافسة محفوظة';
    final part = challenge.subjectPart?.name;
    return part == null ? subject : '$subject - $part';
  }
}

class _ChallengeCard extends StatelessWidget {
  final ChallengeSession challenge;
  final int index;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onEditQuestions;
  final VoidCallback onRestart;
  final VoidCallback onDelete;

  const _ChallengeCard({
    required this.challenge,
    required this.index,
    required this.onOpen,
    required this.onEdit,
    required this.onEditQuestions,
    required this.onRestart,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.iconAccent(index);
    final usedQuestions = challenge.questions.where((q) => q.isUsed).length;
    final totalQuestions = challenge.questions.length;
    final totalScore =
        challenge.groups.fold<int>(0, (sum, group) => sum + group.score);
    final topScore = challenge.groups.isEmpty
        ? 0
        : challenge.groups
            .map((group) => group.score)
            .reduce((a, b) => a > b ? a : b);

    return Card(
      color: color.withValues(alpha: 0.07),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color.withValues(alpha: 0.18)),
      ),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppIconBadge(icon: Icons.emoji_events_rounded, color: color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            color: AppTheme.textDark,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusPill(status: challenge.status),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusBadge(
                    label: '$usedQuestions / $totalQuestions سؤال',
                    color: AppTheme.primary,
                    icon: Icons.quiz_rounded,
                  ),
                  StatusBadge(
                    label: '${challenge.groups.length} مجموعة',
                    color: AppTheme.cardClay,
                    icon: Icons.groups_rounded,
                  ),
                  StatusBadge(
                    label: 'أعلى $topScore',
                    color: AppTheme.success,
                    icon: Icons.trending_up_rounded,
                  ),
                  StatusBadge(
                    label: 'الإجمالي $totalScore',
                    color: AppTheme.cardGold,
                    icon: Icons.stars_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                textDirection: TextDirection.ltr,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _DeleteChallengeIcon(onPressed: onDelete),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          _ActionButton(
                            onPressed: onEdit,
                            icon: Icons.edit_rounded,
                            label: 'تعديل',
                            outlined: true,
                          ),
                          _ActionButton(
                            onPressed: onEditQuestions,
                            icon: Icons.quiz_rounded,
                            label: 'تعديل الأسئلة',
                            outlined: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  if (challenge.status == 'completed')
                    _ActionButton(
                      onPressed: onRestart,
                      icon: Icons.replay_rounded,
                      label: 'إعادة التنافس',
                      outlined: true,
                    ),
                  _ActionButton(
                    onPressed: onOpen,
                    icon: Icons.play_arrow_rounded,
                    label: 'دخول',
                    outlined: false,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _title {
    final subject = challenge.subject?.name ?? 'تحدي محفوظ';
    final part = challenge.subjectPart?.name;
    return part == null ? subject : '$subject - $part';
  }

  String get _subtitle {
    final grade = challenge.grade?.name;
    final section = challenge.gradeSection?.trim();
    final gradeLabel = grade == null
        ? null
        : section == null || section.isEmpty
            ? grade
            : '$grade ($section)';
    final started = challenge.startedAt;
    final pieces = [
      if (gradeLabel != null) gradeLabel,
      if (started != null) started.split('T').first,
    ];
    return pieces.isEmpty ? 'تحدي محفوظ' : pieces.join(' • ');
  }
}

class _DeleteChallengeIcon extends StatelessWidget {
  final VoidCallback onPressed;

  const _DeleteChallengeIcon({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'حذف المنافسة',
      child: IconButton(
        onPressed: onPressed,
        icon: const Icon(Icons.delete_outline_rounded),
        color: AppTheme.danger,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints.tightFor(width: 34, height: 34),
        style: IconButton.styleFrom(
          backgroundColor: AppTheme.danger.withValues(alpha: 0.08),
          foregroundColor: AppTheme.danger,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final bool outlined;

  const _ActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.outlined,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 6),
        Text(label),
      ],
    );

    return SizedBox(
      height: 42,
      child: outlined
          ? OutlinedButton(onPressed: onPressed, child: child)
          : ElevatedButton(onPressed: onPressed, child: child),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final isCompleted = status == 'completed';
    return StatusBadge(
      label: isCompleted ? 'مكتمل' : 'نشط',
      color: isCompleted ? AppTheme.cardGold : AppTheme.success,
      icon: isCompleted ? Icons.flag_rounded : Icons.play_circle_rounded,
    );
  }
}

class _EditChallengeDialog extends ConsumerStatefulWidget {
  final ChallengeSession challenge;

  const _EditChallengeDialog({required this.challenge});

  @override
  ConsumerState<_EditChallengeDialog> createState() =>
      _EditChallengeDialogState();
}

class _EditChallengeDialogState extends ConsumerState<_EditChallengeDialog> {
  final List<_GroupDraft> _groups = [];
  bool _isSaving = false;
  bool _timerEnabled = true;
  late int _timerSeconds;
  String? _error;

  @override
  void initState() {
    super.initState();
    _timerEnabled = widget.challenge.timerEnabled;
    _timerSeconds = widget.challenge.timerSeconds;
    for (final group in widget.challenge.groups) {
      _groups.add(_GroupDraft(
        id: group.id,
        controller: TextEditingController(text: group.name),
      ));
    }
    while (_groups.length < 2) {
      _addGroup();
    }
  }

  @override
  void dispose() {
    for (final group in _groups) {
      group.controller.dispose();
    }
    super.dispose();
  }

  void _addGroup() {
    _groups.add(_GroupDraft(
      controller: TextEditingController(text: 'المجموعة ${_groups.length + 1}'),
    ));
  }

  Future<void> _removeGroup(int index) async {
    if (_groups.length <= 2) return;
    final name = _groups[index].controller.text.trim();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المجموعة'),
        content: Text(
          name.isEmpty
              ? 'هل تريد حذف هذه المجموعة؟'
              : 'هل تريد حذف المجموعة: $name؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _groups[index].controller.dispose();
      _groups.removeAt(index);
    });
  }

  Future<void> _save() async {
    final payload = <Map<String, dynamic>>[];
    for (var i = 0; i < _groups.length; i++) {
      final name = _groups[i].controller.text.trim();
      if (name.isEmpty) {
        setState(() => _error = 'أسماء المجموعات مطلوبة.');
        return;
      }
      payload.add({
        if (_groups[i].id != null) 'id': _groups[i].id,
        'name': name,
        'sort_order': i,
      });
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await ref.read(challengeProvider.notifier).updateChallengeSettings(
            challengeId: widget.challenge.id,
            timerSeconds: _timerSeconds,
            timerEnabled: _timerEnabled,
            groups: payload,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _error = AppError.message(
            e,
            fallback: 'تعذر حفظ التعديل. حاول مجدداً.',
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تعديل التحدي'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              value: _timerEnabled,
              onChanged: (value) => setState(() => _timerEnabled = value),
              title: const Text('تفعيل المؤقت'),
            ),
            if (_timerEnabled) ...[
              Text('مدة المؤقت: $_timerSeconds ثانية'),
              Slider(
                value: _timerSeconds.toDouble(),
                min: 10,
                max: 300,
                divisions: 29,
                label: '$_timerSeconds ث',
                onChanged: (value) =>
                    setState(() => _timerSeconds = value.toInt()),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'المجموعات',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(_addGroup),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('إضافة'),
                ),
              ],
            ),
            for (var i = 0; i < _groups.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _groups[i].controller,
                        decoration: InputDecoration(
                          labelText: 'المجموعة ${i + 1}',
                        ),
                      ),
                    ),
                    if (_groups.length > 2)
                      IconButton(
                        onPressed: () => _removeGroup(i),
                        icon: const Icon(Icons.delete_outline_rounded),
                        color: AppTheme.danger,
                      ),
                  ],
                ),
              ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: AppTheme.danger),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: Text(_isSaving ? 'جارٍ الحفظ...' : 'حفظ'),
        ),
      ],
    );
  }
}

class _GroupDraft {
  final int? id;
  final TextEditingController controller;

  _GroupDraft({this.id, required this.controller});
}
