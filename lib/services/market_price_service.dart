import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/crop_price_data.dart';

class MarketPriceService {
  static final _supabase = Supabase.instance.client;

  /// Supabase'den belirli bir mahsulun guncel piyasa fiyatini ceker
  static Future<CropPriceData?> getLivePriceForCrop(String cropId) async {
    try {
      final response = await _supabase
          .from('daily_crop_prices')
          .select()
          .eq('crop_id', cropId)
          .maybeSingle();

      if (response == null) return null;

      return CropPriceData.fromJson(response);
    } catch (e) {
      print('MarketPriceService Error: Fiyat cekilirken hata olustu: $e');
      return null;
    }
  }

  /// Supabase'den tum hal fiyatlarini liste olarak ceker
  static Future<List<CropPriceData>> getAllLivePrices() async {
    try {
      final response = await _supabase
          .from('daily_crop_prices')
          .select()
          .order('last_updated', ascending: false);

      return (response as List).map((json) => CropPriceData.fromJson(json)).toList();
    } catch (e) {
      print('MarketPriceService Error: Tum fiyatlar cekilirken hata olustu: $e');
      return [];
    }
  }
}
