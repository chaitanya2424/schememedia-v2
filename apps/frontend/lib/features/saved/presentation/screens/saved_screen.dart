import 'package:flutter/material.dart';

import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/responsive.dart';

/// Placeholder for the nav shell (phase 2 of the redesign) -- the real
/// local-device-backed saved-schemes list lands in a later phase (see the
/// redesign plan's Phase A/B capability table: saved schemes are real,
/// on-device persistence, not backend-linked yet).
class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved')),
      body: const SafeArea(
        child: ResponsiveContainer(
          child: Center(
            child: EmptyState(
              icon: Icons.bookmark_outline,
              title: 'Saved schemes are coming here soon.',
              subtitle: 'You\'ll be able to keep a shortlist on this device.',
            ),
          ),
        ),
      ),
    );
  }
}
