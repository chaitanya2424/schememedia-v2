import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/local/onboarding_repository.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/eyebrow_label.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/widgets/language_toggle_button.dart';
import '../../../../core/widgets/responsive.dart';

class _StepData {
  const _StepData({
    required this.eyebrow,
    required this.headline,
    required this.body,
    required this.illustrationType,
    required this.eyebrowHi,
    required this.headlineHi,
    required this.bodyHi,
  });

  final String eyebrow;
  final String headline;
  final String body;
  final int illustrationType;
  final String eyebrowHi;
  final String headlineHi;
  final String bodyHi;
}

/// Modernized Onboarding experience with interactive Gov-Tech visual cards,
/// citizen value propositions, animated step indicator pills, and DPDP compliance assurance.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  static const _steps = [
    _StepData(
      eyebrow: 'A little context, a better match',
      headline: 'A calmer way to find support',
      body:
          'SchemeMedia turns hundreds of complex government schemes into a clear, personalized starting point tailored to you.',
      illustrationType: 0,
      eyebrowHi: 'थोड़ी जानकारी, बेहतर योजना मिलान',
      headlineHi: 'सरकारी सहायता पाने का आसान तरीका',
      bodyHi: 'स्कीम मीडिया सैकड़ों जटिल सरकारी योजनाओं को आपके लिए एक स्पष्ट, व्यक्तिगत और पारदर्शी सूची में बदलता है।',
    ),
    _StepData(
      eyebrow: 'Honest by default',
      headline: 'We show our work',
      body:
          'Every scheme is marked source-provided or officially verified with direct gazette links -- no middlemen, zero guesswork.',
      illustrationType: 1,
      eyebrowHi: 'सत्यापित व पारदर्शी',
      headlineHi: 'हम स्रोत दिखाते हैं',
      bodyHi: 'प्रत्येक योजना आधिकारिक पोर्टल या राजपत्र से सीधे सत्यापित होती है -- कोई बिचौलिया नहीं, कोई भ्रामक दावा नहीं।',
    ),
    _StepData(
      eyebrow: "When you're stuck",
      headline: 'Ask in your own words',
      body:
          "Our AI assistant answers using verified government data and transparently tells you what it knows and doesn't know.",
      illustrationType: 2,
      eyebrowHi: 'जब भी कोई संशय हो',
      headlineHi: 'अपनी भाषा में पूछें',
      bodyHi: 'हमारा एआई सहायक सत्यापित सरकारी डेटा का उपयोग करके उत्तर देता है और नियमों की स्पष्ट जानकारी देता है।',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    ref.read(hasSeenOnboardingProvider.notifier).markSeen();
    context.go(AppRoutes.home);
  }

  void _next() {
    if (_index == _steps.length - 1) {
      _finish();
      return;
    }
    _controller.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    final lang = ref.watch(languageProvider);
    final isHindi = lang == AppLanguage.hindi;
    final strings = AppStrings(lang);

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colors.brand,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: const Icon(Icons.account_balance, color: Colors.white, size: 16),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Text(
              'SchemeMedia',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        actions: [
          const LanguageToggleButton(),
          const SizedBox(width: AppSpacing.xs),
          TextButton(
            onPressed: _finish,
            child: Text(
              strings.skip,
              style: TextStyle(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 520,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _steps.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) => _StepSlide(step: _steps[i]),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // Smooth Animated Indicator Pills
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_steps.length, (i) {
                    final isActive = i == _index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: isActive ? 28 : 8,
                      decoration: BoxDecoration(
                        color: isActive ? colors.brand : colors.brand.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: AppSpacing.xl),
                // Action Buttons
                FilledButton(
                  onPressed: _next,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.brand,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    elevation: 1,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _index == _steps.length - 1 ? strings.getStarted : strings.continueText,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // Trust Strip
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified_user_outlined, size: 14, color: colors.textSecondary),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      isHindi
                          ? 'आधिकारिक नागरिक कल्याण • DPDP अधिनियम 2023 के अनुरूप'
                          : 'Official Citizen Welfare • DPDP Act 2023 Compliant',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepSlide extends ConsumerWidget {
  const _StepSlide({required this.step});

  final _StepData step;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final isHindi = ref.watch(languageProvider) == AppLanguage.hindi;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: AppSpacing.md),
          // Rich Visual Graphic Card
          _IllustrationCard(type: step.illustrationType),
          const SizedBox(height: AppSpacing.xl),
          EyebrowLabel(isHindi ? step.eyebrowHi : step.eyebrow),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isHindi ? step.headlineHi : step.headline,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              isHindi ? step.bodyHi : step.body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _IllustrationCard extends StatelessWidget {
  const _IllustrationCard({required this.type});

  final int type;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.brandTint,
            colors.brandTint.withValues(alpha: 0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: colors.brand.withValues(alpha: 0.12),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background subtle circles
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.brand.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -20,
              left: -20,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.brand.withValues(alpha: 0.05),
                ),
              ),
            ),
            // Card Content based on step
            if (type == 0) _MatchingIllustration(colors: colors),
            if (type == 1) _VerificationIllustration(colors: colors),
            if (type == 2) _AssistantIllustration(colors: colors),
          ],
        ),
      ),
    );
  }
}

class _MatchingIllustration extends StatelessWidget {
  const _MatchingIllustration({required this.colors});

  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pillBg = isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFF0FDF4);
    final pillBorder = isDark ? const Color(0xFF059669).withValues(alpha: 0.45) : const Color(0xFF86EFAC);
    final pillTextColor = isDark ? const Color(0xFF6EE7B7) : const Color(0xFF15803D);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: pillBg,
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              border: Border.all(color: pillBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.currency_rupee_rounded, size: 16, color: pillTextColor),
                const SizedBox(width: 4),
                Text(
                  '₹6,000 / year • Guaranteed Support',
                  style: TextStyle(
                    color: pillTextColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: colors.divider),
              boxShadow: [
                BoxShadow(
                  color: colors.brand.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF065F46) : const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(
                    Icons.agriculture_rounded,
                    color: isDark ? const Color(0xFF34D399) : const Color(0xFF2E7D32),
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'PM-Kisan Samman Nidhi',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Central Sector • Direct Bank Transfer',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF065F46).withValues(alpha: 0.4) : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                  child: Text(
                    '98% Match',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF059669),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationIllustration extends StatelessWidget {
  const _VerificationIllustration({required this.colors});

  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final badgeColor = isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E3A8A);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: colors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: colors.divider),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF059669).withValues(alpha: 0.15),
                blurRadius: 14,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.verified_rounded,
              color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
              size: 38,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            border: Border.all(color: colors.divider),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shield_outlined, size: 14, color: badgeColor),
              const SizedBox(width: 6),
              Text(
                '100% Verified from Ministry Gazettes',
                style: TextStyle(
                  color: badgeColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AssistantIllustration extends StatelessWidget {
  const _AssistantIllustration({required this.colors});

  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.brand,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
              child: const Text(
                'Am I eligible for solar pump subsidy?',
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
                border: Border.all(color: colors.divider),
                boxShadow: [
                  BoxShadow(
                    color: colors.brand.withValues(alpha: 0.08),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 14,
                    color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Yes, PM-KUSUM provides up to 60% grant.',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
