import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/app_config.dart';
import '../../../core/models/api_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../providers/challenge_provider.dart';
import '../services/feedback_effects_service.dart';
import '../widgets/question_dialog.dart';
import 'results_screen.dart';

class ChallengeArenaScreen extends ConsumerStatefulWidget {
  const ChallengeArenaScreen({super.key});

  @override
  ConsumerState<ChallengeArenaScreen> createState() =>
      _ChallengeArenaScreenState();
}

class _ChallengeArenaScreenState extends ConsumerState<ChallengeArenaScreen> {
  static const _mutePrefsKey = 'challenge_feedback_muted';

  final FeedbackEffectsService _effects = FeedbackEffectsService();
  bool _soundMuted = false;
  String? _feedbackResult;
  String _difficultyFilter = 'all';
  Timer? _feedbackTimer;

  @override
  void initState() {
    super.initState();
    _loadSoundPreference();
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    _effects.dispose();
    super.dispose();
  }

  Future<void> _loadSoundPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _soundMuted = prefs.getBool(_mutePrefsKey) ?? false);
    }
  }

  Future<void> _toggleSound() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _soundMuted = !_soundMuted);
    await prefs.setBool(_mutePrefsKey, _soundMuted);
  }

  @override
  Widget build(BuildContext context) {
    final arenaState = ref.watch(challengeProvider);
    final session = arenaState.session;

    ref.listen(challengeProvider.select((s) => s.activeQuestion), (prev, next) {
      if (next != null && context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const QuestionDialog(),
        );
      }
    });

    ref.listen(challengeProvider.select((s) => s.lastAnswerResult),
        (prev, next) {
      if (next == null || !context.mounted) return;
      _showAnswerFeedback(next);
    });

    ref.listen(challengeProvider.select((s) => s.session?.status),
        (prev, next) {
      if (prev == 'completed' || next != 'completed' || !context.mounted) {
        return;
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ResultsScreen()),
        (route) => false,
      );
    });

    if (session == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          _SubjectArenaBackground(subject: session.subject),
          SafeArea(
            child: Column(
              children: [
                _ArenaTopBar(
                  session: session,
                  muted: _soundMuted,
                  onMuteToggle: _toggleSound,
                  onEnd: () => _confirmEnd(context),
                ),
                Expanded(
                  child: _ArenaStage(
                    arenaState: arenaState,
                    difficultyFilter: _difficultyFilter,
                    onDifficultyChanged: (value) =>
                        setState(() => _difficultyFilter = value),
                  ),
                ),
                _TeamsDock(
                  groups: arenaState.groups,
                  currentGroupId: arenaState.currentGroup?.id,
                  ref: ref,
                ),
              ],
            ),
          ),
          _FeedbackOverlay(result: _feedbackResult),
        ],
      ),
    );
  }

  Future<void> _showAnswerFeedback(String result) async {
    _feedbackTimer?.cancel();
    setState(() => _feedbackResult = result);

    if (result == 'correct') {
      unawaited(_effects.playCorrect(muted: _soundMuted));
    } else {
      unawaited(_effects.playWrong(muted: _soundMuted));
    }

    _feedbackTimer = Timer(const Duration(milliseconds: 1250), () {
      if (mounted) setState(() => _feedbackResult = null);
    });
  }

  Future<void> _confirmEnd(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إنهاء التحدي'),
        content: const Text('هل تريد إنهاء التحدي والانتقال لشاشة النتائج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('لا'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('نعم، أنهِ'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(challengeProvider.notifier).completeChallenge();
    }
  }
}

class _SubjectArenaBackground extends StatelessWidget {
  final Subject? subject;

  const _SubjectArenaBackground({required this.subject});

  @override
  Widget build(BuildContext context) {
    final imageUrl = _resolveBackgroundImageUrl(subject?.backgroundImageUrl);
    final colors = _themeColors(subject?.backgroundTheme);
    final backgroundColor = colors.first;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(color: backgroundColor),
        ),
        if (imageUrl != null)
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          )
        else
          CustomPaint(painter: _SubjectBackdropPainter(subject?.name ?? '')),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.background.withValues(alpha: 0.18),
          ),
        ),
      ],
    );
  }

  String? _resolveBackgroundImageUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) {
      return null;
    }

    final apiUri = Uri.tryParse(AppConfig.apiBaseUrl);
    final backendOrigin =
        apiUri?.replace(path: '', query: '', fragment: '').toString();
    final imageUri = Uri.tryParse(rawUrl);

    if (imageUri == null) {
      return rawUrl;
    }

    if (!imageUri.hasScheme) {
      if (backendOrigin == null) return rawUrl;
      return Uri.parse(backendOrigin)
          .resolve(rawUrl.startsWith('/') ? rawUrl.substring(1) : rawUrl)
          .toString();
    }

    final host = imageUri.host.toLowerCase();
    final pointsToLocalhost = host == 'localhost' || host == '127.0.0.1';
    if (!pointsToLocalhost || backendOrigin == null) {
      return rawUrl;
    }

    final backendUri = Uri.parse(backendOrigin);
    final backendHasExplicitPort =
        backendUri.authority.split('@').last.contains(':');
    return Uri(
      scheme: backendUri.scheme,
      userInfo: backendUri.userInfo,
      host: backendUri.host,
      port: backendHasExplicitPort ? backendUri.port : 0,
      path: imageUri.path,
      query: imageUri.query.isEmpty ? null : imageUri.query,
      fragment: imageUri.fragment.isEmpty ? null : imageUri.fragment,
    ).toString();
  }

  List<Color> _themeColors(String? theme) {
    return switch (theme) {
      'science' => const [
          Color(0xFF84976D),
          Color(0xFF6E8790),
          Color(0xFFF3F0E8),
        ],
      'math' => const [
          Color(0xFFB88632),
          Color(0xFFE8DDC8),
          Color(0xFFFFFCF4),
        ],
      'english' => const [
          Color(0xFF537A6E),
          Color(0xFF8FA1A4),
          Color(0xFFF3F0E8),
        ],
      'islamic' => const [
          Color(0xFF617447),
          Color(0xFFE8DDC8),
          Color(0xFFF3F0E8),
        ],
      'social' => const [
          Color(0xFFA4653F),
          Color(0xFFD8C9AE),
          Color(0xFFF3F0E8),
        ],
      _ => const [
          Color(0xFFF3F0E8),
          Color(0xFFE8DDC8),
          Color(0xFFB88632),
        ],
    };
  }
}

class _SubjectBackdropPainter extends CustomPainter {
  final String subjectName;

  const _SubjectBackdropPainter(this.subjectName);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final subject = subjectName.toLowerCase();
    final icons = subject.contains('علوم')
        ? ['⚗', '◌', '△', 'pH']
        : subject.contains('رياض')
            ? ['√π', '△', '□', '123']
            : subject.contains('إنج') || subject.contains('english')
                ? ['A', 'B', 'Hello', 'C']
                : ['✦', '◌', 'كتاب', '★'];

    paint.color = Colors.white.withValues(alpha: 0.22);
    canvas.drawCircle(Offset(size.width * .15, size.height * .20), 38, paint);
    paint.color = Colors.white.withValues(alpha: 0.18);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * .74, size.height * .16, 92, 92),
        const Radius.circular(12),
      ),
      paint,
    );
    paint.color = Colors.white.withValues(alpha: 0.14);
    canvas.drawCircle(Offset(size.width * .82, size.height * .70), 58, paint);

    for (var i = 0; i < icons.length; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: icons[i],
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.42),
            fontSize: i.isEven ? 34 : 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final dx = (size.width * (0.14 + i * 0.22)).clamp(18.0, size.width - 70);
      final dy = i.isEven ? size.height * .22 : size.height * .72;
      tp.paint(canvas, Offset(dx, dy));
    }
  }

  @override
  bool shouldRepaint(covariant _SubjectBackdropPainter oldDelegate) =>
      oldDelegate.subjectName != subjectName;
}

class _ArenaTopBar extends StatelessWidget {
  final ChallengeSession session;
  final bool muted;
  final VoidCallback onMuteToggle;
  final VoidCallback onEnd;

  const _ArenaTopBar({
    required this.session,
    required this.muted,
    required this.onMuteToggle,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    final title = [
      if (session.subject != null) session.subject!.name,
      if (session.subjectPart != null) session.subjectPart!.name,
      if (session.grade != null) session.grade!.name,
    ].join(' - ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          _CircleGlassButton(
            icon: Icons.close_rounded,
            tooltip: 'إنهاء التحدي',
            onPressed: onEnd,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _GlassPill(
              child: Text(
                title.isEmpty ? 'ساحة التحدي' : title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  color: AppTheme.textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _CircleGlassButton(
            icon: muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
            tooltip: muted ? 'تشغيل الصوت' : 'كتم الصوت',
            onPressed: onMuteToggle,
          ),
        ],
      ),
    );
  }
}

class _ArenaStage extends ConsumerStatefulWidget {
  final ChallengeArenaState arenaState;
  final String difficultyFilter;
  final ValueChanged<String> onDifficultyChanged;

  const _ArenaStage({
    required this.arenaState,
    required this.difficultyFilter,
    required this.onDifficultyChanged,
  });

  @override
  ConsumerState<_ArenaStage> createState() => _ArenaStageState();
}

class _ArenaStageState extends ConsumerState<_ArenaStage> {
  int _currentPage = 0;

  @override
  void didUpdateWidget(covariant _ArenaStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.difficultyFilter != widget.difficultyFilter) {
      _currentPage = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 720;
    final questions = _filteredQuestions(widget.arenaState.questions);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 14,
        vertical: 8,
      ),
      child: Column(
        children: [
          _TimerPill(arenaState: widget.arenaState),
          const SizedBox(height: 8),
          _TurnPill(group: widget.arenaState.currentGroup),
          const SizedBox(height: 10),
          Expanded(
            child: _QuestionBoard(
              questions: questions,
              currentPage: _currentPage,
              maxWidth: isTablet ? 680 : 430,
              onPageChanged: (page) => setState(() => _currentPage = page),
            ),
          ),
          const SizedBox(height: 10),
          _ControlStrip(
            arenaState: widget.arenaState,
            difficultyFilter: widget.difficultyFilter,
            onDifficultyChanged: (value) {
              if (value != widget.difficultyFilter) {
                setState(() => _currentPage = 0);
              }
              widget.onDifficultyChanged(value);
            },
          ),
        ],
      ),
    );
  }

  List<ChallengeQuestionItem> _filteredQuestions(
    List<ChallengeQuestionItem> questions,
  ) {
    if (widget.difficultyFilter == 'easy') {
      return questions.where((q) => q.question?.isHard != true).toList();
    }
    if (widget.difficultyFilter == 'hard') {
      return questions.where((q) => q.question?.isHard == true).toList();
    }
    return questions;
  }
}

class _TimerPill extends ConsumerWidget {
  final ChallengeArenaState arenaState;

  const _TimerPill({required this.arenaState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerEnabled = arenaState.session?.timerEnabled ?? true;
    final label =
        timerEnabled ? _formatTime(arenaState.timerRemaining) : 'بدون مؤقت';
    final warning = arenaState.timerRemaining <= 10 && timerEnabled;

    return _GlassPill(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Tajawal',
              color: warning ? AppTheme.danger : AppTheme.textDark,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.timer_outlined,
            color: warning ? AppTheme.danger : AppTheme.textDark,
            size: 21,
          ),
          if (timerEnabled) ...[
            const SizedBox(width: 10),
            _TimerIconButton(
              icon: arenaState.timerRunning
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              tooltip:
                  arenaState.timerRunning ? 'إيقاف المؤقت' : 'تشغيل المؤقت',
              onTap: arenaState.timerRunning
                  ? () => ref.read(challengeProvider.notifier).pauseTimer()
                  : () => ref.read(challengeProvider.notifier).startTimer(),
            ),
            const SizedBox(width: 6),
            _TimerIconButton(
              icon: Icons.restart_alt_rounded,
              tooltip: 'إعادة ضبط المؤقت',
              onTap: () => ref.read(challengeProvider.notifier).resetTimer(),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (s == 0 && m > 0) return '$m min';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _TimerIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _TimerIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.56),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, color: AppTheme.textDark, size: 20),
        ),
      ),
    );
  }
}

class _TurnPill extends StatelessWidget {
  final ChallengeGroup? group;

  const _TurnPill({required this.group});

  @override
  Widget build(BuildContext context) {
    return _GlassPill(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.groups_rounded,
            color: AppTheme.textDark,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            group == null
                ? 'لا توجد مجموعة حالية'
                : 'دور ${group!.name} لرمي النرد',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              color: AppTheme.textDark,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionBoard extends ConsumerWidget {
  final List<ChallengeQuestionItem> questions;
  final int currentPage;
  final double maxWidth;
  final ValueChanged<int> onPageChanged;

  const _QuestionBoard({
    required this.questions,
    required this.currentPage,
    required this.maxWidth,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diceValue =
        ref.watch(challengeProvider.select((s) => s.currentDiceValue));

    return LayoutBuilder(
      builder: (context, outerConstraints) {
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: outerConstraints.maxHeight,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.36)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (questions.isEmpty) {
                    return const Center(
                      child: AppStateView(
                        icon: Icons.quiz_rounded,
                        title: 'لا توجد أسئلة',
                        message: 'لا توجد أسئلة تطابق هذا الاختيار.',
                      ),
                    );
                  }

                  const spacing = 10.0;
                  const pageControlsHeight = 38.0;
                  const pageControlsGap = 8.0;
                  final availableWidth = constraints.maxWidth;
                  final availableHeight = constraints.maxHeight;
                  var layout = QuestionBoardLayout.forSize(
                    width: availableWidth,
                    height: availableHeight,
                    questionCount: questions.length,
                    spacing: spacing,
                  );
                  if (questions.length > layout.questionsPerPage) {
                    layout = QuestionBoardLayout.forSize(
                      width: availableWidth,
                      height: math.max(
                        96.0,
                        availableHeight - pageControlsHeight - pageControlsGap,
                      ),
                      questionCount: questions.length,
                      spacing: spacing,
                    );
                  }
                  final pageCount = layout.pageCount;
                  final page = currentPage.clamp(0, pageCount - 1);
                  if (page != currentPage) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      onPageChanged(page);
                    });
                  }

                  final start = page * layout.questionsPerPage;
                  final end = math.min(
                      start + layout.questionsPerPage, questions.length);
                  final visibleQuestions = questions.sublist(start, end);
                  final hasPages = pageCount > 1;
                  final cellSize = layout.cellSize;
                  final gridWidth = layout.columns * cellSize +
                      (layout.columns - 1) * spacing;

                  return Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: SizedBox(
                            width: gridWidth,
                            child: Wrap(
                              spacing: spacing,
                              runSpacing: spacing,
                              children: visibleQuestions
                                  .map(
                                    (question) => _ArenaQuestionTile(
                                      question: question,
                                      size: cellSize,
                                      onTap: question.isUsed
                                          ? null
                                          : () {
                                              if (diceValue == null) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'يرجى رمّ النرد أولاً',
                                                    ),
                                                  ),
                                                );
                                                return;
                                              }
                                              ref
                                                  .read(
                                                    challengeProvider.notifier,
                                                  )
                                                  .openQuestion(question);
                                            },
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                      ),
                      if (hasPages) ...[
                        const SizedBox(height: pageControlsGap),
                        _QuestionPageControls(
                          currentPage: page,
                          pageCount: pageCount,
                          onPrevious:
                              page == 0 ? null : () => onPageChanged(page - 1),
                          onNext: page == pageCount - 1
                              ? null
                              : () => onPageChanged(page + 1),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

@visibleForTesting
class QuestionBoardLayout {
  final int columns;
  final int rows;
  final double cellSize;
  final int questionsPerPage;
  final int pageCount;

  const QuestionBoardLayout({
    required this.columns,
    required this.rows,
    required this.cellSize,
    required this.questionsPerPage,
    required this.pageCount,
  });

  factory QuestionBoardLayout.forSize({
    required double width,
    required double height,
    required int questionCount,
    double spacing = 10,
  }) {
    const minCellSize = 54.0;
    const maxCellSize = 96.0;
    final safeWidth = math.max(width, minCellSize);
    final safeHeight = math.max(height, minCellSize);
    final maxColumns =
        math.max(1, ((safeWidth + spacing) / (minCellSize + spacing)).floor());
    final maxRows =
        math.max(1, ((safeHeight + spacing) / (minCellSize + spacing)).floor());

    var bestColumns = 1;
    var bestRows = 1;
    var bestCellSize = minCellSize;
    var bestCapacity = 1;
    var bestScore = -1.0;

    for (var columns = 1; columns <= maxColumns; columns++) {
      for (var rows = 1; rows <= maxRows; rows++) {
        final cellByWidth = (safeWidth - spacing * (columns - 1)) / columns;
        final cellByHeight = (safeHeight - spacing * (rows - 1)) / rows;
        final cellSize =
            math.min(maxCellSize, math.min(cellByWidth, cellByHeight));
        if (cellSize < minCellSize) continue;

        final capacity = columns * rows;
        final filledSlots = math.min(capacity, questionCount);
        final visibleRatio =
            questionCount == 0 ? 1.0 : filledSlots / questionCount;
        final areaScore = filledSlots * cellSize;
        final balancePenalty = (columns - rows).abs() * 4.0;
        final score = areaScore + visibleRatio * 120 - balancePenalty;

        if (score > bestScore ||
            (score == bestScore && capacity > bestCapacity)) {
          bestScore = score;
          bestColumns = columns;
          bestRows = rows;
          bestCellSize = cellSize;
          bestCapacity = capacity;
        }
      }
    }

    final questionsPerPage = math.max(1, bestCapacity);
    final pageCount =
        questionCount == 0 ? 1 : (questionCount / questionsPerPage).ceil();

    return QuestionBoardLayout(
      columns: bestColumns,
      rows: bestRows,
      cellSize: bestCellSize,
      questionsPerPage: questionsPerPage,
      pageCount: pageCount,
    );
  }
}

class _QuestionPageControls extends StatelessWidget {
  final int currentPage;
  final int pageCount;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const _QuestionPageControls({
    required this.currentPage,
    required this.pageCount,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: _GlassPill(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PageIconButton(
              icon: Icons.chevron_right_rounded,
              tooltip: 'الصفحة السابقة',
              onTap: onPrevious,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '${currentPage + 1} / $pageCount',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  color: AppTheme.textDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            _PageIconButton(
              icon: Icons.chevron_left_rounded,
              tooltip: 'الصفحة التالية',
              onTap: onNext,
            ),
          ],
        ),
      ),
    );
  }
}

class _PageIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _PageIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: enabled
                ? Colors.white.withValues(alpha: 0.58)
                : Colors.white.withValues(alpha: 0.24),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(
            icon,
            color: enabled
                ? AppTheme.textDark
                : AppTheme.textMuted.withValues(alpha: 0.46),
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _ArenaQuestionTile extends StatelessWidget {
  final ChallengeQuestionItem question;
  final double size;
  final VoidCallback? onTap;

  const _ArenaQuestionTile({
    required this.question,
    required this.size,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUsed = question.isUsed;
    final isHard = question.question?.isHard == true;
    final Color foreground;
    final Widget child;

    if (isUsed && question.answerStatus == 'correct') {
      foreground = AppTheme.success;
      child = const Icon(Icons.check_rounded, size: 32);
    } else if (isUsed) {
      foreground = AppTheme.danger;
      child = const Icon(Icons.close_rounded, size: 32);
    } else {
      foreground = isHard ? AppTheme.accentAlt : AppTheme.textDark;
      child = Text(
        '${question.sequenceNumber}',
        style: TextStyle(
          fontFamily: 'Tajawal',
          color: foreground,
          fontSize: 27,
          fontWeight: FontWeight.w900,
        ),
      );
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      opacity: isUsed ? 0.58 : 1,
      child: SizedBox(
        width: size,
        height: size,
        child: Material(
          color: isUsed
              ? Colors.white.withValues(alpha: 0.44)
              : Colors.white.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(8),
          elevation: isUsed ? 0 : 5,
          shadowColor: Colors.black.withValues(alpha: 0.16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                if (isHard && !isUsed)
                  const Positioned(
                    top: 6,
                    left: 6,
                    child: Icon(
                      Icons.local_fire_department_rounded,
                      color: AppTheme.accentAlt,
                      size: 16,
                    ),
                  ),
                Center(
                  child: IconTheme(
                    data: IconThemeData(color: foreground),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ControlStrip extends ConsumerWidget {
  final ChallengeArenaState arenaState;
  final String difficultyFilter;
  final ValueChanged<String> onDifficultyChanged;

  const _ControlStrip({
    required this.arenaState,
    required this.difficultyFilter,
    required this.onDifficultyChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _GlassPill(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          _Dice3DButton(
            value: arenaState.currentDiceValue,
            isRolling: arenaState.isDiceRolling,
            onRoll: () => ref.read(challengeProvider.notifier).rollDice(),
          ),
          _FilterChipButton(
            label: 'الكل',
            selected: difficultyFilter == 'all',
            onTap: () => onDifficultyChanged('all'),
          ),
          _FilterChipButton(
            label: 'سهل',
            selected: difficultyFilter == 'easy',
            onTap: () => onDifficultyChanged('easy'),
          ),
          _FilterChipButton(
            label: 'صعب x2',
            selected: difficultyFilter == 'hard',
            onTap: () => onDifficultyChanged('hard'),
          ),
        ],
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.accent.withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.44),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Tajawal',
            color: selected ? Colors.white : AppTheme.textDark,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _Dice3DButton extends StatelessWidget {
  final int? value;
  final bool isRolling;
  final VoidCallback onRoll;

  const _Dice3DButton({
    required this.value,
    required this.isRolling,
    required this.onRoll,
  });

  @override
  Widget build(BuildContext context) {
    final isPhone = MediaQuery.of(context).size.width < 600;
    final diceSize = isPhone ? 42.0 : 36.0;
    final label = value == null ? 'نقاط الحظ' : '$value نقطة';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isRolling ? null : onRoll,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: EdgeInsets.symmetric(
            horizontal: isPhone ? 10 : 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: isRolling ? 0.30 : 0.50),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.40)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: RotationTransition(turns: animation, child: child),
                ),
                child: isRolling
                    ? SizedBox(
                        key: const ValueKey('rolling'),
                        width: diceSize,
                        height: diceSize,
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          ),
                        ),
                      )
                    : _DiceCube(
                        key: ValueKey(value ?? 0),
                        value: value ?? 0,
                        size: diceSize,
                      ),
              ),
              SizedBox(width: isPhone ? 8 : 7),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  color: AppTheme.textDark,
                  fontSize: isPhone ? 13 : 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiceCube extends StatelessWidget {
  final int value;
  final double size;

  const _DiceCube({
    super.key,
    required this.value,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0018)
        ..rotateX(-math.pi / 14)
        ..rotateY(math.pi / 9),
      child: CustomPaint(
        size: Size(size, size),
        painter: _DiceCubePainter(value: value),
      ),
    );
  }
}

class _DiceCubePainter extends CustomPainter {
  final int value;

  const _DiceCubePainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final depth = size.width * 0.18;
    final radius = Radius.circular(size.width * 0.16);
    final frontRect = Rect.fromLTWH(
      depth * 0.35,
      depth,
      size.width - depth,
      size.height - depth * 1.15,
    );

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(frontRect.shift(const Offset(2, 4)), radius),
      shadowPaint,
    );

    final topPath = Path()
      ..moveTo(frontRect.left, frontRect.top)
      ..lineTo(frontRect.left + depth, frontRect.top - depth * 0.72)
      ..lineTo(frontRect.right + depth, frontRect.top - depth * 0.72)
      ..lineTo(frontRect.right, frontRect.top)
      ..close();
    final rightPath = Path()
      ..moveTo(frontRect.right, frontRect.top)
      ..lineTo(frontRect.right + depth, frontRect.top - depth * 0.72)
      ..lineTo(frontRect.right + depth, frontRect.bottom - depth * 0.72)
      ..lineTo(frontRect.right, frontRect.bottom)
      ..close();

    final topPaint = Paint()..color = const Color(0xFFFFF7E6);
    final rightPaint = Paint()..color = AppTheme.surfaceAlt;
    final frontPaint = Paint()..color = Colors.white;
    canvas.drawPath(topPath, topPaint);
    canvas.drawPath(rightPath, rightPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(frontRect, radius), frontPaint);

    final edgePaint = Paint()
      ..color = AppTheme.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    canvas.drawPath(topPath, edgePaint);
    canvas.drawPath(rightPath, edgePaint);
    canvas.drawRRect(RRect.fromRectAndRadius(frontRect, radius), edgePaint);

    final pipPaint = Paint()..color = AppTheme.textDark;
    final pipRadius = frontRect.width * 0.065;
    final positions = _pipPositions(frontRect, value);
    if (positions.isEmpty) {
      final qPaint = Paint()..color = AppTheme.accent;
      canvas.drawCircle(frontRect.center, pipRadius * 1.35, qPaint);
      return;
    }

    for (final position in positions) {
      canvas.drawCircle(position, pipRadius, pipPaint);
    }
  }

  List<Offset> _pipPositions(Rect rect, int rawValue) {
    if (rawValue < 1) return const [];

    final value = rawValue.clamp(1, 6);
    final left = rect.left + rect.width * 0.27;
    final centerX = rect.center.dx;
    final right = rect.right - rect.width * 0.27;
    final top = rect.top + rect.height * 0.27;
    final centerY = rect.center.dy;
    final bottom = rect.bottom - rect.height * 0.27;

    return switch (value) {
      1 => [Offset(centerX, centerY)],
      2 => [Offset(left, top), Offset(right, bottom)],
      3 => [Offset(left, top), Offset(centerX, centerY), Offset(right, bottom)],
      4 => [
          Offset(left, top),
          Offset(right, top),
          Offset(left, bottom),
          Offset(right, bottom),
        ],
      5 => [
          Offset(left, top),
          Offset(right, top),
          Offset(centerX, centerY),
          Offset(left, bottom),
          Offset(right, bottom),
        ],
      _ => [
          Offset(left, top),
          Offset(right, top),
          Offset(left, centerY),
          Offset(right, centerY),
          Offset(left, bottom),
          Offset(right, bottom),
        ],
    };
  }

  @override
  bool shouldRepaint(covariant _DiceCubePainter oldDelegate) =>
      oldDelegate.value != value;
}

class _TeamsDock extends StatelessWidget {
  final List<ChallengeGroup> groups;
  final int? currentGroupId;
  final WidgetRef ref;

  const _TeamsDock({
    required this.groups,
    required this.currentGroupId,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isTablet = width > 720;
        final horizontalPadding = isTablet ? 18.0 : 10.0;
        final gap = isTablet ? 12.0 : 8.0;
        final visibleCards = groups.length <= 2
            ? groups.length.clamp(1, 2)
            : (isTablet ? 4 : (width < 390 ? 2 : 3));
        final rawCardWidth =
            (width - horizontalPadding * 2 - gap * (visibleCards - 1)) /
                visibleCards;
        final cardWidth = rawCardWidth.clamp(isTablet ? 132.0 : 106.0, 168.0);
        final compact = cardWidth < 124;
        final longestName = groups.fold<int>(
          0,
          (length, group) => math.max(length, group.name.characters.length),
        );
        final needsMoreNameSpace =
            longestName > (compact ? 10 : 16) || groups.length > visibleCards;
        final cardHeight = (isTablet
                ? (needsMoreNameSpace ? 98.0 : 86.0)
                : (needsMoreNameSpace ? 92.0 : 80.0))
            .clamp(80.0, 104.0);
        final dockHeight = cardHeight + 22;

        return SizedBox(
          height: dockHeight,
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              8,
              horizontalPadding,
              12,
            ),
            scrollDirection: Axis.horizontal,
            itemCount: groups.length,
            separatorBuilder: (_, __) => SizedBox(width: gap),
            itemBuilder: (context, index) => _TeamScoreCard(
              width: cardWidth,
              height: cardHeight,
              compact: compact,
              allowTwoLineName: needsMoreNameSpace,
              group: groups[index],
              isCurrent: groups[index].id == currentGroupId,
              onAdd: () => ref
                  .read(challengeProvider.notifier)
                  .manualAdd(groups[index].id, 1),
              onSubtract: () => ref
                  .read(challengeProvider.notifier)
                  .manualSubtract(groups[index].id, 1),
            ),
          ),
        );
      },
    );
  }
}

class _TeamScoreCard extends StatelessWidget {
  final double width;
  final double height;
  final bool compact;
  final bool allowTwoLineName;
  final ChallengeGroup group;
  final bool isCurrent;
  final VoidCallback onAdd;
  final VoidCallback onSubtract;

  const _TeamScoreCard({
    required this.width,
    required this.height,
    required this.compact,
    required this.allowTwoLineName,
    required this.group,
    required this.isCurrent,
    required this.onAdd,
    required this.onSubtract,
  });

  @override
  Widget build(BuildContext context) {
    final titleSize = compact ? 11.5 : 13.0;
    final scoreSize = compact ? 17.0 : 20.0;
    final buttonSize = compact ? 22.0 : 25.0;
    final showPointsLabel = !compact && height >= 88;
    final cardColor =
        isCurrent ? AppTheme.primaryDark : Colors.white.withValues(alpha: 0.88);
    final mainTextColor = isCurrent ? Colors.white : AppTheme.textDark;
    final mutedTextColor =
        isCurrent ? Colors.white.withValues(alpha: 0.78) : AppTheme.textMuted;

    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 7 : 8,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrent
              ? AppTheme.primaryDark.withValues(alpha: 0.32)
              : Colors.transparent,
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            group.name,
            maxLines: allowTwoLineName ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Tajawal',
              color: mainTextColor,
              fontSize: titleSize,
              height: 1.05,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (showPointsLabel)
            Text(
              'نقطة',
              style: TextStyle(
                color: mutedTextColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          SizedBox(height: compact ? 2 : 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ScoreButton(
                icon: Icons.remove_rounded,
                onTap: onSubtract,
                size: buttonSize,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Text(
                    '${group.score}',
                    key: ValueKey(group.score),
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      color: mainTextColor,
                      fontSize: scoreSize,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              _ScoreButton(
                icon: Icons.add_rounded,
                onTap: onAdd,
                size: buttonSize,
                color: AppTheme.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final Color color;

  const _ScoreButton({
    required this.icon,
    required this.onTap,
    this.size = 24,
    this.color = AppTheme.surfaceAlt,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = color != AppTheme.surfaceAlt;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(
          icon,
          color: isDark ? Colors.white : AppTheme.textMuted,
          size: size * 0.66,
        ),
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _GlassPill({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CircleGlassButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _CircleGlassButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.62),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
          ),
          child: Icon(icon, color: AppTheme.textDark, size: 22),
        ),
      ),
    );
  }
}

class _FeedbackOverlay extends StatelessWidget {
  final String? result;

  const _FeedbackOverlay({required this.result});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: result == null
              ? const SizedBox.shrink()
              : result == 'correct'
                  ? const _CelebrationEffect(key: ValueKey('correct'))
                  : const _WrongEffect(key: ValueKey('wrong')),
        ),
      ),
    );
  }
}

class _CelebrationEffect extends StatelessWidget {
  const _CelebrationEffect({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.success.withValues(alpha: 0.08),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.55, end: 1.12),
          duration: const Duration(milliseconds: 620),
          curve: Curves.elasticOut,
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: const Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Positioned(
                top: -54,
                child: Icon(Icons.auto_awesome_rounded,
                    color: AppTheme.accent, size: 50),
              ),
              Positioned(
                right: -74,
                child:
                    Icon(Icons.star_rounded, color: AppTheme.accent, size: 42),
              ),
              Positioned(
                left: -70,
                bottom: -24,
                child: Icon(Icons.celebration_rounded,
                    color: AppTheme.success, size: 46),
              ),
              Icon(Icons.emoji_events_rounded,
                  color: AppTheme.accent, size: 112),
            ],
          ),
        ),
      ),
    );
  }
}

class _WrongEffect extends StatelessWidget {
  const _WrongEffect({super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: -1, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.elasticIn,
      builder: (context, value, child) {
        final dx = value.isNegative ? value * 16 : (1 - value) * 16;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: Container(
        color: AppTheme.danger.withValues(alpha: 0.10),
        child: Center(
          child: Container(
            width: 138,
            height: 138,
            decoration: BoxDecoration(
              color: AppTheme.danger.withValues(alpha: 0.90),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.danger.withValues(alpha: 0.32),
                  blurRadius: 34,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: const Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 98,
            ),
          ),
        ),
      ),
    );
  }
}
