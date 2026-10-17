import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../profile/data/profile_automation_repository.dart';
import 'camera_picker.dart';

class DocumentScannerDialog extends ConsumerStatefulWidget {
  const DocumentScannerDialog({required this.onDataExtracted, super.key});

  final void Function(Map<String, dynamic> attributes, Map<String, dynamic> extractedFields) onDataExtracted;

  static Future<void> show(
    BuildContext context, {
    required void Function(Map<String, dynamic> attributes, Map<String, dynamic> extractedFields) onDataExtracted,
  }) {
    return showDialog(
      context: context,
      builder: (context) => DocumentScannerDialog(onDataExtracted: onDataExtracted),
    );
  }

  @override
  ConsumerState<DocumentScannerDialog> createState() => _DocumentScannerDialogState();
}

class _DocumentScannerDialogState extends ConsumerState<DocumentScannerDialog> {
  bool _isScanning = false;
  String? _error;
  Map<String, dynamic>? _scanResult;
  String? _selectedSample;

  Future<void> _captureOrUpload({required bool useCamera}) async {
    setState(() {
      _isScanning = true;
      _error = null;
    });

    try {
      final base64Image = await pickOrCaptureImage(useCamera: useCamera);
      if (base64Image == null) {
        if (mounted) setState(() => _isScanning = false);
        return;
      }

      final repo = ref.read(profileAutomationRepositoryProvider);
      final res = await repo.extractDocument(
        imageBase64: base64Image,
        documentHint: 'auto',
      );

      if (!mounted) return;
      setState(() {
        _scanResult = res;
        _isScanning = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not process document image. Please try again or select a sample.';
        _isScanning = false;
      });
    }
  }

  static const _sampleDocuments = [
    (
      id: 'aadhaar_farmer',
      title: 'Aadhaar Card - Sunita Sharma (Farmer, MH)',
      type: 'aadhaar',
      ocrText: 'GOVERNMENT OF INDIA UIDAI Aadhaar Card Name: Sunita Ramesh Sharma DOB: 15/07/1994 Gender: Female Address: At Post Haveli, Pune, Maharashtra 411001 5482 9182 4829',
    ),
    (
      id: 'aadhaar_student',
      title: 'Aadhaar Card - Aarav Patel (Student, GJ)',
      type: 'aadhaar',
      ocrText: 'GOVERNMENT OF INDIA UIDAI Aadhaar Card Name: Aarav Vikas Patel Year of Birth: 2004 Gender: Male Address: Vastrapur, Ahmedabad, Gujarat 380001 7891 2341 9012',
    ),
    (
      id: 'ration_bpl',
      title: 'BPL Ration Card - Bihar (Food & Civil Supplies)',
      type: 'ration_card',
      ocrText: 'Department of Food and Civil Supplies BPL Ration Card Head of Family: Pooja Devi Gender: Female State: Bihar Patna 800001 Category: BPL Yellow Card Holder',
    ),
    (
      id: 'pan_card',
      title: 'PAN Card - Vikram Malhotra (Delhi)',
      type: 'pan',
      ocrText: 'INCOME TAX DEPARTMENT GOVT OF INDIA Permanent Account Number Name: Vikram Malhotra Father: O.P. Malhotra Date of Birth: 22/09/1988 Gender: Male Delhi 110001 ABCPM1234D',
    ),
  ];

  Future<void> _scanSample(String id, String type, String ocrText) async {
    setState(() {
      _selectedSample = id;
      _isScanning = true;
      _error = null;
    });

    try {
      final repo = ref.read(profileAutomationRepositoryProvider);
      final res = await repo.extractDocument(
        ocrText: ocrText,
        documentHint: type,
      );

      if (!mounted) return;
      setState(() {
        _scanResult = res;
        _isScanning = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to extract document information. Please try again.';
        _isScanning = false;
      });
    }
  }

  void _applyAndClose() {
    if (_scanResult != null) {
      final attrs = _scanResult!['attributes'] as Map<String, dynamic>? ?? {};
      final fields = _scanResult!['extracted_fields'] as Map<String, dynamic>? ?? {};
      widget.onDataExtracted(attrs, fields);
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
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 680),
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
                      color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.document_scanner_rounded, color: Color(0xFF2563EB), size: 24),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              strings.isHindi ? 'दस्तावेज़ स्कैनर (AI OCR)' : 'Govt Document Scanner',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'AI OCR',
                                style: TextStyle(color: Color(0xFF2563EB), fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          strings.isHindi
                              ? 'आधार, पैन या राशन कार्ड से स्वचालित विवरण निकालें'
                              : 'Auto-extract demographic details from Aadhaar, PAN or Ration Card',
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
              const Divider(height: 24),

              Expanded(
                child: SingleChildScrollView(
                  child: _scanResult == null
                      ? _buildScannerView(theme, colors, strings)
                      : _buildResultView(theme, colors, strings),
                ),
              ),

              const SizedBox(height: AppSpacing.md),
              if (_scanResult != null)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _scanResult = null),
                        child: Text(strings.isHindi ? 'दूसरा दस्तावेज़' : 'Scan Another'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                        onPressed: _applyAndClose,
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                        label: Text(strings.isHindi ? 'प्रोफ़ाइल में लागू करें' : 'Apply to Profile'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScannerView(ThemeData theme, AppColors colors, AppStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Interactive Camera / Upload Area
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: colors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.4), style: BorderStyle.solid),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              children: [
                Icon(Icons.add_a_photo_outlined, size: 40, color: const Color(0xFF2563EB)),
                const SizedBox(height: 8),
                Text(
                  strings.isHindi ? 'आधार या सरकारी पहचान पत्र की फोटो लें' : 'Upload or Photo of Govt Document',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  strings.isHindi
                      ? 'Aadhaar, PAN, Voter ID, Ration Card समर्थित हैं'
                      : 'Aadhaar Card, PAN Card, Voter ID, Ration Card supported',
                  style: theme.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onPressed: _isScanning ? null : () => _captureOrUpload(useCamera: true),
                      icon: const Icon(Icons.camera_alt_rounded, size: 18),
                      label: Text(strings.isHindi ? 'कैमरा खोलें' : 'Open Camera'),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onPressed: _isScanning ? null : () => _captureOrUpload(useCamera: false),
                      icon: const Icon(Icons.upload_file_rounded, size: 18),
                      label: Text(strings.isHindi ? 'फ़ाइल अपलोड' : 'Upload Image'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        Text(
          strings.isHindi ? 'या त्वरित परीक्षण के लिए नमूना दस्तावेज़ चुनें:' : 'Or Select a Sample Document for Instant Test:',
          style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),

        for (final sample in _sampleDocuments)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              onTap: _isScanning ? null : () => _scanSample(sample.id, sample.type, sample.ocrText),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.sm + 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: _selectedSample == sample.id ? const Color(0xFF2563EB) : colors.divider,
                    width: _selectedSample == sample.id ? 1.5 : 1.0,
                  ),
                  color: _selectedSample == sample.id ? const Color(0xFF2563EB).withValues(alpha: 0.05) : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      sample.type == 'aadhaar'
                          ? Icons.badge_outlined
                          : (sample.type == 'ration_card' ? Icons.receipt_long_outlined : Icons.credit_card_outlined),
                      color: const Color(0xFF2563EB),
                      size: 22,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        sample.title,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),

        if (_isScanning) ...[
          const SizedBox(height: AppSpacing.md),
          const Center(
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 8),
                Text('AI Vision OCR scanning document...', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],

        if (_error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(_error!, style: TextStyle(color: theme.colorScheme.error, fontSize: 13)),
        ],
      ],
    );
  }

  Widget _buildResultView(ThemeData theme, AppColors colors, AppStrings strings) {
    final fields = _scanResult!['extracted_fields'] as Map<String, dynamic>? ?? {};
    final title = _scanResult!['document_title'] as String? ?? 'Aadhaar Card';
    final confidence = ((_scanResult!['confidence'] as num? ?? 0.9) * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        border: Border.all(color: const Color(0xFF93C5FD)),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFF2563EB), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: const Color(0xFF1D4ED8),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'AI OCR Confidence: $confidence%',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF3B82F6), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  fields['id_masked'] ?? 'XXXX-XXXX-4829',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(height: 18),
          _fieldRow('Full Name', fields['name'] ?? 'Citizen Name'),
          _fieldRow('Age / DOB', '${fields['age'] ?? '30'} years (${fields['dob'] ?? 'N/A'})'),
          _fieldRow('Gender', fields['gender'] ?? 'Female'),
          _fieldRow('State / UT', '${fields['state'] ?? 'Maharashtra'} (${fields['state_code'] ?? 'MH'})'),
          if (fields['address_type'] != null) _fieldRow('Area Type', fields['address_type']!),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF2563EB), size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    strings.isHindi
                        ? 'पहचाने गए सभी मान आपकी प्रोफाइल में अपडेट कर दिए जाएंगे।'
                        : 'Extracted attributes ready to auto-populate your eligibility profile.',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF1E40AF)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }
}
