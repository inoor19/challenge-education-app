import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/challenge_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';

class DiceWidget extends ConsumerWidget {
  final ChallengeArenaState arenaState;
  const DiceWidget({super.key, required this.arenaState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diceValue = arenaState.currentDiceValue;

    return ArenaPanel(
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.casino_rounded, color: AppTheme.accent, size: 20),
              SizedBox(width: 8),
              Text(
                'نقاط الحظ',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  color: AppTheme.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: child,
            ),
            child: Container(
              key: ValueKey(diceValue),
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accent.withValues(alpha: 0.28),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Center(
                child: arenaState.isDiceRolling
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      )
                    : Text(
                        diceValue?.toString() ?? '?',
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
            ),
          ),
          if (diceValue != null)
            Text(
              '$diceValue نقطة للسؤال السهل',
              style: const TextStyle(
                fontFamily: 'Tajawal',
                color: AppTheme.accent,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: arenaState.isDiceRolling
                  ? null
                  : () => ref.read(challengeProvider.notifier).rollDice(),
              icon: arenaState.isDiceRolling
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.casino_rounded),
              label: const Text('رمّ النرد'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
