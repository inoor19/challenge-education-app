import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/models/api_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../providers/challenge_provider.dart';
import '../services/feedback_effects_service.dart';

class QuestionDialog extends ConsumerStatefulWidget {
  const QuestionDialog({super.key});

  @override
  ConsumerState<QuestionDialog> createState() => _QuestionDialogState();
}

class _QuestionDialogState extends ConsumerState<QuestionDialog> {
  static const _mutePrefsKey = 'challenge_feedback_muted';

  final FeedbackEffectsService _effects = FeedbackEffectsService();
  String? _selectedAnswer;
  String? _answerResult;
  ChallengeQuestionItem? _questionSnapshot;
  ChallengeGroup? _answeringGroupSnapshot;
  int? _diceValueSnapshot;
  bool _soundMuted = true;
  bool _isSubmitting = false;
  bool _canClose = false;
  bool _timeoutHandled = false;

  @override
  void initState() {
    super.initState();
    final state = ref.read(challengeProvider);
    _questionSnapshot = state.activeQuestion;
    _answeringGroupSnapshot = state.currentGroup;
    _diceValueSnapshot = state.currentDiceValue;
    _loadSoundPreference();
  }

  @override
  void dispose() {
    unawaited(_effects.dispose());
    super.dispose();
  }

  Future<void> _loadSoundPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _soundMuted = prefs.getBool(_mutePrefsKey) ?? false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(challengeProvider);
    final activeQuestion = _questionSnapshot ?? state.activeQuestion;

    if (activeQuestion == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      });
      return const SizedBox.shrink();
    }

    final question = activeQuestion.question!;
    final currentGroup = _answeringGroupSnapshot ?? state.currentGroup;
    final diceValue = _diceValueSnapshot ?? state.currentDiceValue;
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 650;
    final canAnswer =
        diceValue != null && currentGroup != null && _answerResult == null;

    final timerEnabled = state.session?.timerEnabled == true;
    final timerRemaining = state.timerRemaining;

    ref.listen<int>(
      challengeProvider.select((s) => s.timerRemaining),
      (previous, next) {
        final current = ref.read(challengeProvider);
        final isTick = previous != null && next < previous && next > 0;
        final canPlay = current.session?.timerEnabled == true &&
            current.timerRunning &&
            current.activeQuestion != null &&
            _answerResult == null &&
            !_canClose;

        if (isTick && canPlay) {
          unawaited(_effects.playTimerTick(muted: _soundMuted));
        }
      },
    );

    if (timerEnabled &&
        canAnswer &&
        timerRemaining <= 0 &&
        !_timeoutHandled &&
        !_isSubmitting) {
      _timeoutHandled = true;
      Future.microtask(_handleTimeout);
    }

    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isTablet ? 44 : 14,
        vertical: isTablet ? 36 : 18,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: Border.all(color: AppTheme.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 28,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -42,
                  right: -34,
                  child: _GlowDisk(
                    size: 120,
                    color: AppTheme.secondary.withValues(alpha: 0.18),
                  ),
                ),
                Positioned(
                  bottom: -34,
                  left: -28,
                  child: _GlowDisk(
                    size: 104,
                    color: AppTheme.accent.withValues(alpha: 0.16),
                  ),
                ),
                SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    isTablet ? 28 : 18,
                    isTablet ? 26 : 18,
                    isTablet ? 28 : 18,
                    isTablet ? 24 : 18,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _QuestionHeader(
                        sequenceNumber: activeQuestion.sequenceNumber,
                        question: question,
                        timerEnabled: timerEnabled,
                        timerRemaining: timerRemaining,
                      ),
                      const SizedBox(height: 16),
                      _QuestionCard(questionText: question.questionText),
                      if (question.questionType == 'multiple_choice') ...[
                        const SizedBox(height: 12),
                        _OptionsPanel(
                          question: question,
                          enabled: canAnswer && !_isSubmitting,
                          selectedAnswer: _selectedAnswer,
                          answerResult: _answerResult,
                          onSelect: _selectObjectiveAnswer,
                        ),
                      ] else if (question.questionType == 'true_false') ...[
                        const SizedBox(height: 12),
                        _TrueFalsePanel(
                          enabled: canAnswer && !_isSubmitting,
                          selectedAnswer: _selectedAnswer,
                          answerResult: _answerResult,
                          onSelect: _selectObjectiveAnswer,
                        ),
                      ],
                      const SizedBox(height: 14),
                      diceValue == null
                          ? const _NeedDiceBanner()
                          : _DiceInfoBanner(
                              diceValue: diceValue,
                              isHard: question.isHard,
                            ),
                      if (currentGroup != null) ...[
                        const SizedBox(height: 16),
                        _SectionLabel(
                          icon: Icons.groups_rounded,
                          label: 'المجموعة التي تجيب: ${currentGroup.name}',
                        ),
                      ],
                      if (_answerResult != null) ...[
                        const SizedBox(height: 14),
                        _AnswerResultBanner(
                          result: _answerResult!,
                        ),
                      ],
                      if (question.questionType == 'text') ...[
                        const SizedBox(height: 18),
                        _AnswerActions(
                          enabled: canAnswer && !_isSubmitting,
                          onWrong: () => _answer('wrong'),
                          onCorrect: () => _answer('correct'),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_canClose)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _QuestionCloseButton(onPressed: _closeDialog),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectObjectiveAnswer(String answer) async {
    if (_isSubmitting || _answerResult != null) return;

    final question = ref.read(challengeProvider).activeQuestion?.question;
    if (question == null) return;

    final result =
        _answersMatch(answer, question.correctAnswer) ? 'correct' : 'wrong';

    setState(() {
      _selectedAnswer = answer;
      _answerResult = result;
      _isSubmitting = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    await _answer(result);
  }

  Future<void> _answer(String result) async {
    if (_isSubmitting && _answerResult == null) return;
    if (_canClose) return;
    if (!_isSubmitting) {
      setState(() {
        _answerResult = result;
        _isSubmitting = true;
      });
    }

    try {
      final notifier = ref.read(challengeProvider.notifier);
      if (result == 'correct') {
        await notifier.markCorrect(_answeringGroupSnapshot?.id);
      } else {
        await notifier.markWrong(_answeringGroupSnapshot?.id);
      }

      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _canClose = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppError.message(
              e,
              fallback: 'تعذر تسجيل الإجابة. حاول مجدداً.',
            ),
          ),
        ),
      );
      setState(() {
        _answerResult = null;
        _isSubmitting = false;
      });
    }
  }

  void _closeDialog() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    ref.read(challengeProvider.notifier).closeQuestion();
  }

  bool _answersMatch(String selected, String correct) {
    String normalize(String value) => value.trim().toLowerCase();
    return normalize(selected) == normalize(correct);
  }

  Future<void> _handleTimeout() async {
    if (!mounted) return;
    if (_canClose || _answerResult != null) return;

    setState(() {
      _answerResult = 'wrong';
      _isSubmitting = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('انتهى الوقت')),
    );

    try {
      await ref
          .read(challengeProvider.notifier)
          .markWrong(_answeringGroupSnapshot?.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppError.message(
                e,
                fallback: 'تعذر تسجيل انتهاء الوقت. حاول مجدداً.',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _canClose = true;
        });
      }
    }
  }
}

class _QuestionCloseButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _QuestionCloseButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'إغلاق السؤال',
      child: IconButton.filled(
        onPressed: onPressed,
        icon: const Icon(Icons.close_rounded),
        style: IconButton.styleFrom(
          backgroundColor: AppTheme.surface,
          foregroundColor: AppTheme.textDark,
          side: const BorderSide(color: AppTheme.border),
        ),
      ),
    );
  }
}

class _QuestionHeader extends StatelessWidget {
  final int sequenceNumber;
  final Question question;
  final bool timerEnabled;
  final int timerRemaining;

  const _QuestionHeader({
    required this.sequenceNumber,
    required this.question,
    required this.timerEnabled,
    required this.timerRemaining,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.18)),
          ),
          child: Center(
            child: Text(
              '$sequenceNumber',
              style: const TextStyle(
                fontFamily: 'Tajawal',
                color: AppTheme.primary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'سؤال الساحة',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  color: AppTheme.textDark,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              _LevelBadge(isHard: question.isHard, label: question.levelLabel),
            ],
          ),
        ),
        if (timerEnabled)
          _TimerPillInline(
            seconds: timerRemaining,
            isDanger: timerRemaining <= 10,
          ),
      ],
    );
  }
}

class _TimerPillInline extends StatelessWidget {
  final int seconds;
  final bool isDanger;

  const _TimerPillInline({
    required this.seconds,
    required this.isDanger,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? AppTheme.danger : AppTheme.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_rounded, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            '$seconds ث',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final String questionText;

  const _QuestionCard({required this.questionText});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Text(
        questionText,
        textAlign: TextAlign.start,
        style: const TextStyle(
          fontFamily: 'Tajawal',
          color: AppTheme.textDark,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          height: 1.55,
        ),
      ),
    );
  }
}

class _OptionsPanel extends StatelessWidget {
  final Question question;
  final bool enabled;
  final String? selectedAnswer;
  final String? answerResult;
  final ValueChanged<String> onSelect;

  const _OptionsPanel({
    required this.question,
    required this.enabled,
    required this.selectedAnswer,
    required this.answerResult,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      ('أ', question.optionA),
      ('ب', question.optionB),
      ('ج', question.optionC),
      ('د', question.optionD),
    ].where((option) => option.$2 != null && option.$2!.trim().isNotEmpty);

    return Column(
      children: options
          .map(
            (option) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _AnswerChoice(
                label: option.$1,
                text: option.$2!,
                enabled: enabled,
                selected: selectedAnswer == option.$2,
                result: selectedAnswer == option.$2 ? answerResult : null,
                onTap: () => onSelect(option.$2!),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _TrueFalsePanel extends StatelessWidget {
  final bool enabled;
  final String? selectedAnswer;
  final String? answerResult;
  final ValueChanged<String> onSelect;

  const _TrueFalsePanel({
    required this.enabled,
    required this.selectedAnswer,
    required this.answerResult,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _AnswerChoice(
            label: 'صح',
            text: 'صح',
            enabled: enabled,
            selected: selectedAnswer == 'صح',
            result: selectedAnswer == 'صح' ? answerResult : null,
            onTap: () => onSelect('صح'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _AnswerChoice(
            label: 'خطأ',
            text: 'خطأ',
            enabled: enabled,
            selected: selectedAnswer == 'خطأ',
            result: selectedAnswer == 'خطأ' ? answerResult : null,
            onTap: () => onSelect('خطأ'),
          ),
        ),
      ],
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final bool isHard;
  final String label;

  const _LevelBadge({required this.isHard, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = isHard ? AppTheme.accentAlt : AppTheme.success;
    return StatusBadge(
      label: isHard ? '$label x2' : label,
      color: color,
      icon: isHard ? Icons.local_fire_department_rounded : Icons.bolt_rounded,
    );
  }
}

class _DiceInfoBanner extends StatelessWidget {
  final int diceValue;
  final bool isHard;

  const _DiceInfoBanner({required this.diceValue, required this.isHard});

  @override
  Widget build(BuildContext context) {
    final points = isHard ? diceValue * 2 : diceValue;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.36)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.iconBorder(AppTheme.accent)),
            ),
            child: const Icon(
              Icons.casino_rounded,
              color: AppTheme.accent,
              size: 24,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isHard
                  ? 'النرد $diceValue x 2 = $points نقطة للسؤال الصعب'
                  : 'النرد $diceValue = $points نقطة للسؤال السهل',
              style: const TextStyle(
                fontFamily: 'Tajawal',
                color: AppTheme.accent,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NeedDiceBanner extends StatelessWidget {
  const _NeedDiceBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.36)),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'يرجى رم النرد أولاً لتحديد نقاط السؤال',
              style: TextStyle(
                fontFamily: 'Tajawal',
                color: AppTheme.warning,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.textMuted, size: 18),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            color: AppTheme.textMuted,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _AnswerChoice extends StatelessWidget {
  final String label;
  final String text;
  final bool enabled;
  final bool selected;
  final String? result;
  final VoidCallback onTap;

  const _AnswerChoice({
    required this.label,
    required this.text,
    required this.enabled,
    required this.selected,
    required this.result,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final resultColor =
        result == 'correct' ? AppTheme.success : AppTheme.danger;
    final borderColor = result == null
        ? (selected ? AppTheme.accent : AppTheme.border)
        : resultColor;

    return InkWell(
      key: ValueKey('answer-choice-$label'),
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected && result == 'correct'
              ? AppTheme.success.withValues(alpha: 0.18)
              : selected && result == 'wrong'
                  ? AppTheme.danger.withValues(alpha: 0.14)
                  : selected
                      ? AppTheme.surfaceAlt
                      : AppTheme.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: selected ? 1.6 : 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: result == null
                    ? Colors.white.withValues(alpha: 0.92)
                    : resultColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: result == null
                    ? Text(
                        label,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          color: AppTheme.textDark,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      )
                    : Icon(
                        result == 'correct'
                            ? Icons.check_rounded
                            : Icons.close_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  color: AppTheme.textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnswerResultBanner extends StatelessWidget {
  final String result;

  const _AnswerResultBanner({
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final correct = result == 'correct';
    final color = correct ? AppTheme.success : AppTheme.danger;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.38)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: color,
              size: 23,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              correct ? 'إجابة صحيحة' : 'إجابة خاطئة',
              style: TextStyle(
                fontFamily: 'Tajawal',
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerActions extends StatelessWidget {
  final bool enabled;
  final VoidCallback onWrong;
  final VoidCallback onCorrect;

  const _AnswerActions({
    required this.enabled,
    required this.onWrong,
    required this.onCorrect,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 390;
    final actions = [
      Expanded(
        child: ElevatedButton.icon(
          onPressed: enabled ? onCorrect : null,
          icon: const Icon(Icons.check_rounded),
          label: const Text('صحيحة'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.success,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 52),
          ),
        ),
      ),
      SizedBox(width: isCompact ? 0 : 12, height: isCompact ? 10 : 0),
      Expanded(
        child: ElevatedButton.icon(
          onPressed: enabled ? onWrong : null,
          icon: const Icon(Icons.close_rounded),
          label: const Text('خاطئة'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.danger,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 52),
          ),
        ),
      ),
    ];

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: actions
            .map(
              (child) => child is Expanded
                  ? SizedBox(height: 52, child: child.child)
                  : child,
            )
            .toList(),
      );
    }

    return Row(children: actions);
  }
}

class _GlowDisk extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowDisk({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
