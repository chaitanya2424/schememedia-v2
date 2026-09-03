import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/local/saved_schemes_repository.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/eyebrow_label.dart';
import '../../../../core/widgets/responsive.dart';
import '../../../../core/widgets/scheme_card.dart';

/// Real, on-device saved schemes -- see the redesign plan's Phase A/B
/// capability table: genuine persistence across app restarts (backed by
/// `savedSchemesProvider`/`shared_preferences`), explicitly labeled as
/// device-local since there's no account to sync it to yet. No
/// eligibility pill on these cards: eligibility is a moment-in-time
/// computation against whatever profile existed when the scheme was
/// saved, and would silently go stale as the profile changes -- omitted
/// rather than shown as if still current.
class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedSchemesProvider).values.toList();
    final categories = saved.map((s) => s.category).whereType<String>().toSet();

    return Scaffold(
      appBar: AppBar(title: const Text('Saved')),
      body: SafeArea(
        child: ResponsiveContainer(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const EyebrowLabel('Your collection'),
                const SizedBox(height: AppSpacing.xs),
                Text('Saved for later.', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Keep a quiet shortlist while you gather documents or talk it through.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                if (saved.isEmpty)
                  EmptyState(
                    icon: Icons.bookmark_outline,
                    title: "You haven't saved any schemes yet.",
                    subtitle: 'Tap the bookmark on any scheme to keep it here.',
                  )
                else ...[
                  AppCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${saved.length} scheme${saved.length == 1 ? '' : 's'} saved',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                categories.isEmpty
                                    ? 'Saved on this device'
                                    : 'Across ${categories.length} categor${categories.length == 1 ? 'y' : 'ies'} · saved on this device',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(color: context.colors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  for (final scheme in saved)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: SchemeCard(
                        schemeId: scheme.schemeId,
                        name: scheme.name,
                        category: scheme.category,
                        description: scheme.description,
                        verificationStatus: scheme.verificationStatus,
                        needsReview: scheme.needsReview,
                        onTap: () => context.push(AppRoutes.schemeDetailPath(scheme.schemeId)),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
