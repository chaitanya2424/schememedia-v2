import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/language_repository.dart';
export '../local/language_repository.dart';

/// Centralized strings dictionary for English and Hindi localization.
class AppStrings {
  const AppStrings(this.language);

  factory AppStrings.of(AppLanguage language) => AppStrings(language);

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
  String get allSchemes => isHindi ? 'सभी योजनाएं' : 'All schemes';
  String get trendingSearches => isHindi ? 'लोकप्रिय खोजें' : 'Trending';
  String get popularPrefix => isHindi ? 'लोकप्रिय: ' : 'Popular: ';
  String get verifiedSchemesAvailable =>
      isHindi ? 'सत्यापित योजनाएं उपलब्ध' : 'verified schemes available';

  // Home Hero Card
  String get heroPickedForYou => isHindi ? 'आपके लिए विशेष योजनाएं' : 'Picked for you';
  String get heroRecommended => isHindi ? 'पात्रता अनुसार अनुशंसित' : 'Recommended for you';
  String get heroBuildProfile => isHindi ? 'अपनी पात्रता प्रोफ़ाइल बनाएं' : 'Build your profile';
  String get heroMatchingSchemes =>
      isHindi ? 'योजनाएं आपकी पात्रता से मेल खाती हैं' : 'matching schemes found for your profile';
  String get heroAnswerQuestions => isHindi
      ? 'सटीक और व्यक्तिगत योजनाएं खोजने के लिए प्रश्नों के उत्तर दें।'
      : 'Answer questions to discover exact welfare benefits tailored to you.';
  String get viewMatches => isHindi ? 'योजनाएं देखें' : 'View matches';
  String get startProfile => isHindi ? 'शुरू करें' : 'Start';
  String get updateProfile => isHindi ? 'अपडेट करें' : 'Update';
  String get askAssistant => isHindi ? 'सहायक से पूछें' : 'Ask Assistant';

  // Trust Metrics
  String get trustSchemesCount => '1,000+';
  String get trustSchemesLabel => isHindi ? 'कल्याणकारी योजनाएं' : 'Welfare Schemes';
  String get trustStatesCount => isHindi ? '28 राज्य' : '28 States';
  String get trustStatesLabel => isHindi ? 'केंद्रीय एवं राज्य' : 'Central & State';
  String get trustFreeCount => isHindi ? '100% निःशुल्क' : '100% Free';
  String get trustFreeLabel => isHindi ? 'नागरिक प्रत्यक्ष' : 'Citizen Direct';

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
      'women' || 'women & child development' || 'women welfare' => 'महिला एवं बाल विकास',
      'social' || 'social welfare & inclusion' || 'social welfare' => 'सामाजिक कल्याण',
      'senior' || 'senior citizens' => 'वरिष्ठ नागरिक',
      'disability' || 'disability support' => 'दिव्यांगजन सहायता',
      'tribal' || 'tribal affairs' => 'जनजातीय कार्य',
      'banking' || 'banking & financial services' => 'वित्तीय सेवाएं',
      'business & entrepreneurship' => 'व्यवसाय एवं उद्यम',
      'insurance' => 'बीमा एवं सुरक्षा',
      'sports & culture' => 'खेल एवं संस्कृति',
      'general' => 'सामान्य कल्याण',
      _ => englishName,
    };
  }

  // Scheme Actions & Badges
  String get viewDetails => isHindi ? 'विवरण देखें' : 'View details';
  String get checkEligibility => isHindi ? 'पात्रता जांचें' : 'Check eligibility';
  String get seeEligibility => isHindi ? 'पात्रता देखें' : 'See eligibility';
  String get applyOnPortal => isHindi ? 'आधिकारिक पोर्टल पर आवेदन करें' : 'Apply on official portal';
  String get savedSchemes => isHindi ? 'सहेजी गई योजनाएं' : 'Saved schemes';
  String get saveScheme => isHindi ? 'सहेजें' : 'Save';
  String get saved => isHindi ? 'सहेजा गया' : 'Saved';
  String get likelyEligible => isHindi ? 'संभावित पात्र' : 'Likely eligible';
  String get notEligible => isHindi ? 'पात्र नहीं' : 'Not eligible';
  String get unknownEligibility => isHindi ? 'जांच आवश्यक' : 'Check required';
  String get verifiedByMinistry => isHindi ? 'मंत्रालय सत्यापित' : 'Verified';
  String get centralSector => isHindi ? 'केंद्रीय क्षेत्र' : 'Central Sector';
  String get stateSector => isHindi ? 'राज्य क्षेत्र' : 'State Sector';

  // Search & Explore
  String get exploreTitle => isHindi ? 'कल्याणकारी योजनाएं खोजें' : 'Explore Welfare Schemes';
  String get publicSchemesDirectory =>
      isHindi ? 'सार्वजनिक योजना निर्देशिका' : 'PUBLIC SCHEMES DIRECTORY';
  String get searchByNeed =>
      isHindi ? 'मंत्रालय नहीं, जरूरत के अनुसार योजनाएं खोजें।' : 'Find schemes by need, not ministry.';
  String get searchDescription => isHindi
      ? 'केंद्रीय व राज्य लाभ, नकद सब्सिडी और शैक्षणिक अनुदान खोजें।'
      : 'Search through central and state benefits, cash subsidies, and educational grants.';
  String get searchSchemesHint =>
      isHindi ? 'योजनाएं, लाभ या दस्तावेज खोजें...' : 'Search schemes, benefits, or documents...';
  String get searchSuggestions => isHindi ? 'सुझाव: ' : 'Suggestions: ';
  String get allFilter => isHindi ? 'सभी' : 'All';
  String get sortBy => isHindi ? 'क्रमबद्ध करें' : 'Sort by';
  String get sortAndFilters => isHindi ? 'क्रमबद्ध और फ़िल्टर' : 'Sort & Filters';
  String get clear => isHindi ? 'हटाएं' : 'Clear';
  String get popularWelfareDomains => isHindi ? 'प्रमुख कल्याणकारी क्षेत्र' : 'Popular Welfare Domains';
  String get sortSchemes => isHindi ? 'योजनाएं क्रमबद्ध करें' : 'Sort schemes';
  String get relevanceMatch =>
      isHindi ? 'सटीकता अनुसार (अनुशंसित)' : 'Relevance match (Recommended)';
  String get relevanceSubtitle => isHindi
      ? 'एआई से आपकी खोज के अनुकूल योजनाएं'
      : 'Ranks schemes by AI semantic match to your query';
  String get nameAtoZ => isHindi ? 'नाम: अ से ज्ञ (A to Z)' : 'Name, A to Z';
  String get nameAtoZSubtitle => isHindi
      ? 'योजना के आधिकारिक शीर्षक अनुसार वर्णमाला क्रम'
      : 'Alphabetical order by official scheme title';
  String schemesFound(int count) => count == 1
      ? (isHindi ? '1 योजना मिली' : '1 scheme found')
      : (isHindi ? '$count योजनाएं मिलीं' : '$count schemes found');
  String verifiedCount(int count) => isHindi ? '$count सत्यापित' : '$count Verified';
  String noSchemesMatched(String query) =>
      isHindi ? '"$query" के लिए कोई योजना नहीं मिली' : 'No schemes matched "$query"';
  String get tryDifferentKeywords => isHindi
      ? 'कृपया अन्य कीवर्ड से प्रयास करें या नीचे दी गई श्रेणियां देखें।'
      : 'Try a broader keyword, or explore popular categories below.';

  // Home Screen extra
  String get viewAll => isHindi ? 'सभी देखें' : 'View all';
  String get profileConfidence => isHindi ? 'प्रोफ़ाइल सटीकता' : 'Profile Confidence';
  String get dpdpTitle => isHindi ? 'DPDP 2023 अनुपालित' : 'DPDP 2023 Compliant';
  String get dpdpSubtitle => isHindi
      ? 'आपकी जानकारी सुरक्षित है और केवल आपके डिवाइस पर जांची जाती है।'
      : 'Your attributes are encrypted and evaluated deterministically on-device.';
  String get quickShortcuts => isHindi ? 'त्वरित शॉर्टकट' : 'Quick Shortcuts';
  String get shortcutSearch => isHindi ? 'योजनाएं खोजें' : 'Search for schemes';
  String get shortcutRecommendations => isHindi ? 'मेरी सिफारिशें देखें' : 'See my recommendations';
  String get shortcutAssistant => isHindi ? 'सहायक से पूछें' : 'Ask the assistant';
  String get shortcutSaved => isHindi ? 'सहेजी गई योजनाएं देखें' : 'View saved schemes';
  String get startQuestionnaire => isHindi ? 'प्रश्नावली शुरू करें' : 'Start Questionnaire';
  String reviewDetails(int count) => isHindi
      ? '$count विवरणों की समीक्षा करें'
      : 'Review $count Detail${count == 1 ? '' : 's'}';

  // AI Assistant
  String get assistantTitle => isHindi ? 'कल्याण एआई सहायक' : 'Welfare AI Assistant';
  String get assistantSubtitle => isHindi
      ? 'सरकारी योजनाओं व पात्रता के बारे में सीधे पूछें'
      : 'Grounded citizen assistant for Indian welfare schemes';
  String get assistantInputHint => isHindi
      ? 'योजना, लाभ या पात्रता के बारे में पूछें…'
      : 'Ask about a scheme, benefit, or eligibility…';
  String get assistantThinking => 'Thinking…';
  String get assistantTrustBanner => isHindi
      ? 'पारदर्शी व सत्यापित डेटा • सभी उत्तर आधिकारिक नियमों पर आधारित हैं'
      : 'Grounded in verified scheme rules. No hallucinations, no guessing.';
  String get sendMessageTooltip => isHindi ? 'संदेश भेजें' : 'Send message';
  String get sendingTooltip => isHindi ? 'भेजा जा रहा है...' : 'Sending…';
  String get hideQuestionIdeas => isHindi ? 'सुझाव छिपाएं' : 'Hide question ideas';
  String get moreQuestionIdeas => isHindi ? 'अन्य प्रश्न सुझाव' : 'More question ideas';
  String get askThenUnderstand => isHindi ? 'पूछें, और स्पष्ट समझें।' : 'Ask, then understand.';
  String get assistantHeadlineSubtitle => isHindi
      ? 'मैं आधिकारिक नियमों का संदर्भ दूंगा, पात्रता स्पष्ट करूंगा और कभी अनुमान नहीं लगाऊंगा।'
      : "I'll point to the rule, explain the uncertainty and never guess on your behalf.";
  String get whatWouldYouLikeToKnow =>
      isHindi ? 'आप क्या जानना चाहते हैं?' : 'What would you like to know?';
  String get assistantCardSubtitle => isHindi
      ? 'किसी योजना, लाभ या पात्रता दस्तावेजों के बारे में प्रश्न पूछें।'
      : 'Try a question about a scheme, a benefit or the documents you may need.';
  String get answersGrounded =>
      isHindi ? 'उत्तर आधिकारिक स्रोतों पर आधारित हैं' : 'Answers are grounded in sources';
  String get answersGroundedSubtitle => isHindi
      ? 'हम जानकारी का स्रोत दिखाते हैं ताकि आप स्वयं पुष्टि कर सकें।'
      : 'We show you where the information comes from so you can check it yourself.';
  String get replyAccuracyWarning =>
      isHindi ? 'यह उत्तर पूरी तरह सटीक नहीं हो सकता:' : 'This reply may not be fully accurate:';
  String get hideSources => isHindi ? 'स्रोत छिपाएं' : 'Hide sources';
  String sourcesWithCount(int count) => isHindi ? 'स्रोत ($count)' : 'Sources ($count)';

  // Scheme Details & Explanations
  String get aboutScheme => isHindi ? 'योजना के बारे में' : 'About';
  String get whatYouMayReceive => isHindi ? 'आपको क्या लाभ मिलेगा' : 'What you may receive';
  String get eligibilityExplained => isHindi ? 'पात्रता विवरण' : 'Eligibility, explained';
  String get keepTheseReady => isHindi ? 'यह दस्तावेज तैयार रखें' : 'Keep these ready';
  String get visitOfficialPage => isHindi ? 'आधिकारिक पोर्टल पर जाएं' : 'Visit official page';
  String get whyThisLooksPromising =>
      isHindi ? 'यह आपके लिए उपयुक्त क्यों है' : 'Why this looks promising for you';
  String get whyThisScheme => isHindi ? 'यह योजना क्यों?' : 'Why this scheme?';
  String get hideDetails => isHindi ? 'विवरण छिपाएं' : 'Hide details';
  String get hideEligibilityDetails => isHindi ? 'पात्रता विवरण छिपाएं' : 'Hide eligibility details';
  String whyWithCount(int count) => isHindi ? 'क्यों? ($count)' : 'Why? ($count)';
  String unknownWithCount(int count) => isHindi ? '$count अस्पष्ट' : '$count unknown';
  String get matchedFromProfile =>
      isHindi ? 'आपकी प्रोफ़ाइल से मेल खाता है' : 'Matched from your profile';
  String get doesNotMatchProfile =>
      isHindi ? 'आपकी प्रोफ़ाइल से मेल नहीं खाता' : "Doesn't match your profile";
  String get weDontHaveThisYet =>
      isHindi ? 'इसकी जानकारी अभी उपलब्ध नहीं है' : "We don't have this yet";
  String get notApplicable => isHindi ? 'लागू नहीं' : 'Not applicable';
  String get checkAction => isHindi ? 'जांचें' : 'Check';
  String get saveForLater => isHindi ? 'बाद के लिए सहेजें' : 'Save for later';
  String get removeFromSaved => isHindi ? 'सहेजे गए से हटाएं' : 'Remove from saved';
  String get ministryLabel => isHindi ? 'मंत्रालय / विभाग' : 'Ministry';
  String get categoryLabel => isHindi ? 'श्रेणी' : 'Category';
  String get jurisdictionFieldLabel => isHindi ? 'क्षेत्राधिकार' : 'Jurisdiction';
  String get applicationDeadlineLabel => isHindi ? 'आवेदन की अंतिम तिथि' : 'Application deadline';
  String get savesStat => isHindi ? 'सहेजे' : 'saves';
  String get commentsStat => isHindi ? 'टिप्पणियां' : 'comments';
  String get likesStat => isHindi ? 'पसंद' : 'likes';
  String get averageRatingStat => isHindi ? 'औसत रेटिंग' : 'average rating';
  String get governmentOfIndia => isHindi ? 'भारत सरकार' : 'Government of India';
  String get stateGovernment => isHindi ? 'राज्य सरकार' : 'State government';
  String stateWithCode(String code) => isHindi ? 'राज्य ($code)' : 'State ($code)';
  String get centralGov => isHindi ? 'केंद्रीय सरकार' : 'Central';
  String get stateGov => isHindi ? 'राज्य' : 'State';

  // Profile Screen
  String get profileTitle => isHindi ? 'प्रोफ़ाइल' : 'Profile';
  String get yourEligibilityProfile => isHindi ? 'आपकी पात्रता प्रोफ़ाइल' : 'Your eligibility profile';
  String get onThisDevice => isHindi ? 'इस डिवाइस पर' : 'On this device';
  String get preferences => isHindi ? 'प्राथमिकताएं' : 'Preferences';
  String get aboutApp => isHindi ? 'ऐप के बारे में' : 'About';
  String get notSignedIn => isHindi ? 'साइन इन नहीं हैं' : 'Not signed in';
  String get signInSubtitle => isHindi
      ? 'प्रोफ़ाइल और सहेजी गई योजनाओं को सुरक्षित रखने के लिए साइन इन करें।'
      : 'Sign in to sync your profile and saved schemes across devices.';
  String get signInOrCreate => isHindi ? 'साइन इन / खाता बनाएं' : 'Sign in / Create Account';
  String get signOut => isHindi ? 'साइन आउट' : 'Sign out';
  String get updatesAboutNewSchemes => isHindi ? 'नई योजनाओं की जानकारी' : 'Updates about new schemes';
  String get languageLabel => isHindi ? 'भाषा' : 'Language';
  String get appearanceLabel => isHindi ? 'दिखावट' : 'Appearance';

  // Archetypes & Express Profile Setup
  String get oneTapProfiles => isHindi ? '1-क्लिक नागरिक प्रोफाइल' : '1-Tap Citizen Profiles';
  String get oneTapPresets => isHindi ? '1-क्लिक प्रोफाइल' : '1-Tap Profiles';
  String get quickQuiz => isHindi ? '30-सेकंड क्विज़' : '30-Sec Quiz';
  String get expressProfileSetup =>
      isHindi ? 'त्वरित 30-सेकंड प्रोफ़ाइल' : '30-Sec Express Profile';

  // Offline Profile-Tailored Welfare Pocket
  String get offlineMode => isHindi ? 'ऑफ़लाइन मोड' : 'Offline Mode';
  String get offlineReady => isHindi ? 'ऑफ़लाइन तैयार' : 'Offline Ready';
  String get offlinePocketTitle =>
      isHindi ? 'ऑफ़लाइन कल्याण पॉकेट' : 'Offline Welfare Pocket';
  String offlineProfileSchemesCount(int count, String profile) => isHindi
      ? '$count $profile योजनाएं बिना इंटरनेट उपलब्ध'
      : '$count $profile schemes available offline';
  String get offlinePocketSubtitle => isHindi
      ? 'आपकी प्रोफ़ाइल के आधार पर सुरक्षित की गई योजनाएं। बिना इंटरनेट क्षेत्र में भी उपयोगी।'
      : 'Saved for your profile. Full details & criteria ready without cellular data.';

  // Common UI
  String get continueText => isHindi ? 'आगे बढ़ें' : 'Continue';
  String get getStarted => isHindi ? 'शुरू करें' : 'Get started';
  String get skip => isHindi ? 'छोड़ें' : 'Skip';
  String get signIn => isHindi ? 'साइन इन करें' : 'Sign in';
  String get createAccount => isHindi ? 'खाता बनाएं' : 'Create account';
  String get retry => isHindi ? 'पुनः प्रयास करें' : 'Retry';
}


final stringsProvider = Provider<AppStrings>((ref) {
  final lang = ref.watch(languageProvider);
  return AppStrings(lang);
});
