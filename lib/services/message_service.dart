import 'package:supabase_flutter/supabase_flutter.dart';

class MessageService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  
  // O an açık olan sohbeti takip etmek için (bildirim göstermemek için)
  static String? currentChatListingId;

  /// İlan için mesaj gönder
  static Future<String> sendMessage({
    required String listingId,
    required String receiverId,
    required String message,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      // Kendine mesaj gönderemez
      if (user.id == receiverId) {
        throw Exception('Kendinize mesaj gönderemezsiniz');
      }

      // İlanın var olduğunu ve aktif olduğunu kontrol et
      final listing = await _supabase
          .from('marketplace_items')
          .select('id, user_id, is_available')
          .eq('id', listingId)
          .single();

      if (listing['is_available'] != true) {
        throw Exception('Bu ilan artık aktif değil');
      }

      // GÜVENLİ YÖNTEM: RPC (Stored Procedure) kullanımı
      // Bu yöntem RLS hatalarını bypass eder çünkü fonksiyon "Security Definer" olarak çalışır.
      await _supabase.rpc('send_marketplace_message', params: {
        'p_listing_id': listingId,
        'p_receiver_id': receiverId,
        'p_message': message,
      });
      return 'sent';

    } catch (e) {
      print('Mesaj gönderilemedi: $e');
      rethrow;
    }
  }

  /// Belirli bir kişiyle olan sohbet geçmişini getir
  static Future<List<Map<String, dynamic>>> getMessagesForConversation(
    String listingId,
    String otherUserId,
  ) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      final response = await _supabase
          .from('marketplace_messages')
          .select('*')
          .eq('listing_id', listingId)
          .or('and(sender_id.eq.${user.id},receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.${user.id})')
          .order('created_at', ascending: true);

      final messages = List<Map<String, dynamic>>.from(response);
      return messages;
    } catch (e) {
      print('Sohbet geçmişi getirilemedi: $e');
      return [];
    }
  }

  /// İlan için tüm mesajları getir (konuşma geçmişi)
  static Future<List<Map<String, dynamic>>> getMessagesForListing(
    String listingId,
  ) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      // 1. Mesajları getir
      final response = await _supabase
          .from('marketplace_messages')
          .select('*')
          .eq('listing_id', listingId)
          .or('sender_id.eq.${user.id},receiver_id.eq.${user.id}')
          .order('created_at', ascending: true);

      final messages = List<Map<String, dynamic>>.from(response);
      if (messages.isEmpty) return [];

      // 2. Kullanıcı ID'lerini topla
      final userIds = <String>{};
      for (var msg in messages) {
        if (msg['sender_id'] != null) userIds.add(msg['sender_id']);
        if (msg['receiver_id'] != null) userIds.add(msg['receiver_id']);
      }

      // 3. Profilleri getir
      final profilesResponse = await _supabase
          .from('profiles')
          .select('id, name, email')
          .filter('id', 'in', userIds.toList());
      
      final profiles = {for (var p in profilesResponse) p['id']: p};

      // 4. Verileri birleştir
      return messages.map((msg) {
        final sender = profiles[msg['sender_id']];
        final receiver = profiles[msg['receiver_id']];
        
        return {
          ...msg,
          'sender': sender,
          'receiver': receiver,
        };
      }).toList();
    } catch (e) {
      print('Mesajlar getirilemedi: $e');
      rethrow;
    }
  }

  /// Kullanıcının tüm mesajlarını getir (inbox)
  static Future<List<Map<String, dynamic>>> getMyMessages() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      // 1. Mesajları getir
      final response = await _supabase
          .from('marketplace_messages')
          .select('*')
          .or('sender_id.eq.${user.id},receiver_id.eq.${user.id}')
          .order('created_at', ascending: false);

      final messages = List<Map<String, dynamic>>.from(response);
      if (messages.isEmpty) return [];

      // 2. ID'leri topla
      final userIds = <String>{};
      final listingIds = <String>{};

      for (var msg in messages) {
        if (msg['sender_id'] != null) userIds.add(msg['sender_id']);
        if (msg['receiver_id'] != null) userIds.add(msg['receiver_id']);
        if (msg['listing_id'] != null) listingIds.add(msg['listing_id']);
      }

      // 3. Profilleri ve İlanları getir
      final profilesResponse = await _supabase
          .from('profiles')
          .select('id, name, email')
          .filter('id', 'in', userIds.toList());
      
      final listingsResponse = await _supabase
          .from('marketplace_items')
          .select('id, title, image_url, is_available')
          .filter('id', 'in', listingIds.toList());

      final profiles = {for (var p in profilesResponse) p['id']: p};
      final listings = {for (var l in listingsResponse) l['id']: l};

      // 4. Verileri birleştir
      return messages.map((msg) {
        final sender = profiles[msg['sender_id']];
        final receiver = profiles[msg['receiver_id']];
        final listing = listings[msg['listing_id']];
        
        return {
          ...msg,
          'sender': sender,
          'receiver': receiver,
          'listing': listing,
        };
      }).toList();
    } catch (e) {
      print('Mesajlarım getirilemedi: $e');
      rethrow;
    }
  }

  /// Okunmamış mesaj sayısını getir
  static Future<int> getUnreadMessageCount() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return 0;

      final response = await _supabase
          .from('marketplace_messages')
          .select('id')
          .eq('receiver_id', user.id)
          .eq('is_read', false);

      return response.length;
    } catch (e) {
      print('Okunmamış mesaj sayısı getirilemedi: $e');
      return 0;
    }
  }

  /// Konuşmadaki tüm okunmamış mesajları okundu işaretle
  static Future<void> markMessagesAsRead(String listingId, String senderId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      await _supabase
          .from('marketplace_messages')
          .update({'is_read': true})
          .eq('listing_id', listingId)
          .eq('sender_id', senderId)
          .eq('receiver_id', user.id)
          .eq('is_read', false);
    } catch (e) {
      print('Mesajlar okundu işaretlenemedi: $e');
      // Kritik hata değil, sessizce geçilebilir
    }
  }

  /// Mesajı okundu olarak işaretle
  static Future<void> markAsRead(String messageId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      await _supabase
          .from('marketplace_messages')
          .update({'is_read': true})
          .eq('id', messageId)
          .eq('receiver_id', user.id); // Sadece alıcı işaretleyebilir
    } catch (e) {
      print('Mesaj okundu işaretlenemedi: $e');
      rethrow;
    }
  }

  /// Mesajı sil
  static Future<void> deleteMessage(String messageId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      await _supabase
          .from('marketplace_messages')
          .delete()
          .eq('id', messageId)
          .or('sender_id.eq.${user.id},receiver_id.eq.${user.id}'); // Gönderen veya alan silebilir
    } catch (e) {
      print('Mesaj silinemedi: $e');
      rethrow;
    }
  }
}
