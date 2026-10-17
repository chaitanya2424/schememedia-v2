import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/enums.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/widgets/scheme_card.dart';
import '../../domain/scheme_summary.dart';

/// Maps a plain search result onto the shared [SchemeCard] -- no
/// `eligibilityState` (Explore's results are never eligibility-aware,
/// matching what `SearchResultOut` actually returns) and no benefit
/// highlight (`SchemeSummary` carries no benefit data; see SchemeCard's
/// own doc comment on why that's not faked here).
class SchemeResultCard extends ConsumerWidget {
  const SchemeResultCard({super.key, required this.scheme, required this.onTap});

  final SchemeSummary scheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final jurisdictionLabel = switch (scheme.jurisdiction) {
      Jurisdiction.central => strings.centralGov,
      Jurisdiction.state =>
        scheme.stateCode != null ? strings.stateWithCode(scheme.stateCode!) : strings.stateGov,
      Jurisdiction.unrecognized => null,
    };

    return SchemeCard(
      schemeId: scheme.schemeId,
      name: scheme.name,
      category: scheme.category,
      metaSuffix: jurisdictionLabel,
      description: scheme.descriptionShort,
      verificationStatus: scheme.verificationStatus,
      needsReview: scheme.needsReview,
      onTap: onTap,
    );
  }
}

