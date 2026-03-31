import 'dart:convert';
import 'dart:typed_data';
import '../models/crop_guide.dart';
import 'secure_api_service.dart';

class AIService {
  // Groq AI - API key is now securely stored in Supabase Edge Functions
  // No API key in client code for security
  // Groq AI - API key is managed by Supabase Edge Function
  // No API key in client code for security


  // Conversation history for context awareness
  static final List<Map<String, String>> _conversationHistory = [];

  // Clear conversation history
  static void clearConversationHistory() {
    _conversationHistory.clear();
  }

  // Get conversation history length
  static int getConversationLength() {
    return _conversationHistory.length;
  }

  // Free AI mock responses (works without API key)
  static String _getFreeAIResponse(String userMessage) {
    final message = userMessage.toLowerCase();
    
    // Plant disease detection patterns
    if (message.contains('hastalık') || message.contains('yararlı')) {
      return '''Tarım AI Asistanı - Ücretsiz Mod

🔍 Hasta Bitki Tespiti:
Yapraklarda sararma, kahverengi lekeler veya solgunluk varsa, bu bitki hastalığının belirtisi olabilir.

💡 Çözüm Önerileri:
1. Mantar hastalıkları için %5'lik bakır sülfat kullanın
2. Böcek zararları için neem yağı spreyi deneyin
3. Yaprakları iyi havalanan bir yere alın
4. Toprak pH'ını kontrol edin (6.5-7.0 ideal)
5. Düzenli sulama yapın ama aşırı sulamayın

⚠️ API anahtarı ekleyerek gerçek AI ile fotoğraf analizi yapabilirsiniz.''';
    }
    
    // Fertilizer advice
    if (message.contains('gübre') || message.contains('fertilizer') || message.contains('besin')) {
      return '''🌱 Gübreleme Önerileri:

**Domates için:**
- Azot: Ekimden önce
- Fosfor: Çiçeklenme döneminde
- Potasyum: Meyve oluşumunda

**Genel Gereksinimler:**
- NPK oranı: 10-10-10 (başlangıç)
- Organik gübre: Aylık 1 kez
- Kompost: Toprak yüzeyine 2-3 cm

**Uygulama Zamanı:**
- Sabah erken saatlerde
- Sulamadan önce
- Hava nemli değilken
      ''';
    }
    
    // Watering advice
    if (message.contains('sulama') || message.contains('su') || message.contains('watering')) {
      return '''💧 Sulama Rehberi:

**Ideal Sulama Zamanı:**
- Sabah 06:00-09:00 (en iyi)
- Akşam 17:00-19:00 (alternatif)
- Öğlen güneşinde ASLA sulamayın!

**Sulama Sıklığı:**
- Bahçe bitkileri: Günde 1-2 kez
- Saksı bitkileri: Her gün
- Su bitkileri: Sürekli nemli

**Kontrol Yöntemi:**
- Parmak testi: İlk 5 cm kurumuş ise sulayın
- Toprak rengi: Kahverengi ise sulayın
- Yaprak kontrolü: Soluyor ise sulayın
      ''';
    }
    
    // Harvest timing
    if (message.contains('hasat') || message.contains('harvest') || message.contains('toplama')) {
      return '''📅 Hasat Zamanı Kılavuzu:

**Domates:**
- Ekimden 70-90 gün sonra
- Kırmızı, yumuşak ve parlak olmalı
- Sabah erken saatlerde toplayın

**Biber:**
- Ekimden 60-80 gün sonra
- İstediğiniz boyut ve renge göre
- Yeşil ise erken, kırmızı ise tam olgun

**Marul:**
- Ekimden 40-60 gün sonra
- Yapraklar sert ama yenilebilir
- Tamamen açmadan hasat edin

**Genel İpuçları:**
- Sabah erken saatlerde hasat edin
- Görsel ve dokusal olarak kontrol edin
- Sıcaklık 20°C altında olsun
      ''';
    }
    
    // General fallback
    return '''🌾 Tarım AI Asistanı - Ücretsiz Mod

Merhaba! Size tarım konusunda yardımcı olmaya çalışıyorum.

**Sık Sorulan Sorular:**
- "Hastalık" → Bitki hastalıkları hakkında bilgi
- "Gübre" → Gübreleme önerileri
- "Sulama" → Sulama rehberi
- "Hasat" → Hasat zamanı bilgileri

**Tarım İpuçları:**
✅ Sabah erken sulama yapın
✅ Toprak pH'ını 6.5-7.0 tutun
✅ Organik gübre kullanın
✅ Düzenli bitki kontrolü yapın

⚠️ Daha gelişmiş AI için API anahtarı ekleyin:
lib/services/ai_service.dart dosyasındaki _apiKey değişkenini güncelleyin.
      ''';
  }

  static Future<String> getAIResponse(String userMessage) async {
    try {
      // Güvenli API çağrısı yap (Groq Edge Function)
      final response = await SecureApiService.invokeGroq({
        'model': 'llama-3.3-70b-versatile',
        'messages': [
          {
            'role': 'system',
            'content': 'Sen Türkiye tarım konusunda uzman bir yapay zeka asistanısın. Kullanıcının sorularını Türkçe olarak detaylı, pratik ve anlaşılır şekilde yanıtla.'
          },
          {
            'role': 'user',
            'content': userMessage,
          },
        ],
        'temperature': 0.7,
        'max_tokens': 2048,
      });

      if (response['choices'] != null && response['choices'].isNotEmpty) {
        return response['choices'][0]['message']['content'];
      } else {
        return 'Hata: API yanıtı beklenmeyen formatta';
      }
    } catch (e) {
      // Fallback olarak ücretsiz AI yanıtları
      print('AI Service Hatası: $e');
      return _getFreeAIResponse(userMessage);
    }
  }

  // Finansal ve Verim Danışmanlık Motoru (Aşama 3)
  static Future<String> getFinancialAdvisory({
    required String cropName,
    required double expectedYieldKg,
    required double minRevenue,
    required double maxRevenue,
  }) async {
    try {
      final prompt = '''
Benim tarlamda şu an $cropName ekili. 
Sisteminizin hesaplamalarına göre tahmini hasadım: ${expectedYieldKg.toStringAsFixed(1)} KG.
Güncel Türkiye Hal/Borsa fiyatlarına göre bu mahsulün bugünkü piyasa değeri Minimum ${minRevenue.toStringAsFixed(0)} TL ile Maksimum ${maxRevenue.toStringAsFixed(0)} TL arasında değişiyor.

Bir tarım ve finans uzmanı olarak;
1. Bu mahsulü taban fiyattan değil de tavan fiyattan (en yüksek kalite) satabilmem için son haftalarda nelere dikkat etmeliyim? (Gübre, su, hasat zamanlaması)
2. Bu mahsul şu an piyasada değerli mi, satmak için bekletmeli miyim yoksa hemen elden mi çıkarmalıyım?
3. Bu elde edeceğim geliri bir sonraki ekim sezonunda tarlamı geliştirmek için nasıl yatırıma dönüştürmeliyim?

Lütfen çok kısa, madde madde, heyecan verici ve net bir Türkçe ile yanıtla.
''';

      final response = await SecureApiService.invokeGroq({
        'model': 'llama-3.3-70b-versatile',
        'messages': [
          {
            'role': 'system',
            'content': 'Sen Türkiye tarım borsası ve ziraat mühendisliği konusunda uzman CEO seviyesinde bir finansal danışmansın. Madde madde, çok net ve profesyonel tavsiyeler verirsin.'
          },
          {
            'role': 'user',
            'content': prompt,
          },
        ],
        'temperature': 0.8,
        'max_tokens': 1500,
      });

      if (response['choices'] != null && response['choices'].isNotEmpty) {
        return response['choices'][0]['message']['content'];
      }
      return 'Danışmanlık verisi alınamadı.';
    } catch (e) {
      print('AI Financial Advisory Hatası: $e');
      return 'Şu an piyasa dalgalanmaları nedeniyle AI sunucularına ulaşılamıyor. Lütfen daha sonra tekrar deneyin.';
    }
  }

  static Future<String> analyzePlantImage(Uint8List imageBytes) async {
    // API key is now securely stored in Supabase Edge Functions
    
    try {
      // Convert image to base64
      final String base64Image = base64Encode(imageBytes);

      final response = await SecureApiService.invokeGroq({
          'model': 'llama-3.2-11b-vision-preview', // Vision yeteneği olan model
          'messages': [
            {
              'role': 'system',
              'content': 'Bu fotoğraftaki bitkiyi detaylı olarak analiz et. Türkiye tarım koşullarına göre değerlendirme yap. Bitki türü, sağlık durumu, hastalık belirtileri, gübreleme önerileri ve hasat bilgisi içeren detaylı bir rapor hazırla. Türkçe ve anlaşılır bir dil kullan.'
            },
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': 'Bu fotoğraftaki bitkiyi analiz et ve detaylı bilgi ver.'
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$base64Image',
                  },
                },
              ],
            },
          ],
          'temperature': 0.7,
          'max_tokens': 2048,
        });

      if (response['choices'] != null && response['choices'].isNotEmpty) {
        return response['choices'][0]['message']['content'];
      } else {
         return 'Görüntü analizi yapılırken beklenmeyen bir yanıt alındı.';
      }

    } catch (e) {
      return 'Görüntü analizi servisine bağlanırken bir hata oluştu: ${e.toString()}\n\nLütfen internet bağlantınızı kontrol edin ve tekrar deneyin.';
    }
  }
  
  // Tahmini hasat zamanı hesaplama
  static Map<String, dynamic> calculateHarvestTime(String cropName, String cityName, DateTime plantingDate) {
    final cropGuide = CropGuide.getCropGuides()[cropName];
    if (cropGuide == null) {
      return {
        'estimatedHarvest': 'Bilinmiyor',
        'daysToHarvest': 0,
        'harvestDate': null,
        'confidence': 'Düşük'
      };
    }

    // Meyve ağaçları için özel hesaplama (yıl cinsinden)
    final fruitTrees = ['Zeytin', 'Üzüm', 'İncir', 'Nar', 'Turunçgil', 'Avokado', 'Mango', 
                       'Elma', 'Armut', 'Şeftali', 'Kiraz', 'Antep Fıstığı', 'Kayısı', 'Çay', 'Fındık'];
    
    if (fruitTrees.contains(cropName)) {
      return _calculateFruitTreeHarvest(cropName, cityName, plantingDate);
    }

    // Sebze ve tarla bitkileri için gün cinsinden hesaplama
    int baseDays = _getBaseHarvestDays(cropName);
    
    // Şehir iklimine göre düzeltme faktörü
    double climateFactor = _getClimateFactor(cityName);
    
    // Mevsimsel düzeltme
    double seasonalFactor = _getSeasonalFactor(plantingDate);
    
    // Toplam hasat süresi hesaplama
    int adjustedDays = (baseDays * climateFactor * seasonalFactor).round();
    
    // Hasat tarihi hesaplama
    DateTime harvestDate = plantingDate.add(Duration(days: adjustedDays));
    
    // Güven seviyesi
    String confidence = _getConfidenceLevel(cropName, cityName);
    
    return {
      'estimatedHarvest': _formatHarvestTime(adjustedDays),
      'daysToHarvest': adjustedDays,
      'harvestDate': harvestDate,
      'confidence': confidence,
      'climateFactor': climateFactor,
      'seasonalFactor': seasonalFactor
    };
  }
  
  // Meyve ağaçları için hasat hesaplama (yıl cinsinden)
  static Map<String, dynamic> _calculateFruitTreeHarvest(String cropName, String cityName, DateTime plantingDate) {
    // İlk meyve verme süresi (yıl)
    int yearsToFirstHarvest = _getFruitTreeYears(cropName);
    
    // Şehir iklimine göre düzeltme (sıcak bölgelerde daha hızlı)
    final warmRegions = ['Antalya', 'Mersin', 'Hatay', 'Adana', 'Kahramanmaraş', 'İzmir', 'Aydın'];
    if (warmRegions.contains(cityName)) {
      yearsToFirstHarvest = (yearsToFirstHarvest * 0.9).round(); // %10 daha hızlı
    }
    
    // Hasat tarihi hesaplama
    DateTime harvestDate = DateTime(
      plantingDate.year + yearsToFirstHarvest,
      plantingDate.month,
      plantingDate.day,
    );
    
    return {
      'estimatedHarvest': '$yearsToFirstHarvest yıl',
      'daysToHarvest': yearsToFirstHarvest * 365,
      'harvestDate': harvestDate,
      'confidence': 'Orta', // Ağaçlar için iklim faktörleri daha değişken
    };
  }
  
  // Meyve ağaçlarının ilk meyve verme süresi (yıl)
  static int _getFruitTreeYears(String cropName) {
    switch (cropName) {
      case 'Elma': return 3;
      case 'Armut': return 3;
      case 'Şeftali': return 2;
      case 'Kiraz': return 3;
      case 'Kayısı': return 2;
      case 'Üzüm': return 2;
      case 'İncir': return 2;
      case 'Nar': return 2;
      case 'Zeytin': return 4;
      case 'Turunçgil': return 3;
      case 'Avokado': return 4;
      case 'Mango': return 4;
      case 'Antep Fıstığı': return 4;
      case 'Fındık': return 4;
      case 'Çay': return 2;
      default: return 3;
    }
  }

  // Mahsul türüne göre temel hasat süresi (Fide dikimi veya tohum ekiminden sonraki gün sayısı)
  static int _getBaseHarvestDays(String cropName) {
    switch (cropName) {
      // Sebzeler (Fide dikiminden sonra)
      case 'Domates': return 75; // 60-90 gün (fide dikiminden sonra)
      case 'Biber': return 70; // 60-80 gün (fide dikiminden sonra)
      case 'Patlıcan': return 80; // 70-90 gün (fide dikiminden sonra)
      case 'Salatalık': return 60; // 50-70 gün (tohum ekiminden sonra)
      case 'Kabak': return 60; // 50-70 gün (tohum ekiminden sonra)
      case 'Marul': return 50; // 45-60 gün (fide dikiminden sonra)
      case 'Ispanak': return 40; // 30-45 gün (tohum ekiminden sonra)
      case 'Maydanoz': return 70; // 60-80 gün (tohum ekiminden sonra)
      case 'Fesleğen': return 70; // 60-80 gün (fide dikiminden sonra)
      
      // Tahıllar (Sonbahar ekimi - Yaz hasadı)
      case 'Buğday': return 250; // Ekim-Kasım ekimi, Haziran-Temmuz hasadı (240-270 gün)
      case 'Arpa': return 240; // Ekim-Kasım ekimi, Haziran-Temmuz hasadı (230-260 gün)
      
      // Endüstriyel ve tarla bitkileri
      case 'Mısır': return 100; // 90-120 gün (Nisan-Mayıs ekimi)
      case 'Patates': return 110; // 90-120 gün (Mart-Nisan ekimi)
      case 'Ayçiçeği': return 100; // 90-120 gün (Nisan-Mayıs ekimi)
      case 'Şeker Pancarı': return 160; // 150-180 gün (Mart-Nisan ekimi)
      case 'Soğan': return 130; // 120-150 gün (Ekim-Mart ekimi)
      case 'Havuç': return 80; // 70-90 gün (Mart-Ekim ekimi)
      case 'Fasulye': return 70; // 60-80 gün (Nisan-Mayıs ekimi)
      case 'Lahana': return 100; // 80-120 gün (Fide dikiminden sonra)
      case 'Karnabahar': return 100; // 80-120 gün (Fide dikiminden sonra)
      case 'Brokoli': return 100; // 80-120 gün (Fide dikiminden sonra)
      case 'Tütün': return 110; // 90-120 gün (Mart-Nisan ekimi)
      case 'Pamuk': return 160; // 150-180 gün (Nisan-Mayıs ekimi)
      
      // Meyve ağaçları için default değer (aslında _calculateFruitTreeHarvest kullanılır)
      case 'Zeytin':
      case 'Üzüm':
      case 'İncir':
      case 'Nar':
      case 'Turunçgil':
      case 'Avokado':
      case 'Mango':
      case 'Elma':
      case 'Armut':
      case 'Şeftali':
      case 'Kiraz':
      case 'Antep Fıstığı':
      case 'Kayısı':
      case 'Çay':
      case 'Fındık':
        return 730; // 2 yıl (fallback, ama _calculateFruitTreeHarvest kullanılır)
      
      default: return 90;
    }
  }

  // Şehir iklimine göre düzeltme faktörü
  static double _getClimateFactor(String cityName) {
    // Akdeniz iklimi - hızlı büyüme
    if (['Antalya', 'Mersin', 'Hatay', 'Adana', 'Kahramanmaraş'].contains(cityName)) {
      return 0.9; // %10 daha hızlı
    }
    // Karadeniz iklimi - nemli, biraz yavaş
    if (['Trabzon', 'Rize', 'Ordu', 'Giresun', 'Samsun'].contains(cityName)) {
      return 1.1; // %10 daha yavaş
    }
    // Karasal iklim - orta hız
    if (['Ankara', 'Konya', 'Kayseri', 'Sivas', 'Eskişehir', 'Erzurum', 'Van', 'Malatya', 'Elazığ'].contains(cityName)) {
      return 1.0; // Normal hız
    }
    // Ege iklimi - hızlı büyüme
    if (['İzmir', 'Aydın', 'Denizli', 'Manisa'].contains(cityName)) {
      return 0.95; // %5 daha hızlı
    }
    // Marmara iklimi - orta hız
    if (['İstanbul', 'Bursa', 'Tekirdağ', 'Balıkesir'].contains(cityName)) {
      return 1.0; // Normal hız
    }
    // Güneydoğu Anadolu - sıcak, hızlı
    if (['Gaziantep', 'Diyarbakır', 'Şanlıurfa', 'Mardin'].contains(cityName)) {
      return 0.9; // %10 daha hızlı
    }
    return 1.0; // Varsayılan
  }

  // Mevsimsel düzeltme faktörü
  static double _getSeasonalFactor(DateTime plantingDate) {
    int month = plantingDate.month;
    
    // İlkbahar (Mart-Mayıs) - ideal büyüme
    if (month >= 3 && month <= 5) {
      return 1.0; // Normal hız
    }
    // Yaz (Haziran-Ağustos) - sıcak, hızlı büyüme
    if (month >= 6 && month <= 8) {
      return 0.9; // %10 daha hızlı
    }
    // Sonbahar (Eylül-Kasım) - yavaş büyüme
    if (month >= 9 && month <= 11) {
      return 1.2; // %20 daha yavaş
    }
    // Kış (Aralık-Şubat) - çok yavaş
    if (month == 12 || month <= 2) {
      return 1.5; // %50 daha yavaş
    }
    return 1.0;
  }

  // Güven seviyesi
  static String _getConfidenceLevel(String cropName, String cityName) {
    // Yaygın mahsuller için yüksek güven
    if (['Domates', 'Biber', 'Patlıcan', 'Salatalık', 'Marul', 'Ispanak'].contains(cropName)) {
      return 'Yüksek';
    }
    // Tahıl ürünleri için orta güven
    if (['Buğday', 'Arpa', 'Mısır', 'Ayçiçeği'].contains(cropName)) {
      return 'Orta';
    }
    // Diğerleri için düşük güven
    return 'Düşük';
  }

  // Hasat zamanını formatla
  static String _formatHarvestTime(int days) {
    if (days < 30) {
      return '$days gün';
    } else if (days < 60) {
      int weeks = (days / 7).round();
      return '$weeks hafta';
    } else {
      int months = (days / 30).round();
      return '$months ay';
    }
  }

  // Mahsul büyütme ipuçları
  static Map<String, List<String>> getGrowingTips(String cropName, String cityName) {
    Map<String, List<String>> tips = {};
    
    // Genel ipuçları
    tips['Genel'] = [
      'Düzenli sulama yapın - toprak nemini kontrol edin',
      'Güneş ışığını optimize edin - gölge alanlarından kaçının',
      'Toprak pH değerini 6.0-7.0 arasında tutun',
      'Organik gübre kullanarak toprak sağlığını koruyun',
      'Zararlı böcekleri düzenli kontrol edin'
    ];
    
    // Mahsul özel ipuçları
    switch (cropName) {
      case 'Domates':
        tips['Domates İpuçları'] = [
          'Destek çubuğu kullanın - bitkiyi bağlayın',
          'Yan sürgünleri temizleyin - tek gövde bırakın',
          'Çiçeklenme döneminde azot gübresini azaltın',
          'Meyve çatlamasını önlemek için düzenli sulama yapın',
          'Hastalık kontrolü için yaprakları kuru tutun'
        ];
        break;
      case 'Biber':
        tips['Biber İpuçları'] = [
          'Sıcaklığı 20-30°C arasında tutun',
          'İlk çiçekleri koparın - daha iyi verim için',
          'Güneşli yer seçin - günde 6-8 saat güneş',
          'Toprak sıcaklığını kontrol edin',
          'Meyve dökümünü önlemek için düzenli sulama'
        ];
        break;
      case 'Salatalık':
        tips['Salatalık İpuçları'] = [
          'Destek sistemi kullanın - dikey büyütün',
          'Düzenli hasat yapın - büyük meyveler acılaşır',
          'Yaprakları nemli tutun ama çok ıslatmayın',
          'Çiçeklenme döneminde potasyum gübresi verin',
          'Meyve acılaşmasını önlemek için stres yaratmayın'
        ];
        break;
      case 'Marul':
        tips['Marul İpuçları'] = [
          'Serin hava sever - sıcaklığı 15-20°C tutun',
          'Düzenli sulama yapın - toprak nemli olsun',
          'Gölge alan seçin - direkt güneşten koruyun',
          'Yaprak yanıklığını önlemek için sabah sulayın',
          'Hızlı büyüme için azot gübresi kullanın'
        ];
        break;
      case 'Buğday':
        tips['Buğday İpuçları'] = [
          'Ekim zamanını doğru belirleyin - sonbahar ideal',
          'Toprak hazırlığını iyi yapın - derin sürüm',
          'Yabani ot kontrolü yapın - erken müdahale',
          'Gübreleme programını takip edin',
          'Hastalık kontrolü için rotasyon uygulayın'
        ];
        break;
      case 'Mısır':
        tips['Mısır İpuçları'] = [
          'Sıcak hava sever - 20-30°C ideal',
          'Derin toprak gerektirir - kök gelişimi için',
          'Azot gübresini aşamalı verin',
          'Sulama sistemini düzenli kontrol edin',
          'Zararlı böcek kontrolü yapın'
        ];
        break;
    }
    
    // Şehir özel ipuçları
    if (['Antalya', 'Mersin', 'Hatay', 'Adana'].contains(cityName)) {
      tips['Akdeniz İklimi'] = [
        'Yaz sıcağında gölge sağlayın',
        'Sulama sıklığını artırın',
        'Sıcaklık stresini önlemek için malçlama yapın',
        'Sabah erken saatlerde sulama yapın',
        'Nem kontrolü için havalandırmayı artırın'
      ];
    } else if (['Trabzon', 'Rize', 'Ordu', 'Giresun'].contains(cityName)) {
      tips['Karadeniz İklimi'] = [
        'Fazla nemden koruyun - havalandırma önemli',
        'Fungal hastalıklara dikkat edin',
        'Drenaj sistemini kontrol edin',
        'Nem kontrolü için malçlama yapın',
        'Hastalık kontrolü için fungisit kullanın'
      ];
    } else if (['Ankara', 'Konya', 'Kayseri'].contains(cityName)) {
      tips['Karasal İklim'] = [
        'Don riskine karşı koruma sağlayın',
        'Sulama programını optimize edin',
        'Rüzgar koruması sağlayın',
        'Toprak nemini düzenli kontrol edin',
        'Sıcaklık değişimlerine hazırlıklı olun'
      ];
    }
    
    return tips;
  }

  // Tarım ipuçları
  static List<String> getAgricultureTips() {
    return [
      'Sabah erken saatlerde sulama yapın, su kaybını azaltır.',
      'Toprak pH değerini 6.0-7.0 arasında tutun.',
      'Organik gübre kullanarak toprak sağlığını koruyun.',
      'Mahsul rotasyonu yaparak toprak verimliliğini artırın.',
      'Zararlı mücadelesinde doğal yöntemleri tercih edin.',
      'Hasat zamanını doğru belirleyin, erken veya geç hasat verim kaybına neden olur.',
      'Toprak nemini düzenli kontrol edin.',
      'Sera kullanarak mevsim dışı üretim yapabilirsiniz.',
      'Kompost kullanarak organik madde miktarını artırın.',
      'Sulama sisteminizi düzenli kontrol edin.',
    ];
  }
}
