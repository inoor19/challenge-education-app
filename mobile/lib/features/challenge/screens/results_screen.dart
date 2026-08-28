import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/models/api_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../providers/challenge_provider.dart';
import 'challenge_arena_screen.dart';
import 'saved_challenges_screen.dart';

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(challengeProvider);
    final sorted = List<ChallengeGroup>.of(state.groups)
      ..sort((a, b) => b.score.compareTo(a.score));
    final winner = sorted.isEmpty ? null : sorted.first;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: ChallengeBackground(
        dark: true,
        safeArea: false,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isTablet = constraints.maxWidth > 720;
              return Column(
                children: [
                  _ResultsHeader(
                    subjectTitle: _subjectTitle(state.session),
                    winner: winner,
                    isTablet: isTablet,
                  ),
                  Expanded(
                    child: sorted.isEmpty
                        ? const _EmptyResults()
                        : _ResultsList(groups: sorted, isTablet: isTablet),
                  ),
                  _ResultsActions(
                    canRestart: state.session != null,
                    onRestart: () =>
                        _restartChallenge(context, ref, state.session),
                    onBackToChallenges: () => _goToChallenges(context, ref),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _subjectTitle(ChallengeSession? session) {
    final parts = [
      if (session?.subject != null) session!.subject!.name,
      if (session?.subjectPart != null) session!.subjectPart!.name,
      if (session?.grade != null) session!.grade!.name,
    ];
    return parts.isEmpty ? 'ساحة التنافس' : parts.join(' - ');
  }

  Future<void> _restartChallenge(
    BuildContext context,
    WidgetRef ref,
    ChallengeSession? session,
  ) async {
    if (session == null) return;

    try {
      await ref.read(challengeProvider.notifier).restartChallenge(session.id);
      if (!context.mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ChallengeArenaScreen()),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppError.message(e, fallback: 'تعذر إعادة المنافسة. حاول مجدداً.'),
          ),
        ),
      );
    }
  }

  void _goToChallenges(BuildContext context, WidgetRef ref) {
    ref.invalidate(savedChallengesProvider);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SavedChallengesScreen()),
      (route) => false,
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  final String subjectTitle;
  final ChallengeGroup? winner;
  final bool isTablet;

  const _ResultsHeader({
    required this.subjectTitle,
    required this.winner,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.fromLTRB(isTablet ? 28 : 18, 18, isTablet ? 28 : 18, 12),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: AppTheme.accent.withValues(alpha: 0.36)),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: AppTheme.accent,
              size: 34,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'انتهى التحدي',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Tajawal',
              color: AppTheme.textDark,
              fontSize: 29,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subjectTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              color: AppTheme.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (winner != null) ...[
            const SizedBox(height: 16),
            _WinnerPanel(winner: winner!, isTablet: isTablet),
          ],
        ],
      ),
    );
  }
}

class _WinnerPanel extends StatelessWidget {
  final ChallengeGroup winner;
  final bool isTablet;

  const _WinnerPanel({required this.winner, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: isTablet ? 620 : 520),
      child: ArenaPanel(
        color: AppTheme.accent.withValues(alpha: 0.18),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accent.withValues(alpha: 0.24),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'الفائز بالمركز الأول',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      color: AppTheme.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    winner.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      color: AppTheme.textDark,
                      fontSize: 21,
                      height: 1.1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _ScorePill(score: winner.score, large: true),
          ],
        ),
      ),
    );
  }
}

class _ResultsList extends StatelessWidget {
  final List<ChallengeGroup> groups;
  final bool isTablet;

  const _ResultsList({required this.groups, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        isTablet ? 28 : 18,
        4,
        isTablet ? 28 : 18,
        12,
      ),
      itemCount: groups.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final group = groups[index];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 240 + index * 70),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 18 * (1 - value)),
              child: child,
            ),
          ),
          child: _ResultRow(
            rank: index + 1,
            group: group,
            isWinner: index == 0,
          ),
        );
      },
    );
  }
}

class _ResultRow extends StatelessWidget {
  final int rank;
  final ChallengeGroup group;
  final bool isWinner;

  const _ResultRow({
    required this.rank,
    required this.group,
    required this.isWinner,
  });

  @override
  Widget build(BuildContext context) {
    return ArenaPanel(
      color:
          isWinner ? AppTheme.accent.withValues(alpha: 0.16) : AppTheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      child: Row(
        children: [
          _RankBadge(rank: rank, isWinner: isWinner),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              group.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Tajawal',
                color: AppTheme.textDark,
                fontSize: isWinner ? 18 : 16,
                height: 1.15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          _ScorePill(score: group.score),
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;
  final bool isWinner;

  const _RankBadge({required this.rank, required this.isWinner});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isWinner ? AppTheme.primaryDark : AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isWinner ? AppTheme.primaryDark : AppTheme.border,
        ),
      ),
      child: Center(
        child: Text(
          '$rank',
          style: TextStyle(
            fontFamily: 'Tajawal',
            color: isWinner ? Colors.white : AppTheme.textDark,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  final int score;
  final bool large;

  const _ScorePill({required this.score, this.large = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: large ? 82 : 72),
      padding: EdgeInsets.symmetric(
        horizontal: large ? 12 : 10,
        vertical: large ? 9 : 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$score',
            maxLines: 1,
            style: TextStyle(
              fontFamily: 'Tajawal',
              color: AppTheme.primaryDark,
              fontSize: large ? 22 : 19,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'نقطة',
            maxLines: 1,
            style: TextStyle(
              fontFamily: 'Tajawal',
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'لا توجد مجموعات لعرض النتائج',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Tajawal',
            color: AppTheme.textMuted,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ResultsActions extends StatelessWidget {
  final bool canRestart;
  final VoidCallback onRestart;
  final VoidCallback onBackToChallenges;

  const _ResultsActions({
    required this.canRestart,
    required this.onRestart,
    required this.onBackToChallenges,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: canRestart ? onRestart : null,
              icon: const Icon(Icons.replay_rounded),
              label: const Text('إعادة المنافسة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: onBackToChallenges,
              icon: const Icon(Icons.emoji_events_rounded),
              label: const Text('العودة لقائمة المنافسات'),
            ),
          ),
        ],
      ),
    );
  }
}
