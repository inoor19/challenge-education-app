import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_error.dart';
import '../providers/setup_provider.dart';
import '../../challenge/screens/saved_challenges_screen.dart';
import '../../challenge/providers/challenge_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';

class SetupGroupsScreen extends ConsumerStatefulWidget {
  const SetupGroupsScreen({super.key});

  @override
  ConsumerState<SetupGroupsScreen> createState() => _SetupGroupsScreenState();
}

class _SetupGroupsScreenState extends ConsumerState<SetupGroupsScreen> {
  final List<TextEditingController> _controllers = [];
  bool _isCreating = false;
  int _timerSeconds = 60;
  bool _timerEnabled = true;

  @override
  void initState() {
    super.initState();
    // Start with 2 groups
    _controllers.add(TextEditingController(text: 'المجموعة الأولى'));
    _controllers.add(TextEditingController(text: 'المجموعة الثانية'));
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addGroup() {
    setState(() {
      _controllers.add(
          TextEditingController(text: 'المجموعة ${_controllers.length + 1}'));
    });
  }

  Future<void> _removeGroup(int index) async {
    if (_controllers.length <= 2) return;
    final name = _controllers[index].text.trim();
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
      _controllers[index].dispose();
      _controllers.removeAt(index);
    });
  }

  Future<void> _startChallenge() async {
    final groupNames = _controllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (groupNames.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب إضافة مجموعتين على الأقل')),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final setup = ref.read(setupProvider);
      await ref.read(challengeProvider.notifier).createChallenge(
            setup: setup,
            groupNames: groupNames,
            timerSeconds: _timerSeconds,
            timerEnabled: _timerEnabled,
          );

      if (mounted) {
        ref.invalidate(savedChallengesProvider);
        final navigator = Navigator.of(context);
        navigator.popUntil((route) => route.isFirst);
        navigator.push(
          MaterialPageRoute(builder: (_) => const SavedChallengesScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppError.message(
                e,
                fallback: 'تعذر إنشاء المنافسة. حاول مجدداً.',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إعداد المجموعات')),
      body: Column(
        children: [
          const SetupProgressBar(
            currentStep: 7,
            totalSteps: 7,
            label: 'إعداد الفرق والمؤقت',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _TimerSettingsCard(
                  timerSeconds: _timerSeconds,
                  timerEnabled: _timerEnabled,
                  onTimerSecondsChanged: (v) =>
                      setState(() => _timerSeconds = v),
                  onTimerEnabledChanged: (v) =>
                      setState(() => _timerEnabled = v),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'المجموعات (${_controllers.length})',
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _addGroup,
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      label: const Text('إضافة مجموعة'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...List.generate(_controllers.length, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.iconAccent(i),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _controllers[i],
                            decoration: InputDecoration(
                              hintText: 'اسم المجموعة ${i + 1}',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        if (_controllers.length > 2) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                color: AppTheme.danger),
                            onPressed: () => _removeGroup(i),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(top: BorderSide(color: AppTheme.border)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isCreating ? null : _startChallenge,
                icon: _isCreating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow_rounded, size: 28),
                label: Text(
                  _isCreating ? 'جارٍ إنشاء المنافسة...' : 'إنشاء المنافسة',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerSettingsCard extends StatelessWidget {
  final int timerSeconds;
  final bool timerEnabled;
  final ValueChanged<int> onTimerSecondsChanged;
  final ValueChanged<bool> onTimerEnabledChanged;

  const _TimerSettingsCard({
    required this.timerSeconds,
    required this.timerEnabled,
    required this.onTimerSecondsChanged,
    required this.onTimerEnabledChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.cardGold.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppTheme.cardGold.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                AppIconBadge(
                  icon: Icons.timer_rounded,
                  color: AppTheme.cardGold,
                  size: 42,
                  iconSize: 23,
                ),
                SizedBox(width: 10),
                Text(
                  'إعدادات المؤقت',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.timer_rounded, color: AppTheme.cardGold),
                const SizedBox(width: 8),
                const Text('تفعيل المؤقت',
                    style: TextStyle(fontFamily: 'Tajawal')),
                const Spacer(),
                Switch(
                  value: timerEnabled,
                  onChanged: onTimerEnabledChanged,
                  activeColor: AppTheme.cardGold,
                ),
              ],
            ),
            if (timerEnabled) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, color: AppTheme.cardGold),
                  const SizedBox(width: 8),
                  Text(
                    'مدة المؤقت: $timerSeconds ثانية',
                    style: const TextStyle(fontFamily: 'Tajawal'),
                  ),
                ],
              ),
              Slider(
                value: timerSeconds.toDouble(),
                min: 10,
                max: 180,
                divisions: 17,
                label: '$timerSeconds ث',
                onChanged: (v) => onTimerSecondsChanged(v.toInt()),
                activeColor:
                    AppTheme.cardGold, // deprecated but still works on Slider
              ),
            ],
          ],
        ),
      ),
    );
  }
}
