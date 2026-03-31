// lib/services/admin_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Admin kullanıcı kontrolü
  static Future<bool> isAdmin() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();

      return response['role'] == 'admin';
    } catch (e) {
      return false;
    }
  }

  // Admin ekin silme
  static Future<bool> adminDeleteCrop(String cropId) async {
    try {
      final response = await _supabase.functions.invoke(
        'admin-delete-crop',
        body: {
          'crop_id': cropId,
        },
      );

      if (response.data != null && response.data['success'] == true) {
        return true;
      } else {
        throw Exception(response.data?['error'] ?? 'Unknown error');
      }
    } catch (e) {
      throw Exception('Admin delete failed: $e');
    }
  }

  // Admin kullanıcı silme
  static Future<bool> adminDeleteUser(String userId) async {
    try {
      final response = await _supabase.functions.invoke(
        'admin-delete-user',
        body: {
          'user_id': userId,
        },
      );

      if (response.data != null && response.data['success'] == true) {
        return true;
      } else {
        throw Exception(response.data?['error'] ?? 'Unknown error');
      }
    } catch (e) {
      throw Exception('Admin delete user failed: $e');
    }
  }

  // Admin kullanıcı rolü güncelleme
  static Future<bool> adminUpdateUserRole(String userId, String role) async {
    try {
      final response = await _supabase.functions.invoke(
        'admin-update-user-role',
        body: {
          'user_id': userId,
          'role': role,
        },
      );

      if (response.data != null && response.data['success'] == true) {
        return true;
      } else {
        throw Exception(response.data?['error'] ?? 'Unknown error');
      }
    } catch (e) {
      throw Exception('Admin update role failed: $e');
    }
  }
}

