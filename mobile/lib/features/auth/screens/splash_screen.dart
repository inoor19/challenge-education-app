import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../setup/screens/select_grade_screen.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  static const onboardingCompletedKey = 'onboarding_completed';

  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  final _pageController = PageController();

  bool _isChecking = true;
  bool _showOnboarding = false;
  int _currentPage = 0;

  static const _pages = [
    _OnboardingPageData(
      icon: Icons.emoji_events_rounded,
      title: 'حوّل الدرس إلى منافسة حية',
      description:
          'ابنِ تحديات صفية سريعة، وحرّك الحماس بين الفرق بنقاط وأسئلة واضحة.',
      accent: AppTheme.cardGold,
    ),
    _OnboardingPageData(
      icon: Icons.dashboard_customize_rounded,
      title: 'نظّم محتواك بطريقتك',
      description:
          'اختر الصف والمادة والدروس، أو أضف محتوى خاصاً يناسب خطتك التعليمية.',
      accent: AppTheme.cardTeal,
    ),
    _OnboardingPageData(
      icon: Icons.groups_3_rounded,
      title: 'ابدأ الساحة خلال دقائق',
      description:
          'قسّم الطلاب إلى فرق، شغّل المؤقت، وابدأ جولة تفاعلية منضبطة.',
      accent: AppTheme.cardCoral,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.96, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
    _prepareStartup();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _prepareStartup() async {
    final prefs = await SharedPreferences.getInstance();
    final completed =
        prefs.getBool(SplashScreen.onboardingCompletedKey) ?? false;

    if (!mounted) return;
    if (!completed) {
      setState(() {
        _showOnboarding = true;
        _isChecking = false;
      });
      return;
    }

    await _checkAuth();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SplashScreen.onboardingCompletedKey, true);
    if (!mounted) return;

    setState(() {
      _showOnboarding = false;
      _isChecking = true;
    });
    await _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    final isLoggedIn = await ref.read(authProvider.notifier).tryAutoLogin();

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            isLoggedIn ? const SelectGradeScreen() : const LoginScreen(),
      ),
    );
  }

  void _goNext() {
    if (_currentPage == _pages.length - 1) {
      _completeOnboarding();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ChallengeBackground(
        safeArea: false,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: _showOnboarding ? _buildOnboarding(context) : _buildLoader(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoader() {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 118,
              height: 118,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: AppTheme.accent,
                size: 62,
              ),
            ),
            const SizedBox(height: 26),
            const Text(
              'ساحة التحدي التعليمي',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 29,
                fontWeight: FontWeight.w900,
                color: AppTheme.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _isChecking ? 'نجهّز الساحة...' : 'تعلم، تنافس، وارفع النقاط',
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 42),
            const SizedBox(
              width: 38,
              height: 38,
              child: CircularProgressIndicator(
                color: AppTheme.primary,
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboarding(BuildContext context) {
    final isLast = _currentPage == _pages.length - 1;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
        child: Column(
          children: [
            Row(
              children: [
                const _BrandMark(),
                const Spacer(),
                TextButton(
                  onPressed: _completeOnboarding,
                  style:
                      TextButton.styleFrom(foregroundColor: AppTheme.primary),
                  child: const Text('تخطي'),
                ),
              ],
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) => _OnboardingSlide(
                  data: _pages[index],
                ),
              ),
            ),
            Row(
              children: [
                Row(
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsetsDirectional.only(end: 7),
                      width: index == _currentPage ? 28 : 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: 0,
                        ),
                        border: Border.all(
                          color: index == _currentPage
                              ? AppTheme.primary
                              : AppTheme.border,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _goNext,
                    icon: Icon(
                      isLast
                          ? Icons.play_arrow_rounded
                          : Icons.arrow_back_rounded,
                    ),
                    label: Text(isLast ? 'ابدأ الآن' : 'التالي'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(150, 52),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.border),
          ),
          child: const Icon(
            Icons.emoji_events_rounded,
            color: AppTheme.accent,
            size: 24,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'ساحة التحدي',
          style: TextStyle(
            fontFamily: 'Tajawal',
            color: AppTheme.textDark,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  final _OnboardingPageData data;

  const _OnboardingSlide({required this.data});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 620;

    return LayoutBuilder(
      builder: (context, constraints) {
        final visualSize = constraints.maxHeight < 500
            ? (isTablet ? 220.0 : 184.0)
            : (isTablet ? 250.0 : 210.0);
        final innerSize = visualSize * 0.67;
        final iconSize = visualSize * 0.42;

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isTablet ? 620 : 430),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: visualSize,
                      height: visualSize,
                      decoration: BoxDecoration(
                        color: data.accent == AppTheme.cardCoral
                            ? AppTheme.surface
                            : AppTheme.surfaceAlt,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: innerSize,
                            height: innerSize,
                            decoration: BoxDecoration(
                              color: AppTheme.iconSurface(data.accent),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppTheme.iconBorder(data.accent),
                              ),
                            ),
                          ),
                          Icon(data.icon, color: data.accent, size: iconSize),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      data.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        color: AppTheme.textDark,
                        fontSize: isTablet ? 34 : 28,
                        height: 1.18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      data.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        color: AppTheme.textMuted,
                        fontSize: isTablet ? 18 : 16,
                        height: 1.55,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OnboardingPageData {
  final IconData icon;
  final String title;
  final String description;
  final Color accent;

  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.description,
    required this.accent,
  });
}
