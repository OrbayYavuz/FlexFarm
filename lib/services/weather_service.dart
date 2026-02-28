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
  
  // Çevrimdışı / Hata Durumu İçin 81 İlin Yedek Koordinatları
  static const Map<String, Map<String, double>> _fallbackCoordinates = {
    'Adana': {'latitude': 37.0000, 'longitude': 35.3213},
    'Adıyaman': {'latitude': 37.7648, 'longitude': 38.2786},
    'Afyonkarahisar': {'latitude': 38.7507, 'longitude': 30.5567},
    'Ağrı': {'latitude': 39.7191, 'longitude': 43.0503},
    'Amasya': {'latitude': 40.6499, 'longitude': 35.8353},
    'Ankara': {'latitude': 39.9208, 'longitude': 32.8541},
    'Antalya': {'latitude': 36.8969, 'longitude': 30.7133},
    'Artvin': {'latitude': 41.1828, 'longitude': 41.8183},
    'Aydın': {'latitude': 37.8380, 'longitude': 27.8456},
    'Balıkesir': {'latitude': 39.6484, 'longitude': 27.8826},
    'Bilecik': {'latitude': 40.1451, 'longitude': 29.9798},
    'Bingöl': {'latitude': 38.8847, 'longitude': 40.4939},
    'Bitlis': {'latitude': 38.4006, 'longitude': 42.1095},
    'Bolu': {'latitude': 40.7392, 'longitude': 31.6116},
    'Burdur': {'latitude': 37.7183, 'longitude': 30.2823},
    'Bursa': {'latitude': 40.1824, 'longitude': 29.0671},
    'Çanakkale': {'latitude': 40.1553, 'longitude': 26.4142},
    'Çankırı': {'latitude': 40.6013, 'longitude': 33.6134},
    'Çorum': {'latitude': 40.5506, 'longitude': 34.9556},
    'Denizli': {'latitude': 37.7765, 'longitude': 29.0864},
    'Diyarbakır': {'latitude': 37.9144, 'longitude': 40.2306},
    'Edirne': {'latitude': 41.6771, 'longitude': 26.5557},
    'Elazığ': {'latitude': 38.6810, 'longitude': 39.2264},
    'Erzincan': {'latitude': 39.7392, 'longitude': 39.4902},
    'Erzurum': {'latitude': 39.9043, 'longitude': 41.2679},
    'Eskişehir': {'latitude': 39.7767, 'longitude': 30.5206},
    'Gaziantep': {'latitude': 37.0662, 'longitude': 37.3833},
    'Giresun': {'latitude': 40.9128, 'longitude': 38.3895},
    'Gümüşhane': {'latitude': 40.4608, 'longitude': 39.4814},
    'Hakkâri': {'latitude': 37.5833, 'longitude': 43.7333},
    'Hatay': {'latitude': 36.4018, 'longitude': 36.3498},
    'Isparta': {'latitude': 37.7648, 'longitude': 30.5566},
    'Mersin': {'latitude': 36.8121, 'longitude': 34.6415},
    'İstanbul': {'latitude': 41.0082, 'longitude': 28.9784},
    'İzmir': {'latitude': 38.4192, 'longitude': 27.1287},
    'Kars': {'latitude': 40.6013, 'longitude': 43.0975},
    'Kastamonu': {'latitude': 41.3887, 'longitude': 33.7827},
    'Kayseri': {'latitude': 38.7312, 'longitude': 35.4787},
    'Kırklareli': {'latitude': 41.7333, 'longitude': 27.2167},
    'Kırşehir': {'latitude': 39.1425, 'longitude': 34.1709},
    'Kocaeli': {'latitude': 40.7654, 'longitude': 29.9408},
    'Konya': {'latitude': 37.8667, 'longitude': 32.4833},
    'Kütahya': {'latitude': 39.4167, 'longitude': 29.9833},
    'Malatya': {'latitude': 38.3552, 'longitude': 38.3095},
    'Manisa': {'latitude': 38.6120, 'longitude': 27.4260},
    'Kahramanmaraş': {'latitude': 37.5858, 'longitude': 36.9371},
    'Mardin': {'latitude': 37.3212, 'longitude': 40.7245},
    'Muğla': {'latitude': 37.2153, 'longitude': 28.3636},
    'Muş': {'latitude': 38.7346, 'longitude': 41.4910},
    'Nevşehir': {'latitude': 38.6244, 'longitude': 34.7144},
    'Niğde': {'latitude': 37.9667, 'longitude': 34.6833},
    'Ordu': {'latitude': 40.9862, 'longitude': 37.8797},
    'Rize': {'latitude': 41.0201, 'longitude': 40.5234},
    'Sakarya': {'latitude': 40.7569, 'longitude': 30.3783},
    'Samsun': {'latitude': 41.2867, 'longitude': 36.33},
    'Siirt': {'latitude': 37.9333, 'longitude': 41.95},
    'Sinop': {'latitude': 42.0231, 'longitude': 35.1531},
    'Sivas': {'latitude': 39.7477, 'longitude': 37.0179},
    'Tekirdağ': {'latitude': 40.9833, 'longitude': 27.5167},
    'Tokat': {'latitude': 40.3167, 'longitude': 36.55},
    'Trabzon': {'latitude': 41.0015, 'longitude': 39.7178},
    'Tunceli': {'latitude': 39.1079, 'longitude': 39.5401},
    'Şanlıurfa': {'latitude': 37.15, 'longitude': 38.8},
    'Uşak': {'latitude': 38.6823, 'longitude': 29.4082},
    'Van': {'latitude': 38.4891, 'longitude': 43.3889},
    'Yozgat': {'latitude': 39.8181, 'longitude': 34.8147},
    'Zonguldak': {'latitude': 41.4504, 'longitude': 31.7829},
    'Aksaray': {'latitude': 38.3687, 'longitude': 34.037},
    'Bayburt': {'latitude': 40.2552, 'longitude': 40.2249},
    'Karaman': {'latitude': 37.1811, 'longitude': 33.2222},
    'Kırıkkale': {'latitude': 39.8468, 'longitude': 33.5153},
    'Batman': {'latitude': 37.8812, 'longitude': 41.1351},
    'Şırnak': {'latitude': 37.5228, 'longitude': 42.4594},
    'Bartın': {'latitude': 41.6344, 'longitude': 32.3375},
    'Ardahan': {'latitude': 41.1105, 'longitude': 42.7022},
    'Iğdır': {'latitude': 39.9237, 'longitude': 44.045},
    'Yalova': {'latitude': 40.65, 'longitude': 29.2667},
    'Karabük': {'latitude': 41.2061, 'longitude': 32.6234},
    'Kilis': {'latitude': 36.7184, 'longitude': 37.1147},
    'Osmaniye': {'latitude': 37.0742, 'longitude': 36.2475},
    'Düzce': {'latitude': 40.8358, 'longitude': 31.1578}
  };

  /// Şehir adından koordinatları al (Nominatim API'den ve Yedek Listeden)
  static Future<Map<String, double>?> getCityCoordinates(String cityName) async {
    try {
      print('📍 Nominatim API\'den şehir koordinatları alınıyor: $cityName');
      
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?'
        'q=$cityName,Turkey&format=json&limit=1'
      );

      final response = await http.get(url, headers: {
        'User-Agent': 'FlexTarm/1.0',
      }).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        
        if (data.isNotEmpty) {
           final result = data[0];
           final coordinates = {
             'latitude': double.parse(result['lat']),
             'longitude': double.parse(result['lon']),
           };
           print('✅ Çevrimiçi Koordinatlar bulundu: $coordinates');
           return coordinates;
        }
      }
      
      // API Bos donduyse veya 403 yediyse Fallback uzerinden don
      print('⚠️ API yanıt vermedi. $cityName için yerel koordinatlara bakılıyor...');
      return _fallbackCoordinates[cityName];
      
    } catch (e) {
      print('❌ Şehir koordinatları alınırken hata (İnternet Kopuk Olabilir): $e');
      // İnternet sorunu yaşanırsa çökmesin, doğrudan yerel koordinat döndür
      return _fallbackCoordinates[cityName];
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
