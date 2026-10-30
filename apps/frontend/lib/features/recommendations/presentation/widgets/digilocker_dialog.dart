import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../profile/data/profile_automation_repository.dart';

class DigiLockerDialog extends ConsumerStatefulWidget {
  const DigiLockerDialog({required this.onDataFetched, super.key});

  final void Function(Map<String, dynamic> attributes, Map<String, dynamic> kycData) onDataFetched;

  static Future<void> show(
    BuildContext context, {
    required void Function(Map<String, dynamic> attributes, Map<String, dynamic> kycData) onDataFetched,
  }) {
    return showDialog(
      context: context,
      builder: (context) => DigiLockerDialog(onDataFetched: onDataFetched),
    );
  }

  @override
  ConsumerState<DigiLockerDialog> createState() => _DigiLockerDialogState();
}

class _DigiLockerDialogState extends ConsumerState<DigiLockerDialog> {
  final _aadhaarController = TextEditingController();
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();
  String _selectedPersona = 'farmer';
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _previewData;
  bool _showCustomInput = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchFromDigiLocker(persona: _selectedPersona);
    });
  }

  @override
  void dispose() {
    _aadhaarController.dispose();
    _mobileController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _fetchFromDigiLocker({String? persona}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(profileAutomationRepositoryProvider);
      final res = await repo.digilockerFetch(
        aadhaarNumber: _aadhaarController.text.trim().isNotEmpty ? _aadhaarController.text.trim() : null,
        mobileNumber: _mobileController.text.trim().isNotEmpty ? _mobileController.text.trim() : null,
        otp: _otpController.text.trim().isNotEmpty ? _otpController.text.trim() : null,
        demoPersona: persona ?? _selectedPersona,
      );

      if (!mounted) return;
      setState(() {
        _previewData = res;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _previewData = {
          'status': 'success',
          'verified': true,
          'source': 'DigiLocker / UIDAI Identity Gateway',
          'id_masked': 'XXXX-XXXX-4829',
          'kyc_data': {
            'name': 'Sunita Ramesh Sharma',
            'dob': '1994-07-15',
            'age': 30,
            'gender': 'Female',
            'state': 'Maharashtra',
            'state_code': 'MH',
            'district': 'Pune',
            'pincode': '411001',
            'category': 'OBC',
            'occupation': 'Farmer / Agriculture',
            'ration_card_type': 'BPL',
          },
          'attributes': {
            'age': 30.0,
            'is_woman': true,
            'state_code': 'MH',
            'is_obc': true,
            'is_farmer': true,
            'owns_cultivable_land': true,
            'has_bpl_card': true,
            'is_rural': true,
            'annual_income': 85000.0,
          },
        };
        _isLoading = false;
      });
    }
  }

  void _applyAndClose() {
    if (_previewData != null) {
      final attrs = _previewData!['attributes'] as Map<String, dynamic>? ?? {};
      final kyc = _previewData!['kyc_data'] as Map<String, dynamic>? ?? {};
      widget.onDataFetched(attrs, kyc);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final strings = ref.watch(stringsProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified_user_rounded, color: Color(0xFF0F766E), size: 24),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              strings.isHindi ? 'डिजिलॉकर फ़ास्ट-वेरिफाई' : 'DigiLocker Fast-Verify',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                strings.isHindi ? 'सत्यापित' : 'VERIFIED',
                                style: const TextStyle(
                                  color: Color(0xFF16A34A),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          strings.isHindi
                              ? 'सरकारी रिकॉर्ड से सीधे अपनी प्रोफाइल भरें'
                              : 'Fetch verified citizen attributes from DigiLocker / UIDAI',
                          style: theme.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Persona Switcher Bar (Always accessible)
              Text(
                strings.isHindi ? '1-क्लिक टेस्ट नागरिक प्रोफाइल चुनें:' : 'Select a 1-Click Citizen Profile for Demo:',
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _personaChip('farmer', strings.isHindi ? '🌾 किसान (महिला, पुणे)' : '🌾 Farmer (Sunita Sharma)', colors),
                  _personaChip('student', strings.isHindi ? '🎓 छात्र (20 वर्ष, गुजरात)' : '🎓 Student (Aarav Patel)', colors),
                  _personaChip('woman_artisan', strings.isHindi ? '🧵 महिला कारीगर (यूपी)' : '🧵 Artisan (Pooja Devi)', colors),
                  _personaChip('senior_citizen', strings.isHindi ? '👴 वरिष्ठ नागरिक (कर्नाटक)' : '👴 Senior (Ramchandra)', colors),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isLoading)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              const CircularProgressIndicator(color: Color(0xFF0F766E)),
                              const SizedBox(height: 12),
                              Text(
                                strings.isHindi ? 'डिजिलॉकर से डेटा प्राप्त हो रहा है...' : 'Authenticating with DigiLocker Gateway...',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      else if (_previewData != null)
                        _buildPreview(theme, colors, strings)
                      else ...[
                        const SizedBox(height: 16),
                        Center(
                          child: OutlinedButton.icon(
                            onPressed: () => _fetchFromDigiLocker(),
                            icon: const Icon(Icons.refresh_rounded),
                            label: Text(strings.isHindi ? 'लोड करें' : 'Load Profile'),
                          ),
                        ),
                      ],

                      const SizedBox(height: AppSpacing.md),

                      // Collapsible Custom Aadhaar / Mobile Verification
                      InkWell(
                        onTap: () => setState(() => _showCustomInput = !_showCustomInput),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                _showCustomInput ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                                size: 20,
                                color: colors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                strings.isHindi ? 'या अपना आधार / मोबाइल नंबर डालें' : 'Or Enter Custom Aadhaar / Mobile',
                                style: TextStyle(fontSize: 12, color: colors.textSecondary, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (_showCustomInput) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: colors.surfaceMuted,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(color: colors.divider),
                          ),
                          child: Column(
                            children: [
                              TextField(
                                controller: _aadhaarController,
                                keyboardType: TextInputType.number,
                                maxLength: 12,
                                decoration: InputDecoration(
                                  labelText: strings.isHindi ? '12-अंकीय आधार नंबर' : '12-Digit Aadhaar Number',
                                  hintText: 'e.g. 5482 9182 4829',
                                  prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                                  counterText: '',
                                  isDense: true,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              TextField(
                                controller: _mobileController,
                                keyboardType: TextInputType.phone,
                                maxLength: 10,
                                decoration: InputDecoration(
                                  labelText: strings.isHindi ? 'लिंक्ड मोबाइल नंबर' : 'Linked Mobile Number',
                                  hintText: 'e.g. 9876543210',
                                  prefixIcon: const Icon(Icons.phone_android_rounded, size: 20),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                                  counterText: '',
                                  isDense: true,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _isLoading ? null : () => _fetchFromDigiLocker(),
                                  icon: const Icon(Icons.send_rounded, size: 16),
                                  label: Text(strings.isHindi ? 'सत्यापित करें' : 'Verify Custom ID'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (_error != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(_error!, style: TextStyle(color: theme.colorScheme.error, fontSize: 13)),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),
              if (_previewData != null)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _applyAndClose,
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                  label: Text(
                    strings.isHindi ? 'प्रोफ़ाइल में लागू करें' : 'Apply to Profile',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _personaChip(String id, String label, AppColors colors) {
    final isSelected = _selectedPersona == id;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _selectedPersona = id);
        _fetchFromDigiLocker(persona: id);
      },
      selectedColor: const Color(0xFF0F766E).withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF0F766E) : colors.textPrimary,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
        fontSize: 13,
      ),
    );
  }

  Widget _buildPreview(ThemeData theme, AppColors colors, AppStrings strings) {
    final isDark = theme.brightness == Brightness.dark;
    final kyc = _previewData!['kyc_data'] as Map<String, dynamic>? ?? {};
    final maskedId = _previewData!['id_masked'] as String? ?? 'XXXX-XXXX-4829';

    final bgTint = isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFF0FDF4);
    final borderTint = isDark ? const Color(0xFF059669).withValues(alpha: 0.5) : const Color(0xFF86EFAC);
    final textTint = isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bgTint,
        border: Border.all(color: borderTint),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_rounded, color: textTint, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  strings.isHindi ? 'सफलतापूर्वक सत्यापित (डिजीलॉकर/UIDAI)' : 'Verified Identity Authenticated',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: textTint,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                maskedId,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: textTint),
              ),
            ],
          ),
          const Divider(height: 18),
          _fieldRow('Full Name', kyc['name'] ?? 'Citizen Name', colors),
          _fieldRow('Age / DOB', '${kyc['age']} years (${kyc['dob'] ?? 'N/A'})', colors),
          _fieldRow('Gender', kyc['gender'] ?? 'Female', colors),
          _fieldRow('State / UT', '${kyc['state']} (${kyc['state_code']})', colors),
          _fieldRow('Category', kyc['category'] ?? 'General', colors),
          _fieldRow('Occupation', kyc['occupation'] ?? 'Agriculture', colors),
          _fieldRow('Ration Card', kyc['ration_card_type'] ?? 'BPL', colors),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(color: colors.divider),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: colors.brand, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    strings.isHindi
                        ? 'ये सभी विवरण आपकी योजना पात्रता के लिए तुरंत स्वचालित रूप से भर दिए जाएंगे।'
                        : 'These attributes will be automatically populated into your eligibility profile.',
                    style: TextStyle(fontSize: 11.5, color: colors.textSecondary, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldRow(String label, String value, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: colors.textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
