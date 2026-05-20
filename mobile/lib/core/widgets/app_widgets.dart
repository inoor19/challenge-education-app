import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ChallengeBackground extends StatelessWidget {
  final Widget child;
  final bool dark;
  final bool safeArea;
  final EdgeInsetsGeometry? padding;

  const ChallengeBackground({
    super.key,
    required this.child,
    this.dark = false,
    this.safeArea = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: dark ? AppTheme.background : AppTheme.background,
      child: safeArea
          ? SafeArea(
              child: Padding(
                padding: padding ?? EdgeInsets.zero,
                child: child,
              ),
            )
          : Padding(
              padding: padding ?? EdgeInsets.zero,
              child: child,
            ),
    );
  }
}

class AppPageHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const AppPageHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: AppTheme.primaryDark,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDark.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
            ),
            child: Icon(icon, color: AppTheme.accent, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class SetupProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final String label;

  const SetupProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final progress = currentStep / totalSteps;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
              const Spacer(),
              Text(
                '$currentStep من $totalSteps',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppTheme.surfaceAlt,
              valueColor: const AlwaysStoppedAnimation(AppTheme.cardGold),
            ),
          ),
        ],
      ),
    );
  }
}

class AppStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.accent.withValues(alpha: 0.24),
                  ),
                ),
                child: Icon(icon, color: AppTheme.accent, size: 34),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  color: AppTheme.textMuted,
                  height: 1.5,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.refresh),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Tajawal',
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class AppIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;
  final bool filled;

  const AppIconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 48,
    this.iconSize = 26,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: filled ? color : AppTheme.iconSurface(color),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: filled ? Colors.white24 : AppTheme.iconBorder(color),
        ),
      ),
      child: Icon(
        icon,
        color: filled ? Colors.white : color,
        size: iconSize,
      ),
    );
  }
}

class ArenaPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;

  const ArenaPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.color = AppTheme.arenaPanel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}
