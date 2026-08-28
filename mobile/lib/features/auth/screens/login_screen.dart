import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../setup/screens/select_grade_screen.dart';
import '../providers/auth_provider.dart';

enum _AuthMode { login, register }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  _AuthMode _mode = _AuthMode.login;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(authProvider.notifier);
    final success = _mode == _AuthMode.login
        ? await notifier.login(
            _emailController.text.trim(),
            _passwordController.text,
          )
        : await notifier.register(
            _nameController.text.trim(),
            _emailController.text.trim(),
            _passwordController.text,
          );

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SelectGradeScreen()),
      );
    }
  }

  void _setMode(_AuthMode mode) {
    if (_mode == mode) return;
    setState(() => _mode = mode);
    _formKey.currentState?.reset();
    ref.read(authProvider.notifier).clearError();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isTablet = MediaQuery.of(context).size.width > 700;
    final isRegister = _mode == _AuthMode.register;

    return Scaffold(
      body: ChallengeBackground(
        safeArea: false,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isTablet ? 42 : 22),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isTablet ? 920 : 480),
                child: isTablet
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Expanded(child: _AuthHeroPanel()),
                          const SizedBox(width: 28),
                          Expanded(
                            child: _AuthFormCard(
                              authState: authState,
                              formKey: _formKey,
                              mode: _mode,
                              isRegister: isRegister,
                              nameController: _nameController,
                              emailController: _emailController,
                              passwordController: _passwordController,
                              confirmPasswordController:
                                  _confirmPasswordController,
                              obscurePassword: _obscurePassword,
                              obscureConfirmPassword: _obscureConfirmPassword,
                              onModeChanged: _setMode,
                              onSubmit: _submit,
                              onTogglePassword: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              onToggleConfirmPassword: () => setState(
                                () => _obscureConfirmPassword =
                                    !_obscureConfirmPassword,
                              ),
                            ),
                          ),
                        ],
                      )
                    : _AuthFormCard(
                        authState: authState,
                        formKey: _formKey,
                        mode: _mode,
                        isRegister: isRegister,
                        nameController: _nameController,
                        emailController: _emailController,
                        passwordController: _passwordController,
                        confirmPasswordController: _confirmPasswordController,
                        obscurePassword: _obscurePassword,
                        obscureConfirmPassword: _obscureConfirmPassword,
                        onModeChanged: _setMode,
                        onSubmit: _submit,
                        onTogglePassword: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        onToggleConfirmPassword: () => setState(
                          () => _obscureConfirmPassword =
                              !_obscureConfirmPassword,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthHeroPanel extends StatelessWidget {
  const _AuthHeroPanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const AppLogo(
            size: 58,
            padding: EdgeInsets.all(8),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'ساحة التنافس',
          style: TextStyle(
            fontFamily: 'Tajawal',
            color: AppTheme.textDark,
            fontSize: 36,
            fontWeight: FontWeight.w900,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'مساحة واحدة لاختيار الصفوف، إعداد الأسئلة، وتشغيل تحديات تفاعلية داخل الحصة.',
          style: TextStyle(
            fontFamily: 'Tajawal',
            color: AppTheme.textMuted,
            fontSize: 18,
            height: 1.6,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 24),
        const Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _HeroChip(
              icon: Icons.school_rounded,
              label: 'صفوف ودروس',
              color: AppTheme.cardGold,
            ),
            _HeroChip(
              icon: Icons.groups_2_rounded,
              label: 'فرق ونقاط',
              color: AppTheme.cardTeal,
            ),
            _HeroChip(
              icon: Icons.timer_rounded,
              label: 'مؤقت وتحديات',
              color: AppTheme.cardCoral,
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _HeroChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              color: AppTheme.textDark,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthFormCard extends StatelessWidget {
  final AuthState authState;
  final GlobalKey<FormState> formKey;
  final _AuthMode mode;
  final bool isRegister;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final ValueChanged<_AuthMode> onModeChanged;
  final VoidCallback onSubmit;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;

  const _AuthFormCard({
    required this.authState,
    required this.formKey,
    required this.mode,
    required this.isRegister,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.onModeChanged,
    required this.onSubmit,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.cardGold.withValues(alpha: 0.24),
                      ),
                    ),
                    child: const AppLogo(
                      size: 46,
                      padding: EdgeInsets.all(7),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isRegister ? 'إنشاء حساب جديد' : 'مرحباً بعودتك',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: AppTheme.primaryDark,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isRegister
                              ? 'أنشئ حساب معلم وابدأ بناء تحدياتك.'
                              : 'ادخل إلى لوحة المسابقة وابدأ تحدياً جديداً.',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textMuted,
                                    height: 1.35,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SegmentedButton<_AuthMode>(
                segments: const [
                  ButtonSegment(
                    value: _AuthMode.login,
                    icon: Icon(Icons.login_rounded),
                    label: Text('دخول'),
                  ),
                  ButtonSegment(
                    value: _AuthMode.register,
                    icon: Icon(Icons.person_add_alt_1_rounded),
                    label: Text('حساب جديد'),
                  ),
                ],
                selected: {mode},
                onSelectionChanged: authState.isLoading
                    ? null
                    : (value) => onModeChanged(value.first),
              ),
              const SizedBox(height: 22),
              if (authState.error != null) ...[
                _AuthError(message: authState.error!),
                const SizedBox(height: 16),
              ],
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: isRegister
                    ? Padding(
                        key: const ValueKey('name-field'),
                        padding: const EdgeInsets.only(bottom: 16),
                        child: TextFormField(
                          controller: nameController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'اسم المعلم',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          validator: (value) {
                            if (!isRegister) return null;
                            if (value == null || value.trim().isEmpty) {
                              return 'يرجى إدخال الاسم';
                            }
                            if (value.trim().length < 3) {
                              return 'الاسم قصير جداً';
                            }
                            return null;
                          },
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('empty-name-field')),
              ),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) return 'يرجى إدخال البريد الإلكتروني';
                  if (!email.contains('@') || !email.contains('.')) {
                    return 'البريد الإلكتروني غير صحيح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                obscureText: obscurePassword,
                textInputAction:
                    isRegister ? TextInputAction.next : TextInputAction.done,
                textDirection: TextDirection.ltr,
                onFieldSubmitted: (_) {
                  if (!isRegister && !authState.isLoading) onSubmit();
                },
                decoration: InputDecoration(
                  labelText: 'كلمة المرور',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: onTogglePassword,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'يرجى إدخال كلمة المرور';
                  }
                  if (isRegister && value.length < 8) {
                    return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
                  }
                  return null;
                },
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: isRegister
                    ? Padding(
                        key: const ValueKey('confirm-field'),
                        padding: const EdgeInsets.only(top: 16),
                        child: TextFormField(
                          controller: confirmPasswordController,
                          obscureText: obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
                          textDirection: TextDirection.ltr,
                          onFieldSubmitted: (_) {
                            if (!authState.isLoading) onSubmit();
                          },
                          decoration: InputDecoration(
                            labelText: 'تأكيد كلمة المرور',
                            prefixIcon:
                                const Icon(Icons.verified_user_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscureConfirmPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: onToggleConfirmPassword,
                            ),
                          ),
                          validator: (value) {
                            if (!isRegister) return null;
                            if (value == null || value.isEmpty) {
                              return 'يرجى تأكيد كلمة المرور';
                            }
                            if (value != passwordController.text) {
                              return 'كلمة المرور غير متطابقة';
                            }
                            return null;
                          },
                        ),
                      )
                    : const SizedBox.shrink(
                        key: ValueKey('empty-confirm-field'),
                      ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: authState.isLoading ? null : onSubmit,
                  icon: authState.isLoading
                      ? const SizedBox(
                          width: 23,
                          height: 23,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          isRegister
                              ? Icons.person_add_alt_1_rounded
                              : Icons.login_rounded,
                        ),
                  label: Text(
                    authState.isLoading
                        ? 'جارٍ المعالجة...'
                        : isRegister
                            ? 'إنشاء الحساب'
                            : 'تسجيل الدخول',
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

class _AuthError extends StatelessWidget {
  final String message;

  const _AuthError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.danger, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppTheme.danger,
                fontFamily: 'Tajawal',
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
