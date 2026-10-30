import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schememedia_app/features/notifications/domain/scheme_notification.dart';
import 'package:schememedia_app/features/notifications/presentation/providers/notifications_providers.dart';

void main() {
  group('NotificationsNotifier', () {
    test('initializes with seed notifications including quota caps and expiring deadlines', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifs = container.read(notificationsProvider);
      expect(notifs, isNotEmpty);
      expect(notifs.any((n) => n.category == NotificationCategory.quotaCap), isTrue);
      expect(notifs.any((n) => n.category == NotificationCategory.expiringDeadline), isTrue);

      final unreadCount = container.read(unreadNotificationsCountProvider);
      expect(unreadCount, greaterThan(0));
    });

    test('markAsRead marks specific notification as read and decrements unreadCount', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initialUnread = container.read(unreadNotificationsCountProvider);
      final firstUnread = container.read(notificationsProvider).firstWhere((n) => !n.isRead);

      container.read(notificationsProvider.notifier).markAsRead(firstUnread.id);

      final updated = container.read(notificationsProvider).firstWhere((n) => n.id == firstUnread.id);
      expect(updated.isRead, isTrue);
      expect(container.read(unreadNotificationsCountProvider), initialUnread - 1);
    });

    test('markAllAsRead marks all notifications as read', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(notificationsProvider.notifier).markAllAsRead();

      expect(container.read(unreadNotificationsCountProvider), 0);
      expect(container.read(notificationsProvider).every((n) => n.isRead), isTrue);
    });
  });
}
