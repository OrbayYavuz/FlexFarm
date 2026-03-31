import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as app_user;

class SupabaseAuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Kullanıcı kaydı
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      print('Supabase kayıt başlıyor: $email');
      
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
        },
      );

      print('Auth response: ${response.user?.id}');
      print('Auth session: ${response.session?.accessToken}');

      // Trigger otomatik olarak profil oluşturacak, manuel profil oluşturmaya gerek yok
      print('Kullanıcı oluşturuldu, trigger otomatik profil oluşturacak');

      return response;
    } catch (e) {
      print('Supabase kayıt hatası: $e');
      throw Exception('Kayıt sırasında hata oluştu: $e');
    }
  }

  // Mevcut kullanıcı için profil oluştur
  static Future<void> createProfileForCurrentUser() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase.from('profiles').insert({
        'id': user.id,
        'email': user.email,
        'name': user.userMetadata?['name'] ?? user.email?.split('@')[0] ?? 'User',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Profil zaten varsa hata vermez
      print('Profil oluşturma hatası: $e');
    }
  }

  // Kullanıcı girişi
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Giriş sırasında hata oluştu: $e');
    }
  }

  // Çıkış yap
  static Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Çıkış sırasında hata oluştu: $e');
    }
  }

  // Mevcut kullanıcıyı al
  static app_user.User? getCurrentUser() {
    final authUser = _supabase.auth.currentUser;
    if (authUser != null) {
      return app_user.User.fromSupabaseAuth(authUser.toJson());
    }
    return null;
  }

  // Kullanıcı profilini oluştur
  static Future<void> _createUserProfile(User authUser, String name) async {
    try {
      print('Profil oluşturuluyor: ${authUser.id}');
      print('Email: ${authUser.email}');
      print('Name: $name');
      
      // Önce mevcut profili kontrol et
      final existingProfile = await _supabase
          .from('profiles')
          .select('id')
          .eq('id', authUser.id)
          .maybeSingle();
      
      if (existingProfile == null) {
        final result = await _supabase.from('profiles').insert({
          'id': authUser.id,
          'email': authUser.email,
          'name': name,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        
        print('Profil oluşturma sonucu: $result');
      } else {
        print('Profil zaten mevcut: ${authUser.id}');
      }
    } catch (e) {
      print('Profil oluşturma hatası: $e');
      // Hata fırlatma, sadece log'la
    }
  }

  // Kullanıcı profilini güncelle
  static Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? avatarUrl,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updateData['name'] = name;
      if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;

      await _supabase.from('profiles').update(updateData).eq('id', userId);
    } catch (e) {
      throw Exception('Profil güncelleme hatası: $e');
    }
  }

  // Kullanıcı profilini veritabanından al
  static Future<app_user.User?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return app_user.User.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Şifre sıfırlama e-postası gönder
  static Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('Şifre sıfırlama e-postası gönderilemedi: $e');
    }
  }

  // Kimlik doğrulama durumunu dinle
  static Stream<AuthState> get authStateChanges {
    return _supabase.auth.onAuthStateChange;
  }

  // Kullanıcının giriş yapıp yapmadığını kontrol et
  static bool get isSignedIn {
    return _supabase.auth.currentUser != null;
  }

  // E-posta doğrulama durumunu kontrol et
  static bool get isEmailVerified {
    return _supabase.auth.currentUser?.emailConfirmedAt != null;
  }
}
