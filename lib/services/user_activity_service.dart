import 'package:supabase_flutter/supabase_flutter.dart';

class UserActivityService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // ========== FAVORİLER ==========
  
  /// Kullanıcının favorilerini getir
  static Future<List<Map<String, dynamic>>> getUserFavorites() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      final response = await _supabase
          .from('user_favorites')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Favoriler getirilemedi: $e');
    }
  }

  /// Favori ekle
  static Future<void> addToFavorites({
    required String itemType,
    required String itemId,
    required String itemName,
    String? itemDescription,
    String? itemImageUrl,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      await _supabase.from('user_favorites').insert({
        'user_id': user.id,
        'item_type': itemType,
        'item_id': itemId,
        'item_name': itemName,
        'item_description': itemDescription,
        'item_image_url': itemImageUrl,
      });

      // Aktivite loguna ekle
      await _logActivity(
        activityType: 'favorite_added',
        activityDescription: '$itemName favorilere eklendi',
        relatedItemId: itemId,
        relatedItemType: itemType,
      );
    } catch (e) {
      throw Exception('Favori eklenemedi: $e');
    }
  }

  /// Favoriden çıkar
  static Future<void> removeFromFavorites({
    required String itemType,
    required String itemId,
    required String itemName,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      await _supabase
          .from('user_favorites')
          .delete()
          .eq('user_id', user.id)
          .eq('item_type', itemType)
          .eq('item_id', itemId);

      // Aktivite loguna ekle
      await _logActivity(
        activityType: 'favorite_removed',
        activityDescription: '$itemName favorilerden çıkarıldı',
        relatedItemId: itemId,
        relatedItemType: itemType,
      );
    } catch (e) {
      throw Exception('Favori çıkarılamadı: $e');
    }
  }

  /// Favori olup olmadığını kontrol et
  static Future<bool> isFavorite({
    required String itemType,
    required String itemId,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response = await _supabase
          .from('user_favorites')
          .select('id')
          .eq('user_id', user.id)
          .eq('item_type', itemType)
          .eq('item_id', itemId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  // ========== KULLANICI TERCIHLERI ==========

  /// Kullanıcı tercihlerini getir
  static Future<Map<String, String>> getUserPreferences() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      final response = await _supabase
          .from('user_preferences')
          .select('preference_key, preference_value')
          .eq('user_id', user.id);

      final Map<String, String> preferences = {};
      for (final item in response) {
        preferences[item['preference_key']] = item['preference_value'];
      }

      return preferences;
    } catch (e) {
      throw Exception('Tercihler getirilemedi: $e');
    }
  }

  /// Tercih güncelle
  static Future<void> updatePreference({
    required String key,
    required String value,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      // Önce mevcut tercihi kontrol et
      final existing = await _supabase
          .from('user_preferences')
          .select('id')
          .eq('user_id', user.id)
          .eq('preference_key', key)
          .maybeSingle();

      if (existing != null) {
        // Güncelle
        await _supabase
            .from('user_preferences')
            .update({
              'preference_value': value,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', user.id)
            .eq('preference_key', key);
      } else {
        // Yeni ekle
        await _supabase.from('user_preferences').insert({
          'user_id': user.id,
          'preference_key': key,
          'preference_value': value,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      throw Exception('Tercih güncellenemedi: $e');
    }
  }

  /// Belirli bir tercihi getir
  static Future<String?> getPreference(String key) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('user_preferences')
          .select('preference_value')
          .eq('user_id', user.id)
          .eq('preference_key', key)
          .maybeSingle();

      return response?['preference_value'];
    } catch (e) {
      return null;
    }
  }

  // ========== BILDIRIM TERCIHLERI ==========

  /// Bildirim tercihlerini getir
  static Future<Map<String, bool>> getNotificationPreferences() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      final response = await _supabase
          .from('user_notification_preferences')
          .select('notification_type, is_enabled')
          .eq('user_id', user.id);

      final Map<String, bool> preferences = {};
      for (final item in response) {
        preferences[item['notification_type']] = item['is_enabled'];
      }

      return preferences;
    } catch (e) {
      throw Exception('Bildirim tercihleri getirilemedi: $e');
    }
  }

  /// Bildirim tercihini güncelle
  static Future<void> updateNotificationPreference({
    required String notificationType,
    required bool isEnabled,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      await _supabase.from('user_notification_preferences').upsert({
        'user_id': user.id,
        'notification_type': notificationType,
        'is_enabled': isEnabled,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Bildirim tercihi güncellenemedi: $e');
    }
  }

  // ========== AKTIVITE GEÇMIŞI ==========

  /// Kullanıcının aktivite geçmişini getir
  static Future<List<Map<String, dynamic>>> getActivityLog({
    int limit = 50,
    String? activityType,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      var query = _supabase
          .from('user_activity_log')
          .select()
          .eq('user_id', user.id);

      if (activityType != null) {
        query = query.eq('activity_type', activityType);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Aktivite geçmişi getirilemedi: $e');
    }
  }

  /// Aktivite loguna kaydet (private method)
  static Future<void> _logActivity({
    required String activityType,
    required String activityDescription,
    String? relatedItemId,
    String? relatedItemType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return; // Sessizce çık, hata verme

      await _supabase.from('user_activity_log').insert({
        'user_id': user.id,
        'activity_type': activityType,
        'activity_description': activityDescription,
        'related_item_id': relatedItemId,
        'related_item_type': relatedItemType,
        'metadata': metadata,
      });
    } catch (e) {
      // Aktivite logu hatası kritik değil, sessizce geç
      print('Aktivite logu hatası: $e');
    }
  }

  // ========== GENEL AKTIVITE LOGLARI ==========

  /// Mahsul ekleme aktivitesi
  static Future<void> logCropAdded({
    required String cropId,
    required String cropName,
    required String city,
  }) async {
    await _logActivity(
      activityType: 'crop_added',
      activityDescription: '$cropName mahsulü $city şehrinde eklendi',
      relatedItemId: cropId,
      relatedItemType: 'crop',
      metadata: {'city': city},
    );
  }

  /// Mahsul güncelleme aktivitesi
  static Future<void> logCropUpdated({
    required String cropId,
    required String cropName,
  }) async {
    await _logActivity(
      activityType: 'crop_updated',
      activityDescription: '$cropName mahsulü güncellendi',
      relatedItemId: cropId,
      relatedItemType: 'crop',
    );
  }

  /// Mahsul silme aktivitesi
  static Future<void> logCropDeleted({
    required String cropId,
    required String cropName,
  }) async {
    await _logActivity(
      activityType: 'crop_deleted',
      activityDescription: '$cropName mahsulü silindi',
      relatedItemId: cropId,
      relatedItemType: 'crop',
    );
  }

  /// Pazar yeri ürün ekleme aktivitesi
  static Future<void> logMarketplaceItemAdded({
    required String itemId,
    required String itemTitle,
    required String category,
  }) async {
    await _logActivity(
      activityType: 'marketplace_item_added',
      activityDescription: '$itemTitle ürünü pazar yerine eklendi',
      relatedItemId: itemId,
      relatedItemType: 'marketplace_item',
      metadata: {'category': category},
    );
  }

  /// AI konuşma başlatma aktivitesi
  static Future<void> logAIConversationStarted({
    required String sessionId,
    required String messageType,
  }) async {
    await _logActivity(
      activityType: 'ai_conversation_started',
      activityDescription: 'AI asistanı ile konuşma başlatıldı',
      relatedItemId: sessionId,
      relatedItemType: 'ai_conversation',
      metadata: {'message_type': messageType},
    );
  }

  /// Profil güncelleme aktivitesi
  static Future<void> logProfileUpdated({
    required Map<String, dynamic> updatedFields,
  }) async {
    await _logActivity(
      activityType: 'profile_updated',
      activityDescription: 'Profil bilgileri güncellendi',
      metadata: {'updated_fields': updatedFields.keys.toList()},
    );
  }

  // ========== KULLANICI VERİLERİNİ YÜKLEME ==========

  /// Kullanıcının tüm kişisel verilerini yükle
  static Future<Map<String, dynamic>> loadUserData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      // Paralel olarak tüm verileri yükle
      final futures = await Future.wait([
        getUserFavorites(),
        getUserPreferences(),
        getNotificationPreferences(),
        getActivityLog(limit: 20),
      ]);

      return {
        'favorites': futures[0],
        'preferences': futures[1],
        'notificationPreferences': futures[2],
        'recentActivity': futures[3],
      };
    } catch (e) {
      throw Exception('Kullanıcı verileri yüklenemedi: $e');
    }
  }

  // ========== VERİ TEMİZLEME ==========

  /// Kullanıcının tüm aktivite verilerini temizle
  static Future<void> clearUserData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      await Future.wait([
        _supabase.from('user_favorites').delete().eq('user_id', user.id),
        _supabase.from('user_preferences').delete().eq('user_id', user.id),
        _supabase.from('user_notification_preferences').delete().eq('user_id', user.id),
        _supabase.from('user_activity_log').delete().eq('user_id', user.id),
      ]);
    } catch (e) {
      throw Exception('Kullanıcı verileri temizlenemedi: $e');
    }
  }
}
