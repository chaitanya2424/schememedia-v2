import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/local/onboarding_repository.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/eyebrow_label.dart';
import '../../../../core/widgets/responsive.dart';

class _Step {
  const _Step({required this.icon, required this.eyebrow, required this.headline, required this.body});

  final IconData icon;
  final String eyebrow;
  final String headline;
  final String body;
}

/// Shown once per device (real, local `shared_preferences` flag -- see
/// `hasSeenOnboardingProvider`). Step 1's copy is transcribed exactly
/// from the reference mockup; steps 2-3 are original copy in the same
/// voice, covering the two things the redesign plan's Onboarding section
/// already scoped (the verification/honesty principle, and the
/// assistant) -- there was nothing to transcribe for those, only step 1
/// was shown.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  static const _steps = [
    _Step(
      icon: Icons.auto_awesome,
      eyebrow: 'A little context, a better match',
      headline: 'A calmer way to find support',
      body: 'SchemeMedia turns a long list of government schemes into a clear, personal starting point.',
    ),
    _Step(
      icon: Icons.verified_outlined,
      eyebrow: 'Honest by default',
      headline: 'We show our work',
      body:
          'Every scheme is marked unverified, source-provided, or officially verified -- so you always '
          'know how much to trust it.',
    ),
    _Step(
      icon: Icons.chat_bubble_outline,
      eyebrow: "When you're stuck",
      headline: 'Ask in your own words',
      body:
          "The assistant answers using real scheme data, and tells you when it doesn't know something "
          'rather than guessing.',
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
    _controller.nextPage(duration: AppSpacing.durationMedium, curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('SchemeMedia'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Center(
              child: Text('1 minute setup', style: theme.textTheme.bodySmall),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 480,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _steps.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) => _StepView(step: _steps[i]),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        child: LinearProgressIndicator(
                          value: (_index + 1) / _steps.length,
                          minHeight: 4,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text('${_index + 1} of ${_steps.length}', style: theme.textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: _next,
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(_index == _steps.length - 1 ? 'Get started' : 'Continue'),
                ),
                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: TextButton(onPressed: _finish, child: const Text('Skip for now')),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check, size: AppSpacing.iconSm, color: theme.colorScheme.outline),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'No spam. No promises. Just clearer next steps.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepView extends StatelessWidget {
  const _StepView({required this.step});

  final _Step step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: colors.brandTint,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Icon(step.icon, color: colors.brand, size: AppSpacing.iconLg),
        ),
        const SizedBox(height: AppSpacing.xl),
        EyebrowLabel(step.eyebrow),
        const SizedBox(height: AppSpacing.xs),
        Text(step.headline, style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.sm),
        Text(step.body, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}
