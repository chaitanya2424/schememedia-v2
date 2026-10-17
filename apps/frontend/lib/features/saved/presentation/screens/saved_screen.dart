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
class SavedScreen extends ConsumerStatefulWidget {
  const SavedScreen({super.key});

  @override
  ConsumerState<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends ConsumerState<SavedScreen> {
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(savedSchemesProvider).values.toList();
    final categories = saved.map((s) => s.category).whereType<String>().toSet().toList()..sort();

    final filtered = _selectedCategory == null
        ? saved
        : saved.where((s) => s.category == _selectedCategory).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Schemes', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const EyebrowLabel('SAVED SHORTLIST'),
                const SizedBox(height: AppSpacing.xs),
                Text('Saved for later.', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Keep a quiet shortlist while you gather documents or talk it through.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                if (saved.isEmpty)
                  Column(
                    children: [
                      const EmptyState(
                        icon: Icons.bookmark_outline_rounded,
                        title: "You haven't saved any schemes yet.",
                        subtitle: 'Tap the bookmark on any scheme to keep it here.',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      FilledButton.icon(
                        onPressed: () => context.go(AppRoutes.search),
                        icon: const Icon(Icons.explore_outlined),
                        label: const Text('Explore all schemes'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  )
                else ...[
                  AppCard(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: const Icon(Icons.bookmark_rounded, color: Color(0xFF1E3A8A), size: 24),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${saved.length} scheme${saved.length == 1 ? '' : 's'} saved',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
                  if (categories.length > 1) ...[
                    const SizedBox(height: AppSpacing.md),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: Text('All (${saved.length})'),
                            selected: _selectedCategory == null,
                            onSelected: (_) => setState(() => _selectedCategory = null),
                            selectedColor: const Color(0xFF1E3A8A),
                            labelStyle: TextStyle(
                              color: _selectedCategory == null ? Colors.white : null,
                              fontWeight: FontWeight.w600,
                            ),
                            showCheckmark: false,
                          ),
                          for (final cat in categories)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: ChoiceChip(
                                label: Text(cat),
                                selected: _selectedCategory == cat,
                                onSelected: (_) => setState(() => _selectedCategory = cat),
                                selectedColor: const Color(0xFF1E3A8A),
                                labelStyle: TextStyle(
                                  color: _selectedCategory == cat ? Colors.white : null,
                                  fontWeight: FontWeight.w600,
                                ),
                                showCheckmark: false,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  for (final scheme in filtered)
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
