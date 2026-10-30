import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/scheme_notification.dart';
import '../providers/notifications_providers.dart';

class NotificationCenterSheet extends ConsumerStatefulWidget {
  const NotificationCenterSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NotificationCenterSheet(),
    );
  }

  @override
  ConsumerState<NotificationCenterSheet> createState() => _NotificationCenterSheetState();
}

class _NotificationCenterSheetState extends ConsumerState<NotificationCenterSheet> {
  bool _filterUrgentOnly = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final lang = ref.watch(languageProvider);
    final isHindi = lang == AppLanguage.hindi;
    final notifications = ref.watch(notificationsProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    final filtered = _filterUrgentOnly
        ? notifications.where((n) => n.urgency == NotificationUrgency.high).toList()
        : notifications;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: colors.brandTint,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(Icons.notifications_active_rounded, color: colors.brand, size: 20),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isHindi ? 'योजना सूचनाएं एवं अलर्ट' : 'Welfare Alerts & Quotas',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                          if (unreadCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDC2626),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        isHindi
                          ? 'सीट क्षमता, समय सीमा और नए मैच अलर्ट'
                          : 'Capacity limits, expiring deadlines & matches',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (unreadCount > 0)
                  TextButton(
                    onPressed: () => ref.read(notificationsProvider.notifier).markAllAsRead(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(
                      isHindi ? 'सभी पढ़ें' : 'Mark all read',
                      style: TextStyle(fontSize: 12, color: colors.brand),
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Filter toggles
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 8),
            child: Row(
              children: [
                ChoiceChip(
                  label: Text(isHindi ? 'सभी (${notifications.length})' : 'All (${notifications.length})'),
                  selected: !_filterUrgentOnly,
                  onSelected: (_) => setState(() => _filterUrgentOnly = false),
                  backgroundColor: colors.surfaceMuted,
                  selectedColor: colors.primaryAction,
                  labelStyle: TextStyle(
                    color: !_filterUrgentOnly ? colors.onPrimaryAction : colors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: !_filterUrgentOnly ? colors.primaryAction : colors.divider),
                  ),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFDC2626)),
                      const SizedBox(width: 4),
                      Text(isHindi ? 'अति महत्वपूर्ण / अंतिम समय' : 'Urgent & Expiring'),
                    ],
                  ),
                  selected: _filterUrgentOnly,
                  onSelected: (_) => setState(() => _filterUrgentOnly = true),
                  backgroundColor: colors.surfaceMuted,
                  selectedColor: const Color(0xFFDC2626),
                  labelStyle: TextStyle(
                    color: _filterUrgentOnly ? Colors.white : colors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: _filterUrgentOnly ? const Color(0xFFDC2626) : colors.divider),
                  ),
                ),
              ],
            ),
          ),

          // Notification List
          Flexible(
            child: filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.done_all_rounded, size: 48, color: colors.textTertiary),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          isHindi ? 'कोई नई सूचना नहीं है' : 'All caught up!',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isHindi
                              ? 'जब भी आपकी पात्रता से मेल खाने वाली योजना या सीट सीमा का अलर्ट होगा, वह यहां दिखेगा।'
                              : 'Upcoming quota caps, expiring dates, and matches will be notified here.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _NotificationCard(
                        item: item,
                        isHindi: isHindi,
                        onTap: () {
                          ref.read(notificationsProvider.notifier).markAsRead(item.id);
                          Navigator.of(context).pop();
                          context.push(AppRoutes.schemeDetailPath(item.schemeId));
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.isHindi,
    required this.onTap,
  });

  final SchemeNotification item;
  final bool isHindi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final urgencyColor = item.urgency.color(theme.colorScheme);
    final badgeBg = item.urgency.badgeBg(theme.colorScheme);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: item.isRead ? colors.surface : colors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: item.isRead ? colors.divider : colors.brand.withValues(alpha: 0.35),
            width: item.isRead ? 1 : 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(item.category.icon, size: 16, color: urgencyColor),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.localizedTitle(isHindi),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.schemeName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colors.brand,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!item.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 4, left: 4),
                    decoration: BoxDecoration(
                      color: colors.brand,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.localizedMessage(isHindi),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (item.localizedQuota(isHindi) != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: urgencyColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: urgencyColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt, size: 12, color: urgencyColor),
                        const SizedBox(width: 4),
                        Text(
                          item.localizedQuota(isHindi)!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: urgencyColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                if (item.localizedDeadline(isHindi) != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colors.surfaceMuted,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: colors.divider),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.schedule, size: 12, color: colors.textTertiary),
                        const SizedBox(width: 4),
                        Text(
                          item.localizedDeadline(isHindi)!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  isHindi ? 'देखें →' : 'View Scheme →',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: colors.primaryAction,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
