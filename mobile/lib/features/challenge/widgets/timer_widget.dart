import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/challenge_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';

class TimerWidget extends ConsumerWidget {
  const TimerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(challengeProvider);
    final timerEnabled = state.session?.timerEnabled ?? true;

    if (!timerEnabled) {
      return const ArenaPanel(
        child: Center(
          child: Text(
            'المؤقت معطل',
            style: TextStyle(
              fontFamily: 'Tajawal',
              color: AppTheme.textMuted,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    final remaining = state.timerRemaining;
    final isRunning = state.timerRunning;
    final isWarning = remaining <= 10 && remaining > 0;
    final isExpired = remaining <= 0;

    final color = isExpired
        ? AppTheme.danger
        : isWarning
            ? AppTheme.warning
            : AppTheme.success;

    return ArenaPanel(
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.timer_rounded, color: AppTheme.success, size: 20),
              SizedBox(width: 8),
              Text(
                'المؤقت',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  color: AppTheme.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.92, end: isWarning ? 1.04 : 1),
            duration: const Duration(milliseconds: 350),
            builder: (context, scale, child) => Transform.scale(
              scale: scale,
              child: child,
            ),
            child: Text(
              _formatTime(remaining),
              style: TextStyle(
                fontFamily: 'Tajawal',
                color: color,
                fontSize: 38,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _TimerButton(
                icon: isRunning ? Icons.pause : Icons.play_arrow,
                label: isRunning ? 'إيقاف' : 'تشغيل',
                color: AppTheme.primary,
                onPressed: isRunning
                    ? () => ref.read(challengeProvider.notifier).pauseTimer()
                    : () => ref.read(challengeProvider.notifier).startTimer(),
              ),
              _TimerButton(
                icon: Icons.replay,
                label: 'إعادة',
                color: AppTheme.secondary,
                onPressed: () =>
                    ref.read(challengeProvider.notifier).resetAndStartTimer(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _TimerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;
  const _TimerButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Tajawal',
                color: color,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
