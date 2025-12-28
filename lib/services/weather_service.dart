import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class WeatherService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  
  // Cache için static değişkenler
  static Map<String, dynamic>? _cachedWeatherData;
  static Map<String, dynamic>? _cachedAgriculturalData;
  static DateTime? _lastWeatherUpdate;
  static DateTime? _lastAgriculturalUpdate;
  static const Duration _cacheDuration = Duration(minutes: 10); // 10 dakika cache
  
  // Cache için son konum bilgileri
  static double? _lastLat;
  static double? _lastLon;

  // Şehir isminden koordinatları alcache

  // ========== ŞEHİR KOORDİNATLARI ==========
  
  /// Şehir adından koordinatları al (Nominatim API'den)
  static Future<Map<String, double>?> getCityCoordinates(String cityName) async {
    try {
      print('📍 Nominatim API\'den şehir koordinatları alınıyor: $cityName');
      
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?'
        'q=$cityName,Turkey&format=json&limit=1'
      );

      print('📍 Nominatim URL: $url');
      
      final response = await http.get(url, headers: {
        'User-Agent': 'FlexTarm/1.0',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        
        if (data.isNotEmpty) {
          final result = data[0];
          final coordinates = {
            'latitude': double.parse(result['lat']),
            'longitude': double.parse(result['lon']),
          };
          print('✅ Koordinatlar bulundu: $coordinates');
          return coordinates;
        } else {
          print('❌ Şehir bulunamadı: $cityName');
          return null;
        }
      } else {
        print('❌ Nominatim API hatası: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Şehir koordinatları alınamadı: $e');
      return null;
    }
  }

  // ========== HAVA DURUMU VERİLERİ ==========

  /// Güncel hava durumu (Cache ile)
  static Future<Map<String, dynamic>?> getCurrentWeather({
    required double latitude,
    required double longitude,
  }) async {
    try {
      // Koordinat kontrolü - Konum değiştiyse cache'i geçersiz say
      bool locationChanged = _lastLat != latitude || _lastLon != longitude;

      // Cache kontrolü
      if (!locationChanged &&
          _cachedWeatherData != null && 
          _lastWeatherUpdate != null && 
          DateTime.now().difference(_lastWeatherUpdate!) < _cacheDuration) {
        print('🌤️ Cache\'den hava durumu verisi alınıyor');
        return _cachedWeatherData;
      }

      print('🌤️ Open Meteo API\'den hava durumu verisi alınıyor... (Konum değişti: $locationChanged)');
      
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?'
        'latitude=$latitude&longitude=$longitude&'
        'current=temperature_2m,relative_humidity_2m,dewpoint_2m,apparent_temperature,'
        'precipitation,rain,showers,snowfall,weather_code,cloud_cover,pressure_msl,'
        'surface_pressure,wind_speed_10m,wind_direction_10m,uv_index&'
        'hourly=temperature_2m,weather_code&'
        'timezone=auto'
      );

      print('📍 API URL: $url');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Cache'e ve konumu kaydet
        _cachedWeatherData = data;
        _lastWeatherUpdate = DateTime.now();
        _lastLat = latitude;
        _lastLon = longitude;
        
        print('✅ Open Meteo API\'den hava durumu verisi alındı ve cache\'e kaydedildi');
        return data;
      } else {
        print('❌ API hatası: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Hava durumu verisi alınamadı: $e');
      return null;
    }
  }

  /// Tarımsal hava durumu (Cache ile)
  static Future<Map<String, dynamic>?> getAgriculturalWeather({
    required double latitude,
    required double longitude,
  }) async {
    try {
      // Koordinat kontrolü
      bool locationChanged = _lastLat != latitude || _lastLon != longitude;

      // Cache kontrolü
      if (!locationChanged &&
          _cachedAgriculturalData != null && 
          _lastAgriculturalUpdate != null && 
          DateTime.now().difference(_lastAgriculturalUpdate!) < _cacheDuration) {
        print('🌾 Cache\'den tarımsal veri alınıyor');
        return _cachedAgriculturalData;
      }

      print('🌾 Open Meteo API\'den tarımsal veri alınıyor... (Konum değişti: $locationChanged)');
      
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?'
        'latitude=$latitude&longitude=$longitude&'
        'current=soil_temperature_0cm,soil_temperature_6cm,soil_temperature_18cm,'
        'soil_moisture_0_to_1cm,soil_moisture_1_to_3cm,soil_moisture_3_to_9cm,soil_moisture_9_to_27cm&'
        'hourly=soil_temperature_0cm,soil_temperature_6cm,soil_temperature_18cm,'
        'soil_moisture_0_to_1cm,soil_moisture_1_to_3cm,soil_moisture_3_to_9cm,soil_moisture_9_to_27cm&'
        'daily=temperature_2m_max,temperature_2m_min,precipitation_sum,rain_sum,showers_sum,snowfall_sum,precipitation_hours,weather_code&'
        'timezone=auto'
      );

      print('📍 Tarımsal API URL: $url');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Cache'e kaydet
        _cachedAgriculturalData = data;
        _lastAgriculturalUpdate = DateTime.now();
        
        print('✅ Open Meteo API\'den tarımsal veri alındı ve cache\'e kaydedildi');
        return data;
      } else {
        print('❌ Tarımsal API hatası: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Tarımsal veri alınamadı: $e');
      return null;
    }
  }

  // ========== VERİ İŞLEME ==========

  /// Hava durumu kodunu açıklamaya çevir
  static String getWeatherDescription(int weatherCode) {
    switch (weatherCode) {
      case 0:
        return 'Açık';
      case 1:
      case 2:
      case 3:
        return 'Parçalı Bulutlu';
      case 45:
      case 48:
        return 'Sisli';
      case 51:
      case 53:
      case 55:
        return 'Hafif Yağmurlu';
      case 56:
      case 57:
        return 'Hafif Dondurucu Yağmur';
      case 61:
      case 63:
      case 65:
        return 'Yağmurlu';
      case 66:
      case 67:
        return 'Dondurucu Yağmur';
      case 71:
      case 73:
      case 75:
        return 'Karlı';
      case 77:
        return 'Kar Taneleri';
      case 80:
      case 81:
      case 82:
        return 'Sağanak Yağmur';
      case 85:
      case 86:
        return 'Sağanak Kar';
      case 95:
        return 'Fırtınalı';
      case 96:
      case 99:
        return 'Dolu ile Fırtınalı';
      default:
        return 'Bilinmeyen';
    }
  }

  /// Rüzgar yönünü açıklamaya çevir
  static String getWindDirection(int degrees) {
    if (degrees >= 337.5 || degrees < 22.5) return 'Kuzey';
    if (degrees >= 22.5 && degrees < 67.5) return 'Kuzeydoğu';
    if (degrees >= 67.5 && degrees < 112.5) return 'Doğu';
    if (degrees >= 112.5 && degrees < 157.5) return 'Güneydoğu';
    if (degrees >= 157.5 && degrees < 202.5) return 'Güney';
    if (degrees >= 202.5 && degrees < 247.5) return 'Güneybatı';
    if (degrees >= 247.5 && degrees < 292.5) return 'Batı';
    if (degrees >= 292.5 && degrees < 337.5) return 'Kuzeybatı';
    return 'Bilinmeyen';
  }

  /// Toprak nemi seviyesini değerlendir
  static String getSoilMoistureLevel(double moisture) {
    if (moisture < 0.2) return 'Çok Kuru';
    if (moisture < 0.4) return 'Kuru';
    if (moisture < 0.6) return 'Normal';
    if (moisture < 0.8) return 'Nemli';
    return 'Çok Nemli';
  }

  /// UV indeksini değerlendir
  static String getUVIndexLevel(double uvIndex) {
    if (uvIndex < 3) return 'Düşük';
    if (uvIndex < 6) return 'Orta';
    if (uvIndex < 8) return 'Yüksek';
    if (uvIndex < 11) return 'Çok Yüksek';
    return 'Ekstrem';
  }

  // ========== TARIMSAL ÖNERİLER ==========

  /// Hava durumuna göre tarımsal öneriler
  static List<String> getAgriculturalRecommendations(Map<String, dynamic> weatherData) {
    List<String> recommendations = [];
    
    try {
      final current = weatherData['current'];
      final temperature = current['temperature_2m'];
      final humidity = current['relative_humidity_2m'];
      final precipitation = current['precipitation'] ?? 0;
      final windSpeed = current['wind_speed_10m'];

      // Sıcaklık önerileri
      if (temperature < 5) {
        recommendations.add('🌡️ Sıcaklık çok düşük! Bitkileri koruyun.');
      } else if (temperature > 35) {
        recommendations.add('🌡️ Sıcaklık çok yüksek! Gölgelendirme yapın.');
      }

      // Nem önerileri
      if (humidity < 30) {
        recommendations.add('💧 Nem çok düşük! Ek sulama yapın.');
      } else if (humidity > 80) {
        recommendations.add('💧 Nem çok yüksek! Mantar hastalığı riski var.');
      }

      // Yağış önerileri
      if (precipitation > 5) {
        recommendations.add('🌧️ Yoğun yağış! Sulama yapmayın.');
      } else if (precipitation == 0 && humidity < 40) {
        recommendations.add('🌧️ Yağış yok! Sulama gerekebilir.');
      }

      // Rüzgar önerileri
      if (windSpeed > 15) {
        recommendations.add('💨 Güçlü rüzgar! Bitkileri koruyun.');
      }

      // Genel öneriler
      if (recommendations.isEmpty) {
        recommendations.add('✅ Hava koşulları tarım için uygun.');
      }

    } catch (e) {
      recommendations.add('⚠️ Hava durumu verisi işlenemedi.');
    }

    return recommendations;
  }

  // ========== ŞEHİR ÖNERİLERİ ==========

  /// Türkiye'deki tüm iller
  static List<String> getPopularTurkishCities() {
    return [
      'Adana', 'Adıyaman', 'Afyonkarahisar', 'Ağrı', 'Amasya', 'Ankara', 'Antalya', 'Artvin',
      'Aydın', 'Balıkesir', 'Bilecik', 'Bingöl', 'Bitlis', 'Bolu', 'Burdur', 'Bursa',
      'Çanakkale', 'Çankırı', 'Çorum', 'Denizli', 'Diyarbakır', 'Edirne', 'Elazığ', 'Erzincan',
      'Erzurum', 'Eskişehir', 'Gaziantep', 'Giresun', 'Gümüşhane', 'Hakkâri', 'Hatay', 'Isparta',
      'Mersin', 'İstanbul', 'İzmir', 'Kars', 'Kastamonu', 'Kayseri', 'Kırklareli', 'Kırşehir',
      'Kocaeli', 'Konya', 'Kütahya', 'Malatya', 'Manisa', 'Kahramanmaraş', 'Mardin', 'Muğla',
      'Muş', 'Nevşehir', 'Niğde', 'Ordu', 'Rize', 'Sakarya', 'Samsun', 'Siirt',
      'Sinop', 'Sivas', 'Tekirdağ', 'Tokat', 'Trabzon', 'Tunceli', 'Şanlıurfa', 'Uşak',
      'Van', 'Yozgat', 'Zonguldak', 'Aksaray', 'Bayburt', 'Karaman', 'Kırıkkale', 'Batman',
      'Şırnak', 'Bartın', 'Ardahan', 'Iğdır', 'Yalova', 'Karabük', 'Kilis', 'Osmaniye',
      'Düzce'
    ];
  }

  // ========== VERİ FORMATLAMA ==========

  /// Sıcaklığı formatla
  static String formatTemperature(double? temperature) {
    if (temperature == null) return 'N/A';
    return '${temperature.toStringAsFixed(1)}°C';
  }

  /// Nem oranını formatla
  static String formatHumidity(double? humidity) {
    if (humidity == null) return 'N/A';
    return '%${humidity.toStringAsFixed(0)}';
  }

  /// Basıncı formatla
  static String formatPressure(double? pressure) {
    if (pressure == null) return 'N/A';
    return '${pressure.toStringAsFixed(0)} hPa';
  }

  /// Rüzgar hızını formatla
  static String formatWindSpeed(double? windSpeed) {
    if (windSpeed == null) return 'N/A';
    return '${windSpeed.toStringAsFixed(1)} km/h';
  }

  /// Yağış miktarını formatla
  static String formatPrecipitation(double? precipitation) {
    if (precipitation == null) return 'N/A';
    return '${precipitation.toStringAsFixed(1)} mm';
  }
}
