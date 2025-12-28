import 'package:flutter/material.dart';
import 'dart:async'; // Timer için
import '../services/weather_service.dart';
import '../models/city_data.dart';
import '../services/user_activity_service.dart';
import '../theme/app_theme.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  String? _selectedCity;
  Map<String, dynamic>? _currentWeather;
  
  @override
  bool get wantKeepAlive => true;
  Map<String, dynamic>? _agriculturalWeather;
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Timer? _refreshTimer; // Otomatik yenileme için timer

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _loadSavedCity();

    // Her 10 dakikada bir verileri güncelle
    _refreshTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      if (_selectedCity != null) {
        print('⏰ Otomatik hava durumu güncellemesi başlatılıyor...');
        _loadWeatherData(_selectedCity!);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _refreshTimer?.cancel(); // Timer'ı iptal et
    super.dispose();
  }

  // Kaydedilmiş şehri yükle
  Future<void> _loadSavedCity() async {
    try {
      final savedCity = await UserActivityService.getPreference('city');
      if (savedCity != null && savedCity.isNotEmpty) {
        setState(() {
          _selectedCity = savedCity;
        });
        await _loadWeatherData(savedCity);
      }
    } catch (e) {
      print('Kaydedilmiş şehir yüklenemedi: $e');
    }
  }

  // Hava durumu verilerini yükle
  Future<void> _loadWeatherData(String cityName) async {
    print('🌤️ Hava durumu verisi yükleniyor: $cityName');
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('📍 Şehir koordinatları alınıyor...');
      // Şehir koordinatlarını al
      final coordinates = await WeatherService.getCityCoordinates(cityName);
      print('📍 Koordinatlar: $coordinates');
      
      if (coordinates == null) {
        print('❌ Şehir koordinatları bulunamadı');
        setState(() {
          _errorMessage = 'Şehir bulunamadı: $cityName';
          _isLoading = false;
        });
        return;
      }

      print('🌤️ Hava durumu verisi alınıyor...');
      // Hava durumu verilerini al
      final weatherData = await WeatherService.getCurrentWeather(
        latitude: coordinates['latitude']!,
        longitude: coordinates['longitude']!,
      );
      print('🌤️ Hava durumu verisi: $weatherData');

      print('🌾 Tarımsal veri alınıyor...');
      final agriculturalData = await WeatherService.getAgriculturalWeather(
        latitude: coordinates['latitude']!,
        longitude: coordinates['longitude']!,
      );
      print('🌾 Tarımsal veri: $agriculturalData');

      print('💾 Veriler kaydediliyor...');
      setState(() {
        _currentWeather = weatherData;
        _agriculturalWeather = agriculturalData;
        _selectedCity = cityName; // Şehir adını güncelle
        _isLoading = false;
      });

      // Şehri kaydet
      await UserActivityService.updatePreference(key: 'city', value: cityName);
      print('✅ Şehir tercihi kaydedildi');

      _animationController.forward();
      print('🎉 Hava durumu başarıyla yüklendi!');
    } catch (e) {
      print('❌ Hata oluştu: $e');
      setState(() {
        _errorMessage = 'Hava durumu verisi alınamadı: $e';
        _isLoading = false;
      });
    }
  }

  // Şehir seçimi dialogu
  void _showCitySelectionDialog() {
    final TextEditingController searchController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) {
          String currentQuery = searchController.text.trim();

          String normalize(String text) {
            return text.toLowerCase()
              .replaceAll('ğ', 'g')
              .replaceAll('ü', 'u')
              .replaceAll('ş', 's')
              .replaceAll('ı', 'i')
              .replaceAll('i', 'i')
              .replaceAll('ö', 'o')
              .replaceAll('ç', 'c');
          }

          List<CityData> getFilteredCities() {
            final cities = CityData.getTurkishCities();
            if (currentQuery.isEmpty) {
              return cities;
            }
            final normalizedQuery = normalize(currentQuery);
            return cities.where((city) {
              return normalize(city.name).contains(normalizedQuery) ||
                     normalize(city.region).contains(normalizedQuery);
            }).toList();
          }

          final filteredCities = getFilteredCities();

          return DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (_, controller) => Container(
              decoration: const BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Şehir ara... (81 il)',
                        prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            searchController.clear();
                            setStateModal(() {});
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) {
                         setStateModal(() {});
                      },
                    ),
                  ),
                  Expanded(
                    child: filteredCities.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  'Şehir bulunamadı',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            key: ValueKey('list_${currentQuery.length}'), 
                            controller: controller, // DraggableScrollableSheet controller
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: filteredCities.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final city = filteredCities[index];
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.location_city,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                title: Text(
                                  city.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                subtitle: Text(city.region),
                                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                                onTap: () {
                                  Navigator.pop(context);
                                  _loadWeatherData(city.name);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  title: Text(
                    'Hava Durumu',
                    style: AppTheme.modernTitle.copyWith(fontSize: 32),
                  ),
                  centerTitle: false,
                  backgroundColor: AppTheme.backgroundColor,
                  surfaceTintColor: Colors.transparent,
                  pinned: true,
                  floating: true,
                  expandedHeight: 0,
                  automaticallyImplyLeading: false,
                  actions: [
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.location_city, color: AppTheme.textPrimary),
                        onPressed: _showCitySelectionDialog,
                        tooltip: 'Şehir Değiştir',
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.refresh, color: AppTheme.primaryColor),
                        onPressed: _selectedCity != null ? () => _loadWeatherData(_selectedCity!) : null,
                        tooltip: 'Yenile',
                      ),
                    ),
                  ],
                ),
                if (_errorMessage != null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 60, color: AppTheme.errorColor.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppTheme.errorColor),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _showCitySelectionDialog,
                            child: const Text('Şehir Seç'),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_selectedCity == null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.location_city, size: 60, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Şehir Seçin',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Hava durumu bilgilerini görmek için şehir seçin',
                            style: TextStyle(color: AppTheme.textLight),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _showCitySelectionDialog,
                            icon: const Icon(Icons.location_city),
                            label: const Text('Şehir Seç'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Bottom padding for Nav
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCurrentWeatherCard(),
                              const SizedBox(height: 20),
                              _buildAgriculturalDataCard(),
                              const SizedBox(height: 20),
                              _buildRecommendationsCard(),
                              const SizedBox(height: 20),
                              _buildHourlyForecastCard(),
                            ],
                          ),
                        ),
                      ]),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildCurrentWeatherCard() {
    if (_currentWeather == null) return const SizedBox.shrink();

    final current = _currentWeather!['current'];
    final temperature = (current['temperature_2m'] as num?)?.toDouble();
    final humidity = (current['relative_humidity_2m'] as num?)?.toDouble();
    final weatherCode = current['weather_code'] as int?;
    final windSpeed = (current['wind_speed_10m'] as num?)?.toDouble();
    final pressure = (current['pressure_msl'] as num?)?.toDouble();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedCity!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      WeatherService.getWeatherDescription(weatherCode ?? 0),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                WeatherService.formatTemperature(temperature),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeatherInfo(
                  Icons.water_drop_outlined,
                  'Nem',
                  WeatherService.formatHumidity(humidity),
                ),
                Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.2)),
                _buildWeatherInfo(
                  Icons.air,
                  'Rüzgar',
                  WeatherService.formatWindSpeed(windSpeed),
                ),
                Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.2)),
                _buildWeatherInfo(
                  Icons.speed,
                  'Basınç',
                  WeatherService.formatPressure(pressure),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherInfo(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildAgriculturalDataCard() {
    if (_agriculturalWeather == null || _currentWeather == null) return const SizedBox.shrink();

    final weatherCurrent = _currentWeather!['current'];
    
    // Tip dönüşümleri
    final apparentTemp = (weatherCurrent['apparent_temperature'] as num?)?.toDouble();
    final dewpoint = (weatherCurrent['dewpoint_2m'] as num?)?.toDouble();
    final uvIndex = (weatherCurrent['uv_index'] as num?)?.toDouble();
    final precipitation = (weatherCurrent['precipitation'] as num?)?.toDouble();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.agriculture, color: AppTheme.secondaryColor),
              ),
              const SizedBox(width: 12),
              const Text(
                'Tarımsal Veriler',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildAgriculturalInfo(
                  Icons.thermostat,
                  'Hissedilen',
                  WeatherService.formatTemperature(apparentTemp),
                  Colors.orange,
                ),
              ),
              Expanded(
                child: _buildAgriculturalInfo(
                  Icons.water,
                  'Çiğ Noktası',
                  WeatherService.formatTemperature(dewpoint),
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildAgriculturalInfo(
                  Icons.wb_sunny,
                  'UV İndeksi',
                  uvIndex?.toStringAsFixed(1) ?? 'N/A',
                  Colors.amber,
                ),
              ),
              Expanded(
                child: _buildAgriculturalInfo(
                  Icons.cloudy_snowing,
                  'Yağış',
                  WeatherService.formatPrecipitation(precipitation),
                  Colors.indigo,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAgriculturalInfo(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    if (_currentWeather == null) return const SizedBox.shrink();

    final recommendations = WeatherService.getAgriculturalRecommendations(_currentWeather!);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.recommend, color: AppTheme.successColor),
              ),
              const SizedBox(width: 12),
              const Text(
                'Tarımsal Öneriler',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...recommendations.map((recommendation) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle, size: 20, color: AppTheme.successColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        recommendation,
                        style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.4),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildHourlyForecastCard() {
    if (_currentWeather == null || _currentWeather!['hourly'] == null) {
      return const SizedBox.shrink();
    }

    final hourly = _currentWeather!['hourly'];
    final temperatures = hourly['temperature_2m'] as List<dynamic>? ?? [];
    final weatherCodes = hourly['weather_code'] as List<dynamic>? ?? [];
    final times = hourly['time'] as List<dynamic>? ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '24 Saatlik Tahmin',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: temperatures.length > 24 ? 24 : temperatures.length,
              itemBuilder: (context, index) {
                final temperature = (temperatures[index] as num?)?.toDouble();
                final weatherCode = weatherCodes[index] as int?;
                final time = times[index];
                
                final hour = DateTime.parse(time).hour;
                
                return Container(
                  width: 70,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${hour.toString().padLeft(2, '0')}:00',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Icon(getWeatherIcon(weatherCode ?? 0), size: 24, color: AppTheme.primaryColor),
                      const SizedBox(height: 8),
                      Text(
                        WeatherService.formatTemperature(temperature),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  IconData getWeatherIcon(int code) {
    // Basit bir eşleştirme, normalde service'den gelmeli
    if (code == 0) return Icons.wb_sunny;
    if (code < 3) return Icons.cloud;
    if (code < 50) return Icons.foggy;
    if (code < 70) return Icons.water_drop;
    if (code < 80) return Icons.cloudy_snowing;
    return Icons.thunderstorm;
  }
}
