import 'package:flutter/material.dart';

enum NotificationUrgency {
  high,
  medium,
  normal;

  Color color(ColorScheme scheme) {
    return switch (this) {
      NotificationUrgency.high => const Color(0xFFDC2626), // red
      NotificationUrgency.medium => const Color(0xFFEA580C), // orange
      NotificationUrgency.normal => const Color(0xFF0284C7), // sky blue
    };
  }

  Color badgeBg(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    return switch (this) {
      NotificationUrgency.high => isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.35) : const Color(0xFFFEF2F2),
      NotificationUrgency.medium => isDark ? const Color(0xFF7C2D12).withValues(alpha: 0.35) : const Color(0xFFFFF7ED),
      NotificationUrgency.normal => isDark ? const Color(0xFF0C4A6E).withValues(alpha: 0.35) : const Color(0xFFF0F9FF),
    };
  }
}

enum NotificationCategory {
  quotaCap,
  expiringDeadline,
  profileMatch,
  update;

  IconData get icon {
    return switch (this) {
      NotificationCategory.quotaCap => Icons.group_off_rounded,
      NotificationCategory.expiringDeadline => Icons.timer_outlined,
      NotificationCategory.profileMatch => Icons.auto_awesome_rounded,
      NotificationCategory.update => Icons.campaign_rounded,
    };
  }
}

class SchemeNotification {
  const SchemeNotification({
    required this.id,
    required this.schemeId,
    required this.schemeName,
    required this.title,
    required this.titleHi,
    required this.message,
    required this.messageHi,
    required this.urgency,
    required this.category,
    this.quotaRemaining,
    this.quotaRemainingHi,
    this.deadline,
    this.deadlineHi,
    required this.createdAt,
    this.isRead = false,
  });

  final String id;
  final String schemeId;
  final String schemeName;
  final String title;
  final String titleHi;
  final String message;
  final String messageHi;
  final NotificationUrgency urgency;
  final NotificationCategory category;
  final String? quotaRemaining;
  final String? quotaRemainingHi;
  final String? deadline;
  final String? deadlineHi;
  final DateTime createdAt;
  final bool isRead;

  String localizedTitle(bool isHindi) => isHindi ? titleHi : title;
  String localizedMessage(bool isHindi) => isHindi ? messageHi : message;
  String? localizedQuota(bool isHindi) => isHindi ? (quotaRemainingHi ?? quotaRemaining) : quotaRemaining;
  String? localizedDeadline(bool isHindi) => isHindi ? (deadlineHi ?? deadline) : deadline;

  SchemeNotification copyWith({
    bool? isRead,
  }) {
    return SchemeNotification(
      id: id,
      schemeId: schemeId,
      schemeName: schemeName,
      title: title,
      titleHi: titleHi,
      message: message,
      messageHi: messageHi,
      urgency: urgency,
      category: category,
      quotaRemaining: quotaRemaining,
      quotaRemainingHi: quotaRemainingHi,
      deadline: deadline,
      deadlineHi: deadlineHi,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
