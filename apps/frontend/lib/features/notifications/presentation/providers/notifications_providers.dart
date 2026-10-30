import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/scheme_notification.dart';

final _initialNotifications = [
  SchemeNotification(
    id: 'notif-1',
    schemeId: 'pm-kusum-component-b',
    schemeName: 'PM-KUSUM Solar Agricultural Pumps',
    title: 'Limited Seats: Only 10 Registration Slots Left',
    titleHi: 'सीमित सीटें: आपके जिले में केवल 10 स्लॉट शेष',
    message: 'Your district registration capacity has reached 90%. Only 10 beneficiary subsidy slots remain for this round.',
    messageHi: 'आपके जिले में 90% कोटा भर चुका है। इस वित्तीय चक्र के लिए केवल 10 सब्सिडी स्लॉट शेष हैं।',
    urgency: NotificationUrgency.high,
    category: NotificationCategory.quotaCap,
    quotaRemaining: 'Only 10 slots left',
    quotaRemainingHi: 'केवल 10 सीटें शेष',
    deadline: 'Closing soon',
    deadlineHi: 'जल्द समाप्त',
    createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
    isRead: false,
  ),
  SchemeNotification(
    id: 'notif-2',
    schemeId: 'pm-fasal-bima-yojana',
    schemeName: 'Pradhan Mantri Fasal Bima Yojana',
    title: 'Deadline Approaching: Registration Expires in 14 Days',
    titleHi: 'समय सीमा निकट: 14 दिनों में पंजीकरण समाप्त',
    message: 'Kharif crop enrollment portal closes on 15th next month. Eligible farmers are advised to submit land records now.',
    messageHi: 'खरीफ फसल बीमा पोर्टल अगले महीने की 15 तारीख को बंद हो जाएगा। पात्र किसान तुरंत खसरा/खतौनी विवरण जमा करें।',
    urgency: NotificationUrgency.high,
    category: NotificationCategory.expiringDeadline,
    quotaRemaining: null,
    deadline: 'Expires in 14 days',
    deadlineHi: '14 दिनों में समाप्त',
    createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    isRead: false,
  ),
  SchemeNotification(
    id: 'notif-3',
    schemeId: 'pm-kisan-samman-nidhi',
    schemeName: 'PM Kisan Samman Nidhi',
    title: 'New Matched Scheme: 100% Profile Match',
    titleHi: 'नई योजना मेल: आपकी प्रोफ़ाइल से 100% मेल',
    message: 'Based on your registered profile (Farmer, Landowner), you qualify for ₹6,000 annual direct income support.',
    messageHi: 'आपकी प्रोफ़ाइल (किसान, भूमिधारक) के आधार पर आप ₹6,000 वार्षिक वित्तीय सहायता के पूर्ण पात्र हैं।',
    urgency: NotificationUrgency.medium,
    category: NotificationCategory.profileMatch,
    quotaRemaining: 'Active Grant',
    quotaRemainingHi: 'सक्रिय अनुदान',
    deadline: 'Open Year-Round',
    deadlineHi: 'वर्ष भर खुला',
    createdAt: DateTime.now().subtract(const Duration(hours: 8)),
    isRead: false,
  ),
  SchemeNotification(
    id: 'notif-4',
    schemeId: 'national-apprenticeship-promotion-scheme',
    schemeName: 'National Apprenticeship Promotion Scheme',
    title: 'Fast-Filling Quota: Youth Stipend Batch',
    titleHi: 'तेजी से भरता कोटा: युवा वजीफा बैच',
    message: 'Industry apprentice training quota in your region has 25 seats remaining for certified graduates.',
    messageHi: 'आपके क्षेत्र में औद्योगिक प्रशिक्षुता प्रशिक्षण कोटे में प्रमाणित युवाओं के लिए 25 सीटें बची हैं।',
    urgency: NotificationUrgency.normal,
    category: NotificationCategory.quotaCap,
    quotaRemaining: '25 seats remaining',
    quotaRemainingHi: '25 सीटें शेष',
    deadline: '1 month left',
    deadlineHi: '1 माह शेष',
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    isRead: true,
  ),
];

class NotificationsNotifier extends StateNotifier<List<SchemeNotification>> {
  NotificationsNotifier() : super(_initialNotifications);

  int get unreadCount => state.where((n) => !n.isRead).length;

  void markAsRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(isRead: true) else n,
    ];
  }

  void markAllAsRead() {
    state = [
      for (final n in state) n.copyWith(isRead: true),
    ];
  }

  void removeNotification(String id) {
    state = state.where((n) => n.id != id).toList();
  }

  void clearAll() {
    state = [];
  }
}

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, List<SchemeNotification>>((ref) {
  return NotificationsNotifier();
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(notificationsProvider);
  return notifs.where((n) => !n.isRead).length;
});
