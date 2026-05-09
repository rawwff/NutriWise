import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'database_helper.dart';

/// Handles push notifications for low-stock and expiring inventory items.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings: initSettings);
    _initialized = true;
  }

  /// Show a notification immediately.
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'nutriwise_inventory',
      'Inventori NutriWise',
      channelDescription: 'Notifikasi untuk bahan makanan yang hampir habis',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
        id: id, title: title, body: body, notificationDetails: details);
  }

  /// Check inventory and notify about low-stock / expiring items.
  static Future<void> checkAndNotify(String userId) async {
    final dbHelper = DatabaseHelper.instance;

    // Check low stock items
    final lowStockItems = await dbHelper.getLowStockItems(userId);
    if (lowStockItems.isNotEmpty) {
      final names =
          lowStockItems.map((item) => item['name'] as String).take(3).toList();
      final message = names.join(', ');
      final extra = lowStockItems.length > 3
          ? ' dan ${lowStockItems.length - 3} lainnya'
          : '';

      await showNotification(
        id: 1001,
        title: '⚠️ Bahan Makanan Hampir Habis!',
        body: '$message$extra perlu diisi ulang.',
      );
    }

    // Check expiring items (within 3 days)
    final expiringItems = await dbHelper.getExpiringItems(userId, 3);
    if (expiringItems.isNotEmpty) {
      final names =
          expiringItems.map((item) => item['name'] as String).take(3).toList();
      final message = names.join(', ');
      final extra = expiringItems.length > 3
          ? ' dan ${expiringItems.length - 3} lainnya'
          : '';

      await showNotification(
        id: 1002,
        title: '🕐 Bahan Makanan Segera Kedaluwarsa!',
        body: '$message$extra akan kedaluwarsa dalam 3 hari.',
      );
    }
  }
}
