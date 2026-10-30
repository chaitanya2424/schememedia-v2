import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/eyebrow_label.dart';
import '../../../../core/widgets/language_toggle_button.dart';
import '../../../../core/widgets/responsive.dart';
import '../providers/auth_controller.dart';

enum _AuthMode { signIn, signUp }

/// Modernized Citizen Authentication Gateway for SchemeMedia.
/// Follows modern Gov-Tech visual language with high contrast, trust indicators,
/// DPDP Act 2023 privacy banner, and seamless mode switching.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  _AuthMode _mode = _AuthMode.signIn;
  bool _submitting = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      final auth = ref.read(authControllerProvider.notifier);
      if (_mode == _AuthMode.signIn) {
        await auth.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        final name = _nameController.text.trim();
        await auth.register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: name.isEmpty ? null : name,
        );
      }
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.home);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = _messageFor(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _messageFor(Object error) {
    if (error is ApiException) {
      return switch (error) {
        ApiNetworkException() => 'No connection. Check your network and try again.',
        ApiValidationException() => 'Please check the details below.',
        ApiNotFoundException(:final message) => message,
        ApiUnavailableException(:final message) => message,
        ApiServerException(:final message) => message,
        ApiUnknownException(:final message) => message,
      };
    }
    return 'Something went wrong. Please try again.';
  }

  void _switchMode(_AuthMode mode) {
    setState(() {
      _mode = mode;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final isSignIn = _mode == _AuthMode.signIn;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: Image.asset(
                'assets/images/app_logo.png',
                width: 24,
                height: 24,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Text(
              'SchemeMedia',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: AppSpacing.md),
            child: LanguageToggleButton(),
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 480,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.md),
                  // Citizen Portal Badge
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colors.brandTint,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                        border: Border.all(
                          color: colors.brand.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield_outlined, size: 14, color: colors.brand),
                          const SizedBox(width: 6),
                          Text(
                            ref.watch(languageProvider) == AppLanguage.hindi
                                ? 'राष्ट्रीय नागरिक पोर्टल प्रमाणीकरण'
                                : 'National Citizen Portal Auth',
                            style: TextStyle(
                              color: colors.brand,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  EyebrowLabel(
                    isSignIn
                        ? (ref.watch(languageProvider) == AppLanguage.hindi ? 'पुनः स्वागत है' : 'Welcome back')
                        : (ref.watch(languageProvider) == AppLanguage.hindi ? 'शुरू करें' : 'Get started'),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    isSignIn
                        ? (ref.watch(languageProvider) == AppLanguage.hindi
                            ? 'जहां छोड़ा था, वहीं से शुरू करें।'
                            : 'Pick up where you left off.')
                        : (ref.watch(languageProvider) == AppLanguage.hindi
                            ? 'अपना खाता बनाएं।'
                            : 'Create your account.'),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    isSignIn
                        ? (ref.watch(languageProvider) == AppLanguage.hindi
                            ? 'अपनी प्रोफ़ाइल, सहेजी गई योजनाएं और सिफारिशें एक साथ रखने के लिए साइन इन करें।'
                            : 'Sign in to keep your profile, saved schemes and recommendations together.')
                        : (ref.watch(languageProvider) == AppLanguage.hindi
                            ? 'एक खाता आपकी प्रोफ़ाइल, सहेजी गई योजनाएं और सिफारिशें सुरक्षित रखता है।'
                            : 'One account keeps your profile, saved schemes and recommendations in sync.'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  // Segmented Mode Selector
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colors.brandTint.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: colors.brand.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _submitting ? null : () => _switchMode(_AuthMode.signIn),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSignIn ? colors.surface : Colors.transparent,
                                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                boxShadow: isSignIn
                                    ? [
                                        BoxShadow(
                                          color: colors.shadow.withValues(alpha: 0.08),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                ref.watch(languageProvider) == AppLanguage.hindi ? 'साइन इन' : 'Sign In',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: isSignIn ? FontWeight.w800 : FontWeight.w600,
                                  color: isSignIn ? colors.brand : colors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: _submitting ? null : () => _switchMode(_AuthMode.signUp),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !isSignIn ? colors.surface : Colors.transparent,
                                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                boxShadow: !isSignIn
                                    ? [
                                        BoxShadow(
                                          color: colors.shadow.withValues(alpha: 0.08),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                ref.watch(languageProvider) == AppLanguage.hindi ? 'खाता बनाएं' : 'Create Account',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: !isSignIn ? FontWeight.w800 : FontWeight.w600,
                                  color: !isSignIn ? colors.brand : colors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Form Fields Card
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!isSignIn) ...[
                          _FieldLabel('Full name (optional)'),
                          const SizedBox(height: AppSpacing.sm),
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.person_outline, color: colors.brand),
                              hintText: 'Your name',
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        _FieldLabel('Email'),
                        const SizedBox(height: AppSpacing.sm),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.mail_outline, color: colors.brand),
                            hintText: 'you@example.com',
                          ),
                          validator: (value) {
                            final trimmed = value?.trim() ?? '';
                            if (trimmed.isEmpty) return 'Enter your email.';
                            if (!trimmed.contains('@') || !trimmed.contains('.')) {
                              return 'Enter a valid email.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _FieldLabel('Password'),
                        const SizedBox(height: AppSpacing.sm),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          autofillHints: [
                            isSignIn ? AutofillHints.password : AutofillHints.newPassword,
                          ],
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.lock_outline, color: colors.brand),
                            hintText: isSignIn ? 'Your password' : 'At least 8 characters',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: colors.textSecondary,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (value) {
                            final v = value ?? '';
                            if (v.isEmpty) return 'Enter your password.';
                            if (!isSignIn && v.length < 8) {
                              return 'Use at least 8 characters.';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => _submit(),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: AppSpacing.iconSm,
                                  color: theme.colorScheme.onErrorContainer,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onErrorContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        FilledButton(
                          onPressed: _submitting ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.primaryAction,
                            foregroundColor: colors.onPrimaryAction,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            ),
                          ),
                          child: _submitting
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colors.onPrimaryAction,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      isSignIn ? 'Sign in' : 'Create account',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    const Icon(Icons.arrow_forward_rounded, size: 18),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // DPDP Act Compliance Card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.verified_user_rounded,
                          color: Color(0xFF16A34A),
                          size: 22,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ref.watch(languageProvider) == AppLanguage.hindi
                                    ? 'गोपनीय व DPDP अधिनियम 2023 के अनुरूप'
                                    : 'Private & DPDP Act 2023 Compliant',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF15803D),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                ref.watch(languageProvider) == AppLanguage.hindi
                                    ? 'आपकी सहेजी गई योजनाएं और उत्तर सुरक्षित रखे जाते हैं और किसी भी तीसरे पक्ष के साथ साझा नहीं किए जाते हैं।'
                                    : 'Your saved schemes and answers are stored securely and never shared with third parties.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF166534),
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline, size: AppSpacing.iconSm, color: colors.textSecondary),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'End-to-end encrypted session',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    "By continuing, you agree to SchemeMedia's public terms and citizen privacy note.",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}
