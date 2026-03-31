import 'package:supabase_flutter/supabase_flutter.dart';

class CropsService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  
  // Cache için static değişkenler
  static List<Map<String, dynamic>>? _cachedCrops;
  static DateTime? _lastCacheUpdate;
  static String? _cachedUserId;
  static const Duration _cacheDuration = Duration(seconds: 30); // 30 saniye cache

  /// Kullanıcının mahsullerini getir (Cache ile)
  static Future<List<Map<String, dynamic>>> getUserCrops({bool forceRefresh = false}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      // Cache kontrolü
      if (!forceRefresh && 
          _cachedCrops != null && 
          _lastCacheUpdate != null && 
          _cachedUserId == user.id &&
          DateTime.now().difference(_lastCacheUpdate!) < _cacheDuration) {
        return _cachedCrops!;
      }

      // Sadece gerekli alanları seç (performans için)
      final response = await _supabase
          .from('crops')
          .select('id, name, variety, planting_date, expected_harvest_date, city, notes, area_sqm, created_at, updated_at')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(100); // Maksimum 100 kayıt (performans için)

      final crops = List<Map<String, dynamic>>.from(response);
      
      // Cache'e kaydet
      _cachedCrops = crops;
      _lastCacheUpdate = DateTime.now();
      _cachedUserId = user.id;

      return crops;
    } catch (e) {
      // Daha açıklayıcı hata mesajı
      final errorMessage = e.toString().toLowerCase();
      
      // Network/DNS hataları
      if (errorMessage.contains('socketexception') || 
          errorMessage.contains('failed host lookup') ||
          errorMessage.contains('no address associated') ||
          errorMessage.contains('network') || 
          errorMessage.contains('connection') || 
          errorMessage.contains('timeout') ||
          errorMessage.contains('errno = 7')) {
        throw Exception('İnternet bağlantısı hatası. Lütfen internet bağlantınızı kontrol edin ve tekrar deneyin.');
      } 
      // Giriş yapılmamış
      else if (errorMessage.contains('kullanıcı giriş yapmamış') || errorMessage.contains('not authenticated')) {
        throw Exception('Lütfen giriş yapın');
      } 
      // Diğer hatalar
      else {
        throw Exception('Mahsuller getirilemedi. Lütfen tekrar deneyin.');
      }
    }
  }
  
  /// Cache'i temizle
  static void clearCache() {
    _cachedCrops = null;
    _lastCacheUpdate = null;
    _cachedUserId = null;
  }

  /// Yeni mahsul ekle
  static Future<void> addCrop({
    required String name,
    String? variety,
    required DateTime plantingDate,
    DateTime? expectedHarvestDate,
    required String city,
    String? notes,
    double? areaSqm,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      await _supabase.from('crops').insert({
        'user_id': user.id,
        'name': name,
        'variety': variety,
        'planting_date': plantingDate.toIso8601String().split('T')[0], // YYYY-MM-DD formatı
        'expected_harvest_date': expectedHarvestDate?.toIso8601String().split('T')[0],
        'city': city,
        'notes': notes,
        if (areaSqm != null) 'area_sqm': areaSqm,
      });
      
      // Cache'i temizle (yeni ekleme sonrası)
      clearCache();
    } catch (e) {
      throw Exception('Mahsul eklenemedi: $e');
    }
  }

  /// Mahsul sil
  static Future<void> deleteCrop(String cropId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      await _supabase
          .from('crops')
          .delete()
          .eq('id', cropId)
          .eq('user_id', user.id); // Güvenlik için user_id kontrolü
      
      // Cache'i temizle (silme sonrası)
      clearCache();
    } catch (e) {
      throw Exception('Mahsul silinemedi: $e');
    }
  }

  /// Mahsulü favorilere ekle
  static Future<void> addCropToFavorites(String cropId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Kullanıcı giriş yapmamış');

      // Önce mahsul bilgilerini al
      final cropResponse = await _supabase
          .from('crops')
          .select('name, city, notes')
          .eq('id', cropId)
          .eq('user_id', user.id)
          .single();

      // Favorilere ekle
      await _supabase.from('user_favorites').insert({
        'user_id': user.id,
        'item_type': 'crop',
        'item_id': cropId,
        'item_name': cropResponse['name'] ?? 'Mahsul',
        'item_description': cropResponse['notes'],
      });
    } catch (e) {
      // Eğer zaten favorilerde varsa hata verme (duplicate key hatası)
      if (e.toString().contains('duplicate') || e.toString().contains('unique')) {
        throw Exception('Bu mahsul zaten favorilerinizde');
      }
      // Eğer mahsul bulunamadıysa
      if (e.toString().contains('PGRST116') || e.toString().contains('not found')) {
        throw Exception('Mahsul bulunamadı');
      }
      throw Exception('Mahsul favorilere eklenemedi: $e');
    }
  }
}

