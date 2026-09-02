import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/eyebrow_label.dart';
import '../../../../core/widgets/responsive.dart';

/// Built pixel-for-pixel against the reference mockup, but "Continue
/// securely" is deliberately inert: there is no backend auth endpoint to
/// call (no signup/login/session-token routes exist in the API today).
/// Tapping it says so plainly rather than faking a sent OTP or a
/// successful sign-in -- see the redesign plan's Phase A/B capability
/// table.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _showNotAvailable(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Accounts aren't available yet -- this screen is a preview of what's coming."),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(
        title: const Text('SchemeMedia'),
        actions: [
          TextButton(onPressed: () => _showNotAvailable(context), child: const Text('Need help?')),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 480,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xl),
                const EyebrowLabel('Welcome back'),
                const SizedBox(height: AppSpacing.xs),
                Text('Pick up where you left off.', style: theme.textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Sign in to keep your profile, saved schemes and recommendations together.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xl),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Mobile number',
                        style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.phone_outlined),
                          prefixText: '+91  ',
                          hintText: '98765 43210',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton.icon(
                        onPressed: () => _showNotAvailable(context),
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Continue securely'),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Center(
                        child: Text(
                          "We'll use a one-time code. No password to remember.",
                          style: theme.textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F5EC),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.shield_outlined, color: Color(0xFF2E7D32)),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Private profile',
                              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              'Your saved schemes and answers are yours alone.',
                              style: theme.textTheme.bodySmall,
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
                    Text('Protected with secure sign-in', style: theme.textTheme.bodySmall),
                    const SizedBox(width: AppSpacing.xs),
                    Icon(Icons.check, size: AppSpacing.iconSm, color: colors.textSecondary),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  "By continuing, you agree to SchemeMedia's terms and privacy note.",
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
