import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/local/saved_schemes_repository.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/eyebrow_label.dart';
import '../../../../core/widgets/language_toggle_button.dart';
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
    final strings = ref.watch(stringsProvider);
    final categories = saved.map((s) => s.category).whereType<String>().toSet().toList()..sort();

    final filtered = _selectedCategory == null
        ? saved
        : saved.where((s) => s.category == _selectedCategory).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          strings.isHindi ? 'सहेजी गई योजनाएं' : 'Saved Schemes',
          style: const TextStyle(fontWeight: FontWeight.w700),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EyebrowLabel(strings.isHindi ? 'सहेजी गई सूची' : 'SAVED SHORTLIST'),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  strings.isHindi ? 'भविष्य के लिए सहेजी गई योजनाएं' : 'Saved for later.',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  strings.isHindi
                      ? 'दस्तावेज एकत्र करते समय अपनी पसंदीदा योजनाओं की सूची यहां रखें।'
                      : 'Keep a quiet shortlist while you gather documents or talk it through.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                if (saved.isEmpty)
                  Column(
                    children: [
                      EmptyState(
                        icon: Icons.bookmark_outline_rounded,
                        title: strings.isHindi
                            ? 'आपने अभी तक कोई योजना नहीं सहेजी है।'
                            : "You haven't saved any schemes yet.",
                        subtitle: strings.isHindi
                            ? 'किसी भी योजना पर बुकमार्क आइकन दबाकर उसे यहां सहेजें।'
                            : 'Tap the bookmark on any scheme to keep it here.',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      FilledButton.icon(
                        onPressed: () => context.go(AppRoutes.search),
                        icon: const Icon(Icons.explore_outlined),
                        label: Text(strings.isHindi ? 'सभी योजनाएं देखें' : 'Explore all schemes'),
                        style: FilledButton.styleFrom(
                          backgroundColor: context.colors.primaryAction,
                          foregroundColor: context.colors.onPrimaryAction,
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
                            color: context.colors.brandTint,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: Icon(Icons.bookmark_rounded, color: context.colors.brand, size: 24),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                strings.isHindi
                                    ? '${saved.length} योजनाएं सहेजी गईं'
                                    : '${saved.length} scheme${saved.length == 1 ? '' : 's'} saved',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                categories.isEmpty
                                    ? (strings.isHindi ? 'इस डिवाइस पर सहेजा गया' : 'Saved on this device')
                                    : (strings.isHindi
                                        ? '${categories.length} श्रेणियों में · इस डिवाइस पर सहेजा गया'
                                        : 'Across ${categories.length} categor${categories.length == 1 ? 'y' : 'ies'} · saved on this device'),
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
                            label: Text(
                              strings.isHindi ? 'सभी (${saved.length})' : 'All (${saved.length})',
                            ),
                            selected: _selectedCategory == null,
                            onSelected: (_) => setState(() => _selectedCategory = null),
                            backgroundColor: context.colors.surfaceMuted,
                            selectedColor: context.colors.primaryAction,
                            labelStyle: TextStyle(
                              color: _selectedCategory == null ? context.colors.onPrimaryAction : context.colors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            showCheckmark: false,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                              side: BorderSide(
                                color: _selectedCategory == null ? context.colors.primaryAction : context.colors.divider,
                              ),
                            ),
                          ),
                          for (final cat in categories)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: ChoiceChip(
                                label: Text(strings.categoryName(cat)),
                                selected: _selectedCategory == cat,
                                onSelected: (_) => setState(() => _selectedCategory = cat),
                                backgroundColor: context.colors.surfaceMuted,
                                selectedColor: context.colors.primaryAction,
                                labelStyle: TextStyle(
                                  color: _selectedCategory == cat ? context.colors.onPrimaryAction : context.colors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                                showCheckmark: false,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                                  side: BorderSide(
                                    color: _selectedCategory == cat ? context.colors.primaryAction : context.colors.divider,
                                  ),
                                ),
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
