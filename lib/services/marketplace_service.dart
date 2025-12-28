import 'package:supabase_flutter/supabase_flutter.dart';

class MarketplaceService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Tüm aktif ilanları getir (performans için pagination)
  static Future<List<Map<String, dynamic>>> getAllListings({
    String? category,
    String? city,
    String? searchQuery,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      // Base query - profiles join'i kaldırıldı (foreign key sorunu nedeniyle)
      var query = _supabase
          .from('marketplace_items')
          .select('*')
          .eq('is_available', true);

      // Filtreleme
      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }

      if (city != null && city.isNotEmpty) {
        query = query.eq('city', city);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('title.ilike.%$searchQuery%,description.ilike.%$searchQuery%');
      }

      // Sıralama ve limit
      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('İlanlar getirilemedi: $e');
      rethrow;
    }
  }

  /// Kullanıcının kendi ilanlarını getir
  static Future<List<Map<String, dynamic>>> getMyListings() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      final response = await _supabase
          .from('marketplace_items')
          .select('*')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Kendi ilanlarım getirilemedi: $e');
      rethrow;
    }
  }

  /// Tek bir ilanı getir
  static Future<Map<String, dynamic>> getListingById(String listingId) async {
    try {
      final response = await _supabase
          .from('marketplace_items')
          .select('*')
          .eq('id', listingId)
          .single();

      return response;
    } catch (e) {
      print('İlan getirilemedi: $e');
      rethrow;
    }
  }

  /// Yeni ilan oluştur
  static Future<String> createListing({
    required String title,
    required String description,
    required double price,
    required String category,
    String? city,
    String? quantity,
    String? unit,
    String? contactPhone,
    String? imageUrl,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      final response = await _supabase
          .from('marketplace_items')
          .insert({
            'user_id': user.id,
            'title': title,
            'description': description,
            'price': price,
            'category': category,
            'city': city,
            'quantity': quantity,
            'unit': unit ?? 'adet',
            'contact_phone': contactPhone,
            'image_url': imageUrl,
            'is_available': true,
          })
          .select('id')
          .single();

      final listingId = response['id'] as String;

      // Activity log'a ekle
      try {
        await _supabase.from('user_activity_log').insert({
          'user_id': user.id,
          'activity_type': 'marketplace_item_added',
          'activity_description': 'Yeni ilan oluşturuldu: $title',
          'related_item_id': listingId,
          'related_item_type': 'marketplace_item',
        });
      } catch (e) {
        print('Activity log eklenemedi: $e');
      }

      return listingId;
    } catch (e) {
      print('İlan oluşturulamadı: $e');
      rethrow;
    }
  }

  /// İlanı güncelle (sadece ilan sahibi)
  static Future<void> updateListing({
    required String listingId,
    String? title,
    String? description,
    double? price,
    String? category,
    String? city,
    String? quantity,
    String? unit,
    String? contactPhone,
    String? imageUrl,
    bool? isAvailable,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      // Önce ilanın sahibi olduğunu kontrol et
      final listing = await getListingById(listingId);
      if (listing['user_id'] != user.id) {
        throw Exception('Bu ilanı düzenleme yetkiniz yok');
      }

      final updateData = <String, dynamic>{};
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (price != null) updateData['price'] = price;
      if (category != null) updateData['category'] = category;
      if (city != null) updateData['city'] = city;
      if (quantity != null) updateData['quantity'] = quantity;
      if (unit != null) updateData['unit'] = unit;
      if (contactPhone != null) updateData['contact_phone'] = contactPhone;
      if (imageUrl != null) updateData['image_url'] = imageUrl;
      if (isAvailable != null) updateData['is_available'] = isAvailable;

      await _supabase
          .from('marketplace_items')
          .update(updateData)
          .eq('id', listingId)
          .eq('user_id', user.id); // Güvenlik için tekrar kontrol
    } catch (e) {
      print('İlan güncellenemedi: $e');
      rethrow;
    }
  }

  /// İlanı sil (sadece ilan sahibi veya admin)
  static Future<void> deleteListing(String listingId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      final isAdmin = user.email == 'orbay1907@gmail.com';

      // Admin değilse sahiplik kontrolü yap
      if (!isAdmin) {
        final listing = await getListingById(listingId);
        if (listing['user_id'] != user.id) {
          throw Exception('Bu ilanı silme yetkiniz yok');
        }
      }

      var query = _supabase.from('marketplace_items').delete().eq('id', listingId);

      // Admin değilse sadece kendi ilanını silebilir
      if (!isAdmin) {
        query = query.eq('user_id', user.id);
      }

      await query;
    } catch (e) {
      print('İlan silinemedi: $e');
      rethrow;
    }
  }

  /// Kategorileri getir
  static List<String> getCategories() {
    return [
      'Gübre',
      'Tarım İlacı',
      'Hasat Ürünü',
      'Tohum',
      'Ekipman',
      'Diğer',
    ];
  }

  /// Birimleri getir
  static List<String> getUnits() {
    return [
      'adet',
      'kg',
      'ton',
      'litre',
      'm²',
      'dönüm',
    ];
  }
}

