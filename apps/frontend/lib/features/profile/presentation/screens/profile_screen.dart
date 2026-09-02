import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/responsive.dart';

/// Placeholder for the nav shell (phase 2 of the redesign) -- the real
/// signed-out Profile experience (preferences, saved-schemes shortcut,
/// inert sign-in CTA) lands in a later phase. Never a fabricated signed-in
/// state -- see the redesign plan's Phase A/B capability table: accounts
/// require backend work not yet done.
///
/// The Sign in button below is real navigation (to [LoginScreen], phase 4)
/// even though this screen's own layout is still a placeholder.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: ResponsiveContainer(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const EmptyState(
                    icon: Icons.person_outline,
                    title: 'Your profile is coming here soon.',
                    subtitle: 'Preferences and account sign-in will live here.',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  OutlinedButton(
                    onPressed: () => context.push(AppRoutes.login),
                    child: const Text('Sign in'),
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
