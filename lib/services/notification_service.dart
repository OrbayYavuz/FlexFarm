import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static final SupabaseClient _supabase = Supabase.instance.client;
  static Function(String?)? _onTap;
  static bool _initialized = false;

  /// Bildirim servisini başlat
  static Future<void> initialize({Function(String?)? onNotificationTap}) async {
    if (_initialized) return;
    _onTap = onNotificationTap;

    // Timezone verilerini yükle
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));

    // Android ayarları
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS ayarları
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    final initialized = await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    if (initialized != true) {
      print('Bildirim servisi başlatılamadı!');
      return;
    }

    // Android için kanal oluştur
    const androidChannel = AndroidNotificationChannel(
      'reminders_v3',
      'Mahsul Hatırlatıcıları',
      description: 'Zamanlanmış mahsul ve hasat bildirimleri',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // Android için izinleri kontrol et ve iste
    if (Platform.isAndroid) {
      await _requestAndroidPermissions();
    }

    _initialized = true;
    print('Bildirim servisi başarıyla başlatıldı');
  }

  /// Android izinlerini kontrol et ve iste
  static Future<void> _requestAndroidPermissions() async {
    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      // Bildirim izni (Android 13+)
      final granted = await androidImplementation.requestNotificationsPermission();
      if (granted == true) {
        print('Bildirim izni verildi');
      } else {
        print('Bildirim izni reddedildi');
      }

      // Exact alarm izni (Android 12+)
      final exactAlarmGranted = await androidImplementation.requestExactAlarmsPermission();
      if (exactAlarmGranted == true) {
        print('Exact alarm izni verildi');
      } else {
        print('Exact alarm izni reddedildi - bildirimler tam zamanında gelmeyebilir');
      }
    }
  }

  /// Bildirim tıklandığında
  static void _onNotificationTapped(NotificationResponse response) {
    // Bildirim tıklandığında yapılacak işlemler
    print('Bildirim tıklandı: ${response.payload}');
    if (_onTap != null) {
      _onTap!(response.payload);
    }
  }

  /// DateTime'ı TZDateTime'a çevir
  static tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {
    final local = tz.local;
    return tz.TZDateTime(
      local,
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
      dateTime.second,
    );
  }

  /// Anlık bildirim göster (Mesajlar vb. için)
  static Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) return;

    const androidDetails = AndroidNotificationDetails(
      'instant_messages',
      'Anlık Mesajlar',
      channelDescription: 'Gelen mesaj ve uyarılar',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifications.show(id, title, body, details, payload: payload);
  }

  /// Hasat hatırlatıcısı zamanla (1 hafta kala)
  static Future<void> scheduleHarvestReminder({
    required String cropId,
    required String cropName,
    required DateTime harvestDate,
  }) async {
    try {
      if (!_initialized) {
        print('Bildirim servisi başlatılmamış!');
        return;
      }

      final oneWeekBefore = harvestDate.subtract(const Duration(days: 7));
      final now = tz.TZDateTime.now(tz.local);
      final oneWeekBeforeTZ = _convertToTZDateTime(oneWeekBefore);
      final harvestDateTZ = _convertToTZDateTime(harvestDate);

      // 1 hafta kala bildirimi
      if (oneWeekBeforeTZ.isAfter(now)) {
        await _notifications.zonedSchedule(
          _getNotificationId('harvest_week_$cropId'),
          'Hasat Yaklaşıyor! 🌾',
          '$cropName mahsulünün hasat tarihine 1 hafta kaldı!',
          oneWeekBeforeTZ,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'crop_reminders',
              'Mahsul Hatırlatıcıları',
              channelDescription: 'Mahsul hasat ve bakım hatırlatıcıları',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
              enableVibration: true,
              playSound: true,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'crop_$cropId',
        );
        print('1 hafta kala bildirimi zamanlandı: $cropName - $oneWeekBeforeTZ');
      } else {
        print('1 hafta kala tarihi geçmiş, bildirim zamanlanmadı: $cropName');
      }

      // Hasat günü bildirimi
      if (harvestDateTZ.isAfter(now)) {
        await _notifications.zonedSchedule(
          _getNotificationId('harvest_day_$cropId'),
          'Hasat Günü! 🎉',
          '$cropName mahsulünün hasat günü bugün!',
          harvestDateTZ,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'crop_reminders',
              'Mahsul Hatırlatıcıları',
              channelDescription: 'Mahsul hasat ve bakım hatırlatıcıları',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
              enableVibration: true,
              playSound: true,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'crop_$cropId',
        );
        print('Hasat günü bildirimi zamanlandı: $cropName - $harvestDateTZ');
      } else {
        print('Hasat tarihi geçmiş, bildirim zamanlanmadı: $cropName');
      }
    } catch (e) {
      print('Hasat hatırlatıcısı zamanlanamadı: $e');
      if (kDebugMode) {
        print('Stack trace: ${StackTrace.current}');
      }
    }
  }

  /// Özel hatırlatıcı zamanla (ilaçlama, sulama vb.)
  static Future<void> scheduleCustomReminder({
    required String reminderId,
    required String cropName,
    required String title,
    required String description,
    required DateTime reminderDate,
  }) async {
    try {
      if (!_initialized) await initialize();

      // Android 12+ için Exact Alarm izni kontrolü
      if (Platform.isAndroid) {
        final androidImplementation = _notifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidImplementation != null) {
           // İzin yoksa iste, ama kullanıcıyı çok darlamadan
           // (Genelde initialize'da isteriz ama garanti olsun)
          await androidImplementation.requestExactAlarmsPermission();
        }
      }

      final now = tz.TZDateTime.now(tz.local);
      final reminderDateTZ = _convertToTZDateTime(reminderDate);
      
      // Çok geçmiş tarihse iptal et (15 dk tolerans)
      if (reminderDateTZ.isBefore(now.subtract(const Duration(minutes: 15)))) {
        print('Hatırlatıcı tarihi çok eski, zamanlanmadı: $title ($reminderDateTZ)');
        return;
      }
      
      // Eğer tarih geçmişte ama yakınsa (0-15dk), 5 saniye sonraya kur
      tz.TZDateTime scheduledDate = reminderDateTZ;
      if (reminderDateTZ.isBefore(now)) {
        scheduledDate = now.add(const Duration(seconds: 5));
        print('Geçmiş tarihli hatırlatıcı revize edildi: $title -> $scheduledDate');
      }

      await _notifications.zonedSchedule(
        _getNotificationId('reminder_$reminderId'),
        title,
        '$cropName: $description',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'reminders_v3', // Yeni kanal ID
            'Mahsul Hatırlatıcıları',
            channelDescription: 'Zamanlanmış mahsul ve hasat bildirimleri',
            importance: Importance.max,
            priority: Priority.max,
            icon: '@mipmap/ic_launcher',
            enableVibration: true,
            playSound: true,
            fullScreenIntent: true, // Ekran kapalıyken uyandırabilir
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'reminder_$reminderId',
      );
      print('Özel hatırlatıcı zamanlandı: $title - $scheduledDate');
    } catch (e) {
      print('Hatırlatıcı zamanlanamadı: $e');
      if (kDebugMode) {
        print('Stack trace: ${StackTrace.current}');
      }
    }
  }

  /// Bildirimi iptal et
  static Future<void> cancelNotification(String notificationId) async {
    await _notifications.cancel(_getNotificationId(notificationId));
  }

  /// Mahsul ile ilgili tüm bildirimleri iptal et
  static Future<void> cancelCropNotifications(String cropId) async {
    await _notifications.cancel(_getNotificationId('harvest_week_$cropId'));
    await _notifications.cancel(_getNotificationId('harvest_day_$cropId'));
  }

  /// Bildirim ID'si oluştur (string'den int'e)
  static int _getNotificationId(String id) {
    return id.hashCode.abs() % 2147483647; // Max int değeri
  }

  /// Tüm mahsuller için hasat hatırlatıcılarını zamanla
  static Future<void> scheduleAllHarvestReminders() async {
    try {
      if (!_initialized) {
        print('Bildirim servisi başlatılmamış, hatırlatıcılar zamanlanamadı!');
        return;
      }

      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('Kullanıcı giriş yapmamış, hatırlatıcılar zamanlanamadı!');
        return;
      }

      print('Tüm hasat hatırlatıcıları zamanlanıyor...');
      final crops = await _supabase
          .from('crops')
          .select('id, name, expected_harvest_date')
          .eq('user_id', user.id)
          .not('expected_harvest_date', 'is', null);

      print('${crops.length} mahsul bulundu');
      int scheduledCount = 0;

      for (final crop in crops) {
        final harvestDateStr = crop['expected_harvest_date']?.toString();
        if (harvestDateStr == null || harvestDateStr.isEmpty) continue;

        final harvestDate = DateTime.tryParse(harvestDateStr);
        if (harvestDate != null) {
          await scheduleHarvestReminder(
            cropId: crop['id'].toString(),
            cropName: crop['name']?.toString() ?? 'Mahsul',
            harvestDate: harvestDate,
          );
          scheduledCount++;
        } else {
          print('Geçersiz hasat tarihi: ${crop['name']} - $harvestDateStr');
        }
      }

      print('$scheduledCount mahsul için hatırlatıcı zamanlandı');
    } catch (e) {
      print('Hasat hatırlatıcıları zamanlanamadı: $e');
      if (kDebugMode) {
        print('Stack trace: ${StackTrace.current}');
      }
    }
  }

  /// Tüm özel hatırlatıcıları (crop_reminders) tekrar zamanla
  static Future<void> scheduleAllCustomReminders() async {
    try {
      if (!_initialized) {
        print('Bildirim servisi başlatılmamış, özel hatırlatıcılar zamanlanamadı!');
        return;
      }

      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('Kullanıcı giriş yapmamış, özel hatırlatıcılar zamanlanamadı!');
        return;
      }

      print('Tüm özel hatırlatıcılar zamanlanıyor...');
      final now = DateTime.now();

      final reminders = await _supabase
          .from('crop_reminders')
          .select('*, crops(name)')
          .eq('user_id', user.id)
          .eq('is_completed', false)
          .gt('reminder_date', now.toIso8601String()); // Sadece gelecekteki hatırlatıcılar

      print('${reminders.length} aktif özel hatırlatıcı bulundu');
      int scheduledCount = 0;

      for (final reminder in reminders) {
        final reminderDateStr = reminder['reminder_date']?.toString();
        if (reminderDateStr == null) continue;

        final reminderDate = DateTime.tryParse(reminderDateStr);
        if (reminderDate != null) {
          final cropName = reminder['crops']?['name'] ?? 'Mahsul';
          
          await scheduleCustomReminder(
            reminderId: reminder['id'].toString(),
            cropName: cropName,
            title: reminder['title'] ?? 'Hatırlatıcı',
            description: reminder['description'] ?? '',
            reminderDate: reminderDate,
          );
          scheduledCount++;
        }
      }

      print('$scheduledCount özel hatırlatıcı zamanlandı');
    } catch (e) {
      print('Özel hatırlatıcılar zamanlanamadı: $e');
      if (kDebugMode) {
        print('Stack trace: ${StackTrace.current}');
      }
    }
  }
}


