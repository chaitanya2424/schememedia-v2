import 'package:flutter/material.dart';

import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/responsive.dart';

/// Placeholder for the nav shell (phase 2 of the redesign) -- the real
/// signed-out Profile experience (preferences, saved-schemes shortcut,
/// inert sign-in CTA) lands in a later phase. Never a fabricated signed-in
/// state -- see the redesign plan's Phase A/B capability table: accounts
/// require backend work not yet done.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const SafeArea(
        child: ResponsiveContainer(
          child: Center(
            child: EmptyState(
              icon: Icons.person_outline,
              title: 'Your profile is coming here soon.',
              subtitle: 'Preferences and account sign-in will live here.',
            ),
          ),
        ),
      ),
    );
  }
}
