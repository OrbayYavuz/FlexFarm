import 'package:supabase_flutter/supabase_flutter.dart';

class SecureApiService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Groq Edge Function Çağrısı
  static Future<Map<String, dynamic>> invokeGroq(Map<String, dynamic> body) async {
    try {
      final response = await _supabase.functions.invoke(
        'groq-proxy',
        body: body,
      );

      if (response.status == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Groq API Hatası: ${response.status} - ${response.data}');
      }
    } catch (e) {
      throw Exception('Groq servisine bağlanılamadı: $e');
    }
  }

  // OpenAI Edge Function Çağrısı (İhtiyaç olursa)
  static Future<Map<String, dynamic>> invokeOpenAI(Map<String, dynamic> body) async {
    try {
      final response = await _supabase.functions.invoke(
        'openai-proxy',
        body: body,
      );

      if (response.status == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('OpenAI API Hatası: ${response.status} - ${response.data}');
      }
    } catch (e) {
      throw Exception('OpenAI servisine bağlanılamadı: $e');
    }
  }
}
