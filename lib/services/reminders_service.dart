import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';

class RemindersService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Mahsul için hatırlatıcı ekle
  static Future<String> addReminder({
    required String cropId,
    required String title,
    String? description,
    required DateTime reminderDate,
    required String reminderType,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      final response = await _supabase.from('crop_reminders').insert({
        'user_id': user.id,
        'crop_id': cropId,
        'title': title,
        'description': description,
        'reminder_date': reminderDate.toIso8601String(),
        'reminder_type': reminderType,
      }).select('id').single();

      final reminderId = response['id'] as String;

      // Bildirimi zamanla
      final crop = await _supabase
          .from('crops')
          .select('name')
          .eq('id', cropId)
          .single();

      await NotificationService.scheduleCustomReminder(
        reminderId: reminderId,
        cropName: crop['name'] ?? 'Mahsul',
        title: title,
        description: description ?? '',
        reminderDate: reminderDate,
      );

      return reminderId;
    } catch (e) {
      throw Exception('Hatırlatıcı eklenemedi: $e');
    }
  }

  /// Mahsul için hatırlatıcıları getir
  static Future<List<Map<String, dynamic>>> getCropReminders(String cropId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      final response = await _supabase
          .from('crop_reminders')
          .select('*')
          .eq('crop_id', cropId)
          .eq('user_id', user.id)
          .order('reminder_date', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Hatırlatıcılar getirilemedi: $e');
    }
  }

  /// Tüm aktif hatırlatıcıları getir
  static Future<List<Map<String, dynamic>>> getAllReminders({bool includeCompleted = false}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      var query = _supabase
          .from('crop_reminders')
          .select('*, crops(name)')
          .eq('user_id', user.id);

      if (!includeCompleted) {
        query = query.eq('is_completed', false);
      }

      final response = await query.order('reminder_date', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Hatırlatıcılar getirilemedi: $e');
    }
  }

  /// Hatırlatıcıyı tamamla
  static Future<void> completeReminder(String reminderId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      await _supabase
          .from('crop_reminders')
          .update({
            'is_completed': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', reminderId)
          .eq('user_id', user.id);

      // Bildirimi iptal et
      await NotificationService.cancelNotification('reminder_$reminderId');
    } catch (e) {
      throw Exception('Hatırlatıcı tamamlanamadı: $e');
    }
  }

  /// Hatırlatıcıyı sil
  static Future<void> deleteReminder(String reminderId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      await _supabase
          .from('crop_reminders')
          .delete()
          .eq('id', reminderId)
          .eq('user_id', user.id);

      // Bildirimi iptal et
      await NotificationService.cancelNotification('reminder_$reminderId');
    } catch (e) {
      throw Exception('Hatırlatıcı silinemedi: $e');
    }
  }

  /// Hatırlatıcıyı güncelle
  static Future<void> updateReminder({
    required String reminderId,
    String? title,
    String? description,
    DateTime? reminderDate,
    String? reminderType,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (reminderDate != null) updateData['reminder_date'] = reminderDate.toIso8601String();
      if (reminderType != null) updateData['reminder_type'] = reminderType;

      await _supabase
          .from('crop_reminders')
          .update(updateData)
          .eq('id', reminderId)
          .eq('user_id', user.id);

      // Eğer tarih değiştiyse bildirimi yeniden zamanla
      if (reminderDate != null) {
        final reminder = await _supabase
            .from('crop_reminders')
            .select('*, crops(name)')
            .eq('id', reminderId)
            .single();

        final cropName = reminder['crops']?['name'] ?? 'Mahsul';
        await NotificationService.cancelNotification('reminder_$reminderId');
        await NotificationService.scheduleCustomReminder(
          reminderId: reminderId,
          cropName: cropName,
          title: reminder['title'] ?? 'Hatırlatıcı',
          description: reminder['description'] ?? '',
          reminderDate: reminderDate,
        );
      }
    } catch (e) {
      throw Exception('Hatırlatıcı güncellenemedi: $e');
    }
  }
}

