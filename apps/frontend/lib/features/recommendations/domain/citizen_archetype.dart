import 'package:flutter/material.dart';

class CitizenArchetype {
  const CitizenArchetype({
    required this.id,
    required this.titleEn,
    required this.titleHi,
    required this.subtitleEn,
    required this.subtitleHi,
    required this.icon,
    required this.accentColor,
    required this.suggestedQuery,
    required this.highlightsEn,
    required this.highlightsHi,
    required this.attributes,
  });

  final String id;
  final String titleEn;
  final String titleHi;
  final String subtitleEn;
  final String subtitleHi;
  final IconData icon;
  final Color accentColor;
  final String suggestedQuery;
  final List<String> highlightsEn;
  final List<String> highlightsHi;
  final Map<String, dynamic> attributes;

  String title(bool isHindi) => isHindi ? titleHi : titleEn;
  String subtitle(bool isHindi) => isHindi ? subtitleHi : subtitleEn;
  List<String> highlights(bool isHindi) => isHindi ? highlightsHi : highlightsEn;
}

const citizenArchetypes = <CitizenArchetype>[
  CitizenArchetype(
    id: 'farmer',
    titleEn: 'Smallholder Farmer',
    titleHi: 'सीमांत किसान',
    subtitleEn: 'Cultivable land < 2 acres, PM-KISAN, crop subsidies',
    subtitleHi: '2 एकड़ से कम खेती योग्य जमीन, पीएम-किसान एवं कृषि अनुदान',
    icon: Icons.agriculture_rounded,
    accentColor: Color(0xFF15803D), // Forest Green
    suggestedQuery: 'farmer subsidy',
    highlightsEn: ['MH (Maharashtra)', 'Age 38', 'Land < 2ac', 'Income < ₹1L', 'BPL'],
    highlightsHi: ['महाराष्ट्र', 'उम्र 38', 'जमीन < 2 एकड़', 'आय < ₹1 लाख', 'बीपीएल'],
    attributes: {
      'age': 38.0,
      'is_woman': false,
      'state_code': 'MH',
      'is_farmer': true,
      'owns_cultivable_land': true,
      'has_bpl_card': true,
      'is_rural': true,
      'annual_income': 90000.0,
      'is_taxpayer': false,
      'is_govt_employee': false,
    },
  ),
  CitizenArchetype(
    id: 'student',
    titleEn: 'College Student & Youth',
    titleHi: 'कॉलेज छात्र एवं युवा',
    subtitleEn: 'Higher education, merit scholarships, skill grants',
    subtitleHi: 'उच्च शिक्षा, छात्रवृत्ति, लैपटॉप एवं कौशल विकास योजनाएं',
    icon: Icons.school_rounded,
    accentColor: Color(0xFF2563EB), // Blue
    suggestedQuery: 'scholarship',
    highlightsEn: ['GJ (Gujarat)', 'Age 20', 'College Student', 'Income < ₹1.5L'],
    highlightsHi: ['गुजरात', 'उम्र 20', 'कॉलेज छात्र', 'आय < ₹1.5 लाख'],
    attributes: {
      'age': 20.0,
      'is_woman': false,
      'state_code': 'GJ',
      'is_student': true,
      'annual_income': 120000.0,
      'has_orange_ration_card': true,
      'is_taxpayer': false,
      'is_govt_employee': false,
    },
  ),
  CitizenArchetype(
    id: 'woman_artisan',
    titleEn: 'Woman Artisan / SHG',
    titleHi: 'महिला कारीगर / स्वयं सहायता समूह',
    subtitleEn: 'Handicrafts, SHG Mudra loans, Matru Vandana, E-Shram',
    subtitleHi: 'हस्तशिल्प, स्वयं सहायता समूह ऋण, मातृ वंदना, ई-श्रम',
    icon: Icons.female_rounded,
    accentColor: Color(0xFF9333EA), // Purple
    suggestedQuery: 'women welfare',
    highlightsEn: ['UP (Uttar Pradesh)', 'Age 29', 'Artisan/SHG', 'SC Category', 'Income < ₹70k'],
    highlightsHi: ['उत्तर प्रदेश', 'उम्र 29', 'कारीगर/एसएचजी', 'अनुसूचित जाति', 'आय < ₹70 हजार'],
    attributes: {
      'age': 29.0,
      'is_woman': true,
      'state_code': 'UP',
      'is_sc_st': true,
      'is_unorganized_worker': true,
      'has_eshram_card': true,
      'has_bpl_card': true,
      'has_yellow_ration_card': true,
      'is_rural': true,
      'annual_income': 65000.0,
      'is_taxpayer': false,
      'is_govt_employee': false,
    },
  ),
  CitizenArchetype(
    id: 'senior_citizen',
    titleEn: 'Senior Citizen',
    titleHi: 'वरिष्ठ नागरिक (पेंशन व स्वास्थ्य)',
    subtitleEn: 'Age 65+, Ayushman Bharat health cover, Old-Age Pension',
    subtitleHi: 'आयु 65+, आयुष्मान भारत स्वास्थ्य सुरक्षा, वृद्धावस्था पेंशन',
    icon: Icons.elderly_rounded,
    accentColor: Color(0xFFD97706), // Amber
    suggestedQuery: 'pension healthcare',
    highlightsEn: ['RJ (Rajasthan)', 'Age 68', 'Rural', 'Income < ₹60k', 'Yellow Ration'],
    highlightsHi: ['राजस्थान', 'उम्र 68', 'ग्रामीण', 'आय < ₹60 हजार', 'पीला राशन कार्ड'],
    attributes: {
      'age': 68.0,
      'is_woman': false,
      'state_code': 'RJ',
      'has_bpl_card': true,
      'has_yellow_ration_card': true,
      'is_rural': true,
      'annual_income': 55000.0,
      'is_pensioner_above_10k': false,
      'is_taxpayer': false,
      'is_govt_employee': false,
    },
  ),
  CitizenArchetype(
    id: 'worker',
    titleEn: 'Daily-Wage & Unorganized Worker',
    titleHi: 'दैनिक कामगार / असंगठित श्रमिक',
    subtitleEn: 'MGNREGA / E-Shram, Affordable rental housing, Food security',
    subtitleHi: 'मनरेगा, ई-श्रम कार्ड, किफायती आवास, राशन व खाद्य सुरक्षा',
    icon: Icons.engineering_rounded,
    accentColor: Color(0xFF0F766E), // Teal
    suggestedQuery: 'worker welfare',
    highlightsEn: ['BR (Bihar)', 'Age 34', 'E-Shram Card', 'Income < ₹95k', 'BPL'],
    highlightsHi: ['बिहार', 'उम्र 34', 'ई-श्रम कार्ड', 'आय < ₹95 हजार', 'बीपीएल'],
    attributes: {
      'age': 34.0,
      'is_woman': false,
      'state_code': 'BR',
      'is_unorganized_worker': true,
      'has_eshram_card': true,
      'is_mgnrega_worker': true,
      'has_bpl_card': true,
      'annual_income': 92000.0,
      'is_rural': true,
      'no_pucca_house': true,
      'is_taxpayer': false,
      'is_govt_employee': false,
    },
  ),
];
