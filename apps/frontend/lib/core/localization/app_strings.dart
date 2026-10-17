import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/language_repository.dart';

/// Centralized strings dictionary for English and Hindi localization.
class AppStrings {
  const AppStrings(this.language);

  final AppLanguage language;

  bool get isHindi => language == AppLanguage.hindi;

  // Nav labels
  String get navHome => isHindi ? 'होम' : 'Home';
  String get navExplore => isHindi ? 'खोजें' : 'Explore';
  String get navForYou => isHindi ? 'आपके लिए' : 'For You';
  String get navSaved => isHindi ? 'सहेजे गए' : 'Saved';
  String get navAssistant => isHindi ? 'सहायक' : 'Assistant';
  String get navProfile => isHindi ? 'प्रोफ़ाइल' : 'Profile';

  // Home Screen
  String get nationalWelfarePortal =>
      isHindi ? 'राष्ट्रीय नागरिक कल्याण पोर्टल' : 'National Welfare Portal';
  String get heroTitle =>
      isHindi ? 'सरकारी योजनाएं और लाभ जो आपके लिए बने हैं' : 'Find Government Benefits You’re Eligible For';
  String get heroSubtitle => isHindi
      ? 'पारदर्शी नियमों और आधिकारिक लिंक के साथ केंद्र व राज्य योजनाओं की तत्काल खोज।'
      : 'Instant matching across Central & State schemes with transparent rules and direct official links.';
  String get searchPlaceholder =>
      isHindi ? 'योजना का नाम, लाभ या श्रेणी से खोजें...' : 'Search schemes by keyword, benefit, or category...';
  String get exploreByCategory => isHindi ? 'श्रेणी अनुसार खोजें' : 'Explore by Category';
  String get trendingSearches => isHindi ? 'लोकप्रिय खोजें' : 'Trending';
  String get verifiedSchemesAvailable =>
      isHindi ? 'सत्यापित योजनाएं उपलब्ध' : 'verified schemes available';

  // Trust Strip
  String get trustOfficialGazettes =>
      isHindi ? '100% आधिकारिक राजपत्रों से सत्यापित' : '100% Sourced from Official Gazettes';
  String get trustDirectBenefitTransfer =>
      isHindi ? 'प्रत्यक्ष लाभ अंतरण (DBT)' : 'Direct Benefit Transfer (DBT)';
  String get trustDpdpCompliant =>
      isHindi ? 'गोपनीय एवं सुरक्षित • DPDP अधिनियम 2023' : 'Private & Secure • DPDP Act 2023';

  // Categories
  String categoryName(String englishName) {
    if (!isHindi) return englishName;
    return switch (englishName.toLowerCase()) {
      'agriculture' || 'agriculture & rural' => 'कृषि एवं ग्रामीण',
      'education' || 'education & learning' => 'शिक्षा एवं कौशल',
      'health' || 'health & healthcare' => 'स्वास्थ्य एवं चिकित्सा',
      'housing' || 'housing & shelter' => 'आवास एवं आश्रय',
      'employment' || 'employment & business' => 'रोजगार एवं व्यवसाय',
      'women' || 'women & child development' => 'महिला एवं बाल विकास',
      'social' || 'social welfare & inclusion' => 'सामाजिक कल्याण',
      'senior' || 'senior citizens' => 'वरिष्ठ नागरिक',
      'disability' || 'disability support' => 'दिव्यांगजन सहायता',
      'tribal' || 'tribal affairs' => 'जनजातीय कार्य',
      'banking' || 'banking & financial services' => 'वित्तीय सेवाएं',
      _ => englishName,
    };
  }

  // Scheme Actions & Badges
  String get viewDetails => isHindi ? 'विवरण देखें' : 'View details';
  String get checkEligibility => isHindi ? 'पात्रता जांचें' : 'Check eligibility';
  String get applyOnPortal => isHindi ? 'आधिकारिक पोर्टल पर आवेदन करें' : 'Apply on official portal';
  String get savedSchemes => isHindi ? 'सहेजी गई योजनाएं' : 'Saved schemes';
  String get saveScheme => isHindi ? 'सहेजें' : 'Save';
  String get likelyEligible => isHindi ? 'संभावित पात्र' : 'Likely eligible';
  String get notEligible => isHindi ? 'पात्र नहीं' : 'Not eligible';
  String get unknownEligibility => isHindi ? 'जांच आवश्यक' : 'Check required';
  String get verifiedByMinistry => isHindi ? 'मंत्रालय सत्यापित' : 'Verified';

  // AI Assistant
  String get assistantTitle => isHindi ? 'कल्याण एआई सहायक' : 'Welfare AI Assistant';
  String get assistantSubtitle => isHindi
      ? 'सरकारी योजनाओं व पात्रता के बारे में सीधे पूछें'
      : 'Grounded citizen assistant for Indian welfare schemes';
  String get assistantInputHint =>
      isHindi ? 'योजनाओं या पात्रता के बारे में पूछें...' : 'Ask about schemes, eligibility, or benefits...';
  String get assistantThinking => 'Thinking…';
  String get assistantTrustBanner => isHindi
      ? 'पारदर्शी व सत्यापित डेटा • सभी उत्तर आधिकारिक नियमों पर आधारित हैं'
      : 'Grounded in verified scheme rules. No hallucinations, no guessing.';
  String get assistantPrompt1 =>
      isHindi ? 'क्या मैं पीएम-किसान सम्मान निधि के लिए पात्र हूँ?' : 'Am I eligible for PM-Kisan Samman Nidhi?';
  String get assistantPrompt2 =>
      isHindi ? 'छोटे व्यवसायों और दुकानों के लिए सरकारी सब्सिडी' : 'Subsidies available for small businesses';
  String get assistantPrompt3 =>
      isHindi ? 'उच्च शिक्षा और तकनीकी पढ़ाई के लिए छात्रवृत्ति' : 'Scholarships for higher education';
  String get assistantPrompt4 =>
      isHindi ? 'ग्रामीण आवास योजना के लिए कौन से दस्तावेज चाहिए?' : 'Documents required for rural housing scheme';

  // Common UI
  String get continueText => isHindi ? 'आगे बढ़ें' : 'Continue';
  String get getStarted => isHindi ? 'शुरू करें' : 'Get started';
  String get skip => isHindi ? 'छोड़ें' : 'Skip';
  String get languageLabel => isHindi ? 'भाषा' : 'Language';
  String get appearanceLabel => isHindi ? 'दिखावट' : 'Appearance';
  String get signIn => isHindi ? 'साइन इन करें' : 'Sign in';
  String get signOut => isHindi ? 'साइन आउट' : 'Sign out';
  String get createAccount => isHindi ? 'खाता बनाएं' : 'Create account';
  String get retry => isHindi ? 'पुनः प्रयास करें' : 'Retry';
}

final stringsProvider = Provider<AppStrings>((ref) {
  final lang = ref.watch(languageProvider);
  return AppStrings(lang);
});
