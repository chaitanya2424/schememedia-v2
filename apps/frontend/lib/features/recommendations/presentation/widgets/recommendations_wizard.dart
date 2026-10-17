import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/eyebrow_label.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/eligibility_attribute.dart';
import '../../domain/indian_states.dart';
import '../providers/profile_form_provider.dart';
import '../providers/recommendations_providers.dart';
import 'digilocker_dialog.dart';
import 'document_scanner_dialog.dart';

sealed class _Page {
  const _Page();
}

class _QueryPage extends _Page {
  const _QueryPage();
}

class _BasicDetailsPage extends _Page {
  const _BasicDetailsPage();
}

class _EconomicDetailsPage extends _Page {
  const _EconomicDetailsPage();
}

class _SpecialCriteriaPage extends _Page {
  const _SpecialCriteriaPage();
}

/// Upgraded Smart Profile Completion Wizard:
/// 1. Query selection with DigiLocker Fast-Connect & AI Document Photo Scanner.
/// 2. Streamlined 3-step general & relevant profile:
///    - Step 1: Basic Demographics (Age, Gender, State/UT)
///    - Step 2: Socio-Economic Profile (Occupation, Income, Category)
///    - Step 3: Special Eligibility (Land Owner, Ration Card, Divyang, Rural)
class RecommendationsWizard extends ConsumerStatefulWidget {
  const RecommendationsWizard({super.key});

  @override
  ConsumerState<RecommendationsWizard> createState() => _RecommendationsWizardState();
}

class _RecommendationsWizardState extends ConsumerState<RecommendationsWizard> {
  static const _pages = <_Page>[
    _QueryPage(),
    _BasicDetailsPage(),
    _EconomicDetailsPage(),
    _SpecialCriteriaPage(),
  ];

  final _pageController = PageController();
  final _queryController = TextEditingController();
  int _index = 0;
  String? _queryError;
  String? _autoFillSource;

  @override
  void initState() {
    super.initState();
    _maybePrefillFromPersistedProfile();
  }

  Future<void> _maybePrefillFromPersistedProfile() async {
    if (!ref.read(isSignedInProvider)) return;
    final controller = ref.read(profileFormControllerProvider);
    if (!controller.isEmpty) return;
    try {
      final response = await ref.read(profileRepositoryProvider).getProfile();
      if (!mounted || !controller.isEmpty) return;
      controller.loadFrom(response['attributes'] as Map<String, dynamic>);
    } catch (_) {
      // Best effort prefill
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _queryController.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    setState(() => _index = index);
    _pageController.animateToPage(
      index,
      duration: AppSpacing.durationMedium,
      curve: Curves.easeOut,
    );
  }

  void _submitFromQuery() {
    final query = _queryController.text.trim();
    if (query.isEmpty) {
      setState(() => _queryError = 'Enter what you\'re looking for, e.g. "farmer subsidy".');
      return;
    }
    setState(() => _queryError = null);
    _goTo(1);
  }

  void _next() {
    if (_index >= _pages.length - 1) {
      _finish();
      return;
    }
    _goTo(_index + 1);
  }

  void _finish() {
    final query = _queryController.text.trim().isEmpty ? 'all eligible schemes' : _queryController.text.trim();
    final controller = ref.read(profileFormControllerProvider);
    final profile = controller.isEmpty ? null : controller.toProfileJson();

    // Persist to user profile in background if signed in
    if (ref.read(isSignedInProvider) && profile != null) {
      ref.read(profileRepositoryProvider).updateProfile(profile).ignore();
    }

    ref.read(recommendationsNotifierProvider.notifier).fetch(query: query, profile: profile);
  }

  void _applyAttributes(Map<String, dynamic> attributes, String sourceLabel) {
    final controller = ref.read(profileFormControllerProvider);
    controller.loadFrom(attributes);
    setState(() {
      _autoFillSource = sourceLabel;
      if (_queryController.text.trim().isEmpty) {
        if (attributes['is_farmer'] == true) {
          _queryController.text = 'farmer subsidy';
        } else if (attributes['is_student'] == true) {
          _queryController.text = 'scholarship';
        } else if (attributes['is_woman'] == true) {
          _queryController.text = 'women welfare';
        } else {
          _queryController.text = 'all eligible schemes';
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ Verified details loaded from $sourceLabel!'),
        backgroundColor: const Color(0xFF16A34A),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_index];
    final isQueryPage = page is _QueryPage;
    final strings = ref.watch(stringsProvider);

    return Column(
      children: [
        if (!isQueryPage)
          _WizardHeader(
            index: _index,
            totalSteps: _pages.length - 1,
            onBack: () => _goTo(_index - 1),
            onFinish: _finish,
            isHindi: strings.isHindi,
          ),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _pages.length,
            itemBuilder: (context, i) {
              final p = _pages[i];
              return switch (p) {
                _QueryPage() => _QueryStep(
                  controller: _queryController,
                  error: _queryError,
                  autoFillSource: _autoFillSource,
                  onSubmit: _submitFromQuery,
                  onOpenDigiLocker: () => DigiLockerDialog.show(
                    context,
                    onDataFetched: (attrs, kyc) => _applyAttributes(attrs, 'DigiLocker / UIDAI'),
                  ),
                  onOpenDocScanner: () => DocumentScannerDialog.show(
                    context,
                    onDataExtracted: (attrs, fields) => _applyAttributes(attrs, 'Aadhaar AI Scanner'),
                  ),
                ),
                _BasicDetailsPage() => _BasicDetailsStep(onNext: _next),
                _EconomicDetailsPage() => _EconomicDetailsStep(onNext: _next),
                _SpecialCriteriaPage() => _SpecialCriteriaStep(onFinish: _finish),
              };
            },
          ),
        ),
      ],
    );
  }
}

class _WizardHeader extends StatelessWidget {
  const _WizardHeader({
    required this.index,
    required this.totalSteps,
    required this.onBack,
    required this.onFinish,
    required this.isHindi,
  });

  final int index;
  final int totalSteps;
  final VoidCallback onBack;
  final VoidCallback onFinish;
  final bool isHindi;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (index / totalSteps).clamp(0.0, 1.0);

    final stepTitles = isHindi
        ? ['मूल विवरण', 'आर्थिक और व्यवसाय', 'विशेष मानदंड']
        : ['Basic Details', 'Socio-Economic', 'Special Eligibility'];

    final currentTitle = (index - 1 < stepTitles.length) ? stepTitles[index - 1] : '';

    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: const Color(0xFFE2E8F0),
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
          minHeight: 4,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Back',
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Step $index of $totalSteps',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                    ),
                    Text(
                      currentTitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                key: const ValueKey('recommendations_wizard_skip_all_button'),
                onPressed: onFinish,
                child: Text(isHindi ? 'सभी छोड़ें' : 'Skip all'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QueryStep extends ConsumerWidget {
  const _QueryStep({
    required this.controller,
    required this.error,
    required this.autoFillSource,
    required this.onSubmit,
    required this.onOpenDigiLocker,
    required this.onOpenDocScanner,
  });

  final TextEditingController controller;
  final String? error;
  final String? autoFillSource;
  final VoidCallback onSubmit;
  final VoidCallback onOpenDigiLocker;
  final VoidCallback onOpenDocScanner;

  static const _suggestions = [
    'farmer subsidy',
    'scholarship',
    'housing grant',
    'health insurance',
    'small business loan',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final strings = ref.watch(stringsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EyebrowLabel('PERSONALIZED ELIGIBILITY WIZARD'),
          const SizedBox(height: AppSpacing.xs),
          Text(
            strings.isHindi ? 'आप किस प्रकार की योजना खोज रहे हैं?' : 'What schemes are you looking for?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            strings.isHindi
                ? 'स्मार्ट प्रोफ़ाइल या फ़ास्ट-वेरिफाई से तुरंत अनुकूल योजनाएं खोजें।'
                : 'Complete your profile or fast-fill with DigiLocker to see schemes matched to you.',
            style: theme.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),

          // FAST-FILL HERO BAR
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0F766E).withValues(alpha: 0.08),
                  const Color(0xFF2563EB).withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(color: const Color(0xFF93C5FD)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.flash_on_rounded, color: Color(0xFFD97706), size: 20),
                    const SizedBox(width: 6),
                    Text(
                      strings.isHindi ? '1-क्लिक फास्ट-वेरिफिकेशन' : '1-Click Instant Fast-Fill Options',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E3A8A),
                      ),
                    ),
                    const Spacer(),
                    if (autoFillSource != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '✓ $autoFillSource',
                          style: const TextStyle(color: Color(0xFF16A34A), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  strings.isHindi
                      ? 'डिजिलॉकर से सीधे सरकारी रिकॉर्ड लाएं या आधार/दस्तावेज़ की फोटो स्कैन करें।'
                      : 'Connect with DigiLocker or scan Aadhaar card photo to auto-fill verified details.',
                  style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF334155)),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0F766E),
                          side: const BorderSide(color: Color(0xFF0F766E)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: onOpenDigiLocker,
                        icon: const Icon(Icons.verified_user_rounded, size: 16),
                        label: Text(
                          strings.isHindi ? 'डिजिलॉकर कनेक्ट' : 'DigiLocker',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2563EB),
                          side: const BorderSide(color: Color(0xFF2563EB)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: onOpenDocScanner,
                        icon: const Icon(Icons.document_scanner_rounded, size: 16),
                        label: Text(
                          strings.isHindi ? 'आधार स्कैन' : 'Scan Aadhaar',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),
          TextField(
            key: const ValueKey('recommendations_query_field'),
            controller: controller,
            decoration: InputDecoration(
              hintText: strings.isHindi ? 'उदा. किसान सब्सिडी, छात्रवृत्ति' : 'e.g. farmer subsidy, scholarship',
              errorText: error,
              prefixIcon: const Icon(Icons.search_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onSubmit(),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in _suggestions)
                ActionChip(
                  label: Text(s, style: const TextStyle(fontSize: 12)),
                  backgroundColor: colors.surfaceMuted,
                  onPressed: () {
                    controller.text = s;
                    onSubmit();
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('recommendations_wizard_continue_button'),
              onPressed: onSubmit,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(strings.isHindi ? 'आगे बढ़ें: प्रोफ़ाइल भरें' : 'Continue to Smart Profile'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// STEP 1: BASIC DEMOGRAPHICS (Age, Gender, State/UT)
// ---------------------------------------------------------------------------
class _BasicDetailsStep extends ConsumerWidget {
  const _BasicDetailsStep({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = ref.watch(profileFormControllerProvider);
    final strings = ref.watch(stringsProvider);

    final age = controller.valueOf(EligibilityAttribute.age) as double?;
    final isWoman = controller.valueOf(EligibilityAttribute.isWoman) as bool?;
    final stateCode = controller.valueOf(EligibilityAttribute.stateCode) as String?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.isHindi ? 'मूल जनसांख्यिकी विवरण' : 'Basic Demographics',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            strings.isHindi ? 'आपकी उम्र, लिंग और राज्य के आधार पर पात्रता निर्धारित होती है।' : 'Eligibility depends heavily on age, gender and state.',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Age
          Text(strings.isHindi ? 'आपकी आयु (वर्ष)' : 'Your Age (Years)', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: (age ?? 28).clamp(1.0, 100.0),
                  min: 1,
                  max: 100,
                  divisions: 99,
                  label: '${(age ?? 28).toInt()}',
                  onChanged: (val) => controller.setNumeric(EligibilityAttribute.age, val),
                ),
              ),
              Container(
                width: 60,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(age ?? 28).toInt()} yrs',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Gender
          Text(strings.isHindi ? 'लिंग' : 'Gender', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text(strings.isHindi ? 'महिला' : 'Female'),
                selected: isWoman == true,
                onSelected: (val) => controller.setBoolean(EligibilityAttribute.isWoman, val ? true : null),
              ),
              ChoiceChip(
                label: Text(strings.isHindi ? 'पुरुष' : 'Male'),
                selected: isWoman == false,
                onSelected: (val) => controller.setBoolean(EligibilityAttribute.isWoman, val ? false : null),
              ),
              ChoiceChip(
                label: Text(strings.isHindi ? 'अन्य / छोड़ें' : 'Other / Skip'),
                selected: isWoman == null,
                onSelected: (_) => controller.setBoolean(EligibilityAttribute.isWoman, null),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Indian State Dropdown
          Text(strings.isHindi ? 'निवास का राज्य / केंद्र शासित प्रदेश' : 'State / Union Territory of Residence', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: stateCode,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              hintText: strings.isHindi ? 'राज्य चुनें' : 'Select State / UT',
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('All India / Central Only', overflow: TextOverflow.ellipsis)),
              for (final state in indianStates)
                DropdownMenuItem(
                  value: state.$1,
                  child: Text('${state.$2} (${state.$1})', overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (val) => controller.setText(EligibilityAttribute.stateCode, val),
          ),

          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onNext,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(strings.isHindi ? 'अगला: आर्थिक और व्यवसाय' : 'Next: Socio-Economic Profile'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// STEP 2: SOCIO-ECONOMIC (Occupation, Income, Social Category)
// ---------------------------------------------------------------------------
class _EconomicDetailsStep extends ConsumerWidget {
  const _EconomicDetailsStep({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = ref.watch(profileFormControllerProvider);
    final strings = ref.watch(stringsProvider);

    final isFarmer = controller.valueOf(EligibilityAttribute.isFarmer) == true;
    final isStudent = controller.valueOf(EligibilityAttribute.isStudent) == true;
    final isUnorganized = controller.valueOf(EligibilityAttribute.isUnorganizedWorker) == true;
    final isGovtEmployee = controller.valueOf(EligibilityAttribute.isGovtEmployee) == true;

    final isObc = controller.valueOf(EligibilityAttribute.isObc) == true;
    final isScSt = controller.valueOf(EligibilityAttribute.isScSt) == true;
    final isMinority = controller.valueOf(EligibilityAttribute.isMinority) == true;

    final income = controller.valueOf(EligibilityAttribute.annualIncome) as double?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.isHindi ? 'आर्थिक व व्यवसाय प्रोफ़ाइल' : 'Socio-Economic Profile',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            strings.isHindi ? 'व्यवसाय, आय और सामाजिक श्रेणी से विशिष्ट लाभ प्राप्त होते हैं।' : 'Occupation, income tier, and category unlock key benefits.',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Primary Occupation
          Text(strings.isHindi ? 'प्रमुख व्यवसाय / पेशा' : 'Primary Occupation', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: Text(strings.isHindi ? '🌾 किसान / कृषि' : '🌾 Farmer / Agriculture'),
                selected: isFarmer,
                onSelected: (val) {
                  controller.setBoolean(EligibilityAttribute.isFarmer, val ? true : null);
                  if (val) controller.setBoolean(EligibilityAttribute.ownsCultivableLand, true);
                },
              ),
              FilterChip(
                label: Text(strings.isHindi ? '🎓 छात्र / विद्यार्थी' : '🎓 Student'),
                selected: isStudent,
                onSelected: (val) => controller.setBoolean(EligibilityAttribute.isStudent, val ? true : null),
              ),
              FilterChip(
                label: Text(strings.isHindi ? '🛠️ असंगठित / कारीगर' : '🛠️ Unorganized / Artisan'),
                selected: isUnorganized,
                onSelected: (val) => controller.setBoolean(EligibilityAttribute.isUnorganizedWorker, val ? true : null),
              ),
              FilterChip(
                label: Text(strings.isHindi ? '🏛️ सरकारी कर्मचारी' : '🏛️ Govt Employee'),
                selected: isGovtEmployee,
                onSelected: (val) => controller.setBoolean(EligibilityAttribute.isGovtEmployee, val ? true : null),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Social Category
          Text(strings.isHindi ? 'सामाजिक श्रेणी / वर्ग' : 'Social Category', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('General'),
                selected: !isObc && !isScSt && !isMinority,
                onSelected: (_) {
                  controller.setBoolean(EligibilityAttribute.isObc, null);
                  controller.setBoolean(EligibilityAttribute.isScSt, null);
                  controller.setBoolean(EligibilityAttribute.isMinority, null);
                },
              ),
              ChoiceChip(
                label: const Text('OBC'),
                selected: isObc,
                onSelected: (val) {
                  controller.setBoolean(EligibilityAttribute.isObc, val ? true : null);
                  if (val) controller.setBoolean(EligibilityAttribute.isScSt, null);
                },
              ),
              ChoiceChip(
                label: const Text('SC / ST'),
                selected: isScSt,
                onSelected: (val) {
                  controller.setBoolean(EligibilityAttribute.isScSt, val ? true : null);
                  if (val) controller.setBoolean(EligibilityAttribute.isObc, null);
                },
              ),
              ChoiceChip(
                label: Text(strings.isHindi ? 'अल्पसंख्यक' : 'Minority'),
                selected: isMinority,
                onSelected: (val) => controller.setBoolean(EligibilityAttribute.isMinority, val ? true : null),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Annual Household Income
          Text(strings.isHindi ? 'वार्षिक पारिवारिक आय' : 'Annual Household Income', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                label: const Text('< ₹1,00,000 (BPL)'),
                backgroundColor: income != null && income <= 100000 ? const Color(0xFF1E3A8A).withValues(alpha: 0.15) : null,
                onPressed: () {
                  controller.setNumeric(EligibilityAttribute.annualIncome, 90000);
                  controller.setBoolean(EligibilityAttribute.hasBplCard, true);
                },
              ),
              ActionChip(
                label: const Text('₹1L – ₹2.5L (EWS)'),
                backgroundColor: income != null && income > 100000 && income <= 250000 ? const Color(0xFF1E3A8A).withValues(alpha: 0.15) : null,
                onPressed: () => controller.setNumeric(EligibilityAttribute.annualIncome, 180000),
              ),
              ActionChip(
                label: const Text('₹2.5L – ₹5.0L (LIG)'),
                backgroundColor: income != null && income > 250000 && income <= 500000 ? const Color(0xFF1E3A8A).withValues(alpha: 0.15) : null,
                onPressed: () => controller.setNumeric(EligibilityAttribute.annualIncome, 350000),
              ),
              ActionChip(
                label: const Text('> ₹5,00,000'),
                backgroundColor: income != null && income > 500000 ? const Color(0xFF1E3A8A).withValues(alpha: 0.15) : null,
                onPressed: () => controller.setNumeric(EligibilityAttribute.annualIncome, 600000),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onNext,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(strings.isHindi ? 'अगला: विशेष मानदंड' : 'Next: Special Eligibility'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// STEP 3: SPECIAL CRITERIA (Farmer Land, Ration Card, Disability, Rural)
// ---------------------------------------------------------------------------
class _SpecialCriteriaStep extends ConsumerWidget {
  const _SpecialCriteriaStep({required this.onFinish});

  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = ref.watch(profileFormControllerProvider);
    final strings = ref.watch(stringsProvider);

    final ownsLand = controller.valueOf(EligibilityAttribute.ownsCultivableLand) == true;
    final bpl = controller.valueOf(EligibilityAttribute.hasBplCard) == true;
    final divyang = controller.valueOf(EligibilityAttribute.isDivyang) == true;
    final rural = controller.valueOf(EligibilityAttribute.isRural) == true;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.isHindi ? 'विशेष पात्रता मानदंड (वैकल्पिक)' : 'Special Eligibility Criteria',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            strings.isHindi ? 'यदि लागू हो तो इन विकल्पों को चालू करें ताकि कोई विशेष योजना न छूटे।' : 'Toggle any of these criteria to qualify for special targeted schemes.',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: AppSpacing.lg),

          SwitchListTile(
            title: Text(strings.isHindi ? 'कृषि भूमि के मालिक हैं' : 'Owns Cultivable / Agricultural Land'),
            subtitle: Text(strings.isHindi ? 'पीएम-किसान और कृषि सब्सिडी के लिए' : 'For PM-KISAN, crop subsidies, and farm loans'),
            value: ownsLand,
            onChanged: (val) {
              controller.setBoolean(EligibilityAttribute.ownsCultivableLand, val ? true : null);
              if (val) controller.setBoolean(EligibilityAttribute.isFarmer, true);
            },
          ),
          const Divider(),

          SwitchListTile(
            title: Text(strings.isHindi ? 'बीपीएल / अंत्योदय / पीला राशन कार्ड' : 'Has BPL / Yellow / Antyodaya Ration Card'),
            subtitle: Text(strings.isHindi ? 'राशन, आवास और खाद्य सुरक्षा योजनाओं के लिए' : 'For food security, housing and subsidized grains'),
            value: bpl,
            onChanged: (val) => controller.setBoolean(EligibilityAttribute.hasBplCard, val ? true : null),
          ),
          const Divider(),

          SwitchListTile(
            title: Text(strings.isHindi ? 'दिव्यांग / विशेष रूप से सक्षम' : 'Person with Disability (Divyang)'),
            subtitle: Text(strings.isHindi ? 'दिव्यांग पेंशन, उपकरण और आरक्षण योजनाओं के लिए' : 'For disability pensions, assistive devices, and quotas'),
            value: divyang,
            onChanged: (val) => controller.setBoolean(EligibilityAttribute.isDivyang, val ? true : null),
          ),
          const Divider(),

          SwitchListTile(
            title: Text(strings.isHindi ? 'ग्रामीण क्षेत्र में निवास' : 'Rural Resident'),
            subtitle: Text(strings.isHindi ? 'मनरेगा और ग्रामीण विकास योजनाओं के लिए' : 'For rural housing, MGNREGA, and village welfare'),
            value: rural,
            onChanged: (val) => controller.setBoolean(EligibilityAttribute.isRural, val ? true : null),
          ),

          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_rounded, color: Color(0xFF16A34A)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    strings.isHindi ? 'प्रोफ़ाइल तैयार है! आपके उत्तरों के आधार पर योजनाएं रैंक की जाएंगी।' : 'Profile ready! Real schemes will be ranked by your answers.',
                    style: const TextStyle(color: Color(0xFF14532D), fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onFinish,
              icon: const Icon(Icons.search_rounded),
              label: Text(strings.isHindi ? 'अनुकूल योजनाएं देखें' : 'Save & View My Schemes'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
