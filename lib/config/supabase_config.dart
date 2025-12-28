import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  static String get supabaseUrl {
    try {
      return dotenv.env['SUPABASE_URL'] ?? 'https://fhdxjihcsngfkzrjlpae.supabase.co';
    } catch (e) {
      return 'https://fhdxjihcsngfkzrjlpae.supabase.co';
    }
  }
  
  static String get supabaseAnonKey {
    try {
      return dotenv.env['SUPABASE_ANON_KEY'] ?? 'sb_publishable_ltaNA7nnVozoSCOcZIjg';
    } catch (e) {
      return 'sb_publishable_ltaNA7nnVozoSCOcZIjg';
    }
  }
  
  static String get openaiApiKey {
    try {
      return dotenv.env['OPENAI_API_KEY'] ?? '';
    } catch (e) {
      return '';
    }
  }
  
  static String get groqApiKey {
    try {
      return dotenv.env['GROQ_API_KEY'] ?? '';
    } catch (e) {
      return '';
    }
  }
}
