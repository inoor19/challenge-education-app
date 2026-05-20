import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/api_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../providers/challenge_provider.dart';

class QuestionGrid extends ConsumerWidget {
  final List<ChallengeQuestionItem> questions;

  const QuestionGrid({super.key, required this.questions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diceValue =
        ref.watch(challengeProvider.select((s) => s.currentDiceValue));

    if (questions.isEmpty) {
      return const AppStateView(
        icon: Icons.quiz_rounded,
        title: 'لا توجد أسئلة',
        message: 'لا توجد أسئلة في هذه الجلسة.',
      );
    }

    final isTablet = MediaQuery.of(context).size.width > 720;
    final width = MediaQuery.of(context).size.width;
    final crossCount = isTablet ? 8 : (width > 420 ? 5 : 4);

    return GridView.builder(
      shrinkWrap: !isTablet,
      physics: isTablet ? null : const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: questions.length,
      itemBuilder: (ctx, i) {
        final q = questions[i];
        return _QuestionCell(
          question: q,
          onTap: q.isUsed
              ? null
              : () {
                  if (diceValue == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('يرجى رمّ النرد أولاً')),
                    );
                    return;
                  }
                  ref.read(challengeProvider.notifier).openQuestion(q);
                },
        );
      },
    );
  }
}

class _QuestionCell extends StatelessWidget {
  final ChallengeQuestionItem question;
  final VoidCallback? onTap;

  const _QuestionCell({required this.question, this.onTap});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    Widget? overlay;
    String label = '${question.sequenceNumber}';

    if (question.isUsed) {
      if (question.answerStatus == 'correct') {
        bgColor = AppTheme.success.withValues(alpha: 0.18);
        textColor = AppTheme.success;
        overlay =
            const Icon(Icons.check_circle_rounded, color: AppTheme.success);
      } else {
        bgColor = AppTheme.danger.withValues(alpha: 0.18);
        textColor = AppTheme.danger;
        overlay = const Icon(Icons.cancel_rounded, color: AppTheme.danger);
      }
    } else {
      final q = question.question;
      if (q?.level == 'hard') {
        bgColor = AppTheme.accentAlt.withValues(alpha: 0.2);
        textColor = AppTheme.accentAlt;
        label = '${question.sequenceNumber}';
      } else {
        bgColor = AppTheme.secondary.withValues(alpha: 0.18);
        textColor = AppTheme.primaryDark;
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: question.isUsed
              ? textColor.withValues(alpha: 0.42)
              : Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              if (question.question?.isHard == true && !question.isUsed)
                const Positioned(
                  top: 6,
                  left: 6,
                  child: Icon(Icons.local_fire_department_rounded,
                      color: AppTheme.accentAlt, size: 14),
                ),
              Center(
                child: overlay ??
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
