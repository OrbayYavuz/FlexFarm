import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/supabase_auth_service.dart';
import '../services/user_activity_service.dart';
import '../services/weather_service.dart';
import '../theme/app_theme.dart';
import 'crops_screen.dart';
import 'ai_helper_screen.dart';
import 'ai_support_screen.dart';
import 'marketplace_screen.dart';
import 'weather_screen.dart';
import 'profile_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/notification_service.dart';
import '../services/message_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  bool _isLoadingUserData = true;
  String? _currentCity;
  double? _currentTemperature;
  int? _weatherCode;
  
  // Cache için değişkenler
  // ignore: unused_field
  DateTime? _lastWeatherLoad;
  static const Duration _weatherCacheDuration = Duration(minutes: 10);
  
  // Subscription
  RealtimeChannel? _messagesSubscription;

  final List<Widget> _screens = [
    const CropsScreen(),
    const WeatherScreen(),
    const AIHelperScreen(),
    const AISupportScreen(),
    const MarketplaceScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeUserData();
    _startWeatherUpdateTimer();
    _setupMessageListener();
  }

  @override
  void dispose() {
    _messagesSubscription?.unsubscribe();
    _pageController.dispose();
    super.dispose();
  }

  // NotificationService zaten main.dart'ta başlatılıyor, tekrar çağırmaya gerek yok

  // Gelen mesajları dinle
  void _setupMessageListener() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    _messagesSubscription = Supabase.instance.client
        .channel('public:marketplace_messages')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'marketplace_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'receiver_id',
            value: user.id,
          ),
          callback: (payload) async {
            // Yeni mesaj geldi!
            final newMsg = payload.newRecord;
            
            // Eğer gönderen ben isem yoksay
            if (newMsg['sender_id'] == user.id) return;
            
            // Eğer şu an bu sohbetteysem bildirim gösterme
            if (MessageService.currentChatListingId == newMsg['listing_id']) return;
            
            // İlan adını bul
            String listingTitle = 'Ürün';
            try {
              final listing = await Supabase.instance.client
                  .from('marketplace_items')
                  .select('title')
                  .eq('id', newMsg['listing_id'])
                  .single();
              listingTitle = listing['title'] ?? 'Ürün';
            } catch (e) {
              print('İlan adı bulunamadı: $e');
            }

            // Gönderen adını bul
            String senderName = 'Kullanıcı';
            try {
              final sender = await Supabase.instance.client
                  .from('profiles')
                  .select('name')
                  .eq('id', newMsg['sender_id'])
                  .single();
              senderName = sender['name'] ?? 'Kullanıcı';
            } catch (e) {
              print('Gönderen adı bulunamadı: $e');
            }

            // Bildirim göster
            await NotificationService.showInstantNotification(
              id: (newMsg['id'].hashCode).abs(),
              title: 'Yeni Mesaj 💬',
              body: '$senderName ($listingTitle): ${newMsg['message']}', // Mesaj içeriğini de gösterelim
              payload: 'chat|${newMsg['listing_id']}|${newMsg['sender_id']}|$senderName|$listingTitle',
            );
          },
        )
        .subscribe();
  }

  Future<void> _initializeUserData() async {
    try {
      // Profil + kullanıcı verisi + hava durumu PARALEL yükle
      await Future.wait([
        SupabaseAuthService.createProfileForCurrentUser().catchError((e) {
          if (kDebugMode) print('Profil oluşturma hatası: $e');
        }),
        UserActivityService.loadUserData().catchError((e) {
          if (kDebugMode) print('Kullanıcı verisi hatası: $e');
          return <String, dynamic>{};
        }),
        _loadWeatherDataOnce(),
      ]);
      
      if (mounted) {
        setState(() {
          _isLoadingUserData = false;
        });
      }
    } catch (e) {
      if (kDebugMode) print('Kullanıcı verileri yüklenirken hata: $e');
      if (mounted) {
        setState(() {
          _isLoadingUserData = false;
        });
      }
    }
  }

  // Sadece bir kez yükle ve sonra cache'den al
  Future<void> _loadWeatherDataOnce() async {
    try {
      final savedCity = await UserActivityService.getPreference('city');
      if (savedCity != null && savedCity.isNotEmpty) {
        _currentCity = savedCity;
        
        final coordinates = await WeatherService.getCityCoordinates(savedCity);
        if (coordinates != null) {
          final weatherData = await WeatherService.getCurrentWeather(
            latitude: coordinates['latitude']!,
            longitude: coordinates['longitude']!,
          );
          
          if (weatherData != null && weatherData['current'] != null) {
            final current = weatherData['current'];
            if (mounted) {
              setState(() {
                _currentTemperature = (current['temperature_2m'] as num?)?.toDouble();
                _weatherCode = current['weather_code'] as int?;
                _lastWeatherLoad = DateTime.now();
              });
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('Hava durumu verisi yüklenirken hata: $e');
    }
  }

  // Otomatik güncelleme için timer
  void _startWeatherUpdateTimer() {
    Timer.periodic(_weatherCacheDuration, (timer) {
      if (mounted && _currentCity != null) {
        _loadWeatherDataOnce();
      }
    });
  }

  Widget _buildWeatherInfo() {
    if (_currentCity == null || _currentTemperature == null) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: Icon(
          Icons.location_city,
          color: Colors.white70,
          size: 14,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 12.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getWeatherIcon(_weatherCode ?? 0),
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 1),
          Text(
            '${_currentTemperature!.toStringAsFixed(0)}°',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getWeatherIcon(int weatherCode) {
    switch (weatherCode) {
      case 0:
        return Icons.wb_sunny; // ☀️ Açık - Güneş
      case 1:
      case 2:
      case 3:
        return Icons.cloud; // ☁️ Parçalı Bulutlu - Bulut
      case 45:
      case 48:
        return Icons.foggy; // 🌫️ Sisli - Sis
      case 51:
      case 53:
      case 55:
        return Icons.grain; // 🌧️ Hafif Yağmurlu - Yağmur
      case 56:
      case 57:
        return Icons.ac_unit; // ❄️ Dondurucu Yağmur - Kar
      case 61:
      case 63:
      case 65:
        return Icons.grain; // 🌧️ Yağmurlu - Yağmur
      case 66:
      case 67:
        return Icons.ac_unit; // ❄️ Dondurucu Yağmur - Kar
      case 71:
      case 73:
      case 75:
        return Icons.ac_unit; // ❄️ Karlı - Kar
      case 77:
        return Icons.ac_unit; // ❄️ Kar Taneleri - Kar
      case 80:
      case 81:
      case 82:
        return Icons.thunderstorm; // ⛈️ Sağanak Yağmur - Fırtına
      case 85:
      case 86:
        return Icons.ac_unit; // ❄️ Sağanak Kar - Kar
      case 95:
        return Icons.thunderstorm; // ⛈️ Fırtınalı - Fırtına
      case 96:
      case 99:
        return Icons.thunderstorm; // ⛈️ Dolu ile Fırtınalı - Fırtına
      default:
        return Icons.cloud; // ☁️ Varsayılan - Bulut
    }
  }

  void _logout() async {
    try {
      await SupabaseAuthService.signOut();
      // AuthWrapper otomatik olarak login screen'e yönlendirecek
      // Bu yüzden navigation'a gerek yok
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Çıkış yapılırken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // İçeriğin navigation bar altına uzamasını sağlar
      body: _isLoadingUserData
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Kullanıcı verileri yükleniyor...'),
                ],
              ),
            )
          : Stack(
              children: [
                  // Ana İçerik - PageView ile kaydırmalı geçiş
                  PageView(
                    controller: _pageController,
                    // physics: const NeverScrollableScrollPhysics(), // Kaldırıldı: Kaydırma aktif
                    onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  children: _screens,
                ),
                
                // Floating Navigation Bar
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: AppTheme.glassDecoration,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildNavItem(0, Icons.grass, 'Mahsuller'),
                          const SizedBox(width: 4),
                          _buildNavItem(1, Icons.wb_sunny, 'Hava'),
                          const SizedBox(width: 4),
                          _buildNavItem(2, Icons.smart_toy, 'Asistan'),
                          const SizedBox(width: 4),
                          _buildNavItem(3, Icons.location_on, 'Destek'),
                          const SizedBox(width: 4),
                          _buildNavItem(4, Icons.store, 'Pazar'),
                          const SizedBox(width: 4),
                          _buildNavItem(5, Icons.person, 'Profil'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 8, 
          vertical: 8
        ),
        decoration: isSelected
            ? BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              )
            : null,
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
