import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SecureApiService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Groq API anahtarını sunucudan al
  static Future<String> getGroqApiKey() async {
    try {
      // Supabase Edge Function'dan API anahtarını al
      final response = await _supabase.functions.invoke(
        'get-api-key',
        body: {
          'service': 'groq',
        },
      );

      if (response.data != null && response.data['apiKey'] != null) {
        return response.data['apiKey'];
      } else {
        throw Exception('API anahtarı alınamadı');
      }
    } catch (e) {
      // Fallback olarak environment'tan al (development için)
      final fallbackKey = SupabaseConfig.groqApiKey;
      if (fallbackKey.isNotEmpty) {
        return fallbackKey;
      }
      throw Exception('API anahtarı alınamadı: $e');
    }
  }

  // Güvenli API çağrısı yap
  static Future<Map<String, dynamic>> makeSecureApiCall({
    required String endpoint,
    required Map<String, dynamic> data,
    String? apiKey,
  }) async {
    try {
      // API anahtarı verilmemişse sunucudan al (Groq için)
      final key = apiKey ?? await getGroqApiKey();

      // Supabase Edge Function üzerinden API çağrısı yap
      final response = await _supabase.functions.invoke(
        'secure-api-call',
        body: {
          'endpoint': endpoint,
          'data': data,
          'apiKey': key,
        },
      );

      if (response.data != null) {
        return response.data;
      } else {
        throw Exception('API çağrısı başarısız');
      }
    } catch (e) {
      throw Exception('Güvenli API çağrısı hatası: $e');
    }
  }

  // Kullanıcıya özel API anahtarı kaydet (opsiyonel)
  static Future<void> saveUserApiKey({
    required String userId,
    required String service,
    required String apiKey,
  }) async {
    try {
      await _supabase.from('user_api_keys').insert({
        'user_id': userId,
        'service': service,
        'encrypted_key': apiKey, // Bu alan şifrelenmiş olmalı
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('API anahtarı kaydedilemedi: $e');
    }
  }

  // Kullanıcının API anahtarını al
  static Future<String?> getUserApiKey({
    required String userId,
    required String service,
  }) async {
    try {
      final response = await _supabase
          .from('user_api_keys')
          .select('encrypted_key')
          .eq('user_id', userId)
          .eq('service', service)
          .single();

      return response['encrypted_key'];
    } catch (e) {
      return null;
    }
  }

  // API anahtarını sil
  static Future<void> deleteUserApiKey({
    required String userId,
    required String service,
  }) async {
    try {
      await _supabase
          .from('user_api_keys')
          .delete()
          .eq('user_id', userId)
          .eq('service', service);
    } catch (e) {
      throw Exception('API anahtarı silinemedi: $e');
    }
  }
}
