import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui';
// import 'package:flutter_dotenv/flutter_dotenv.dart'; // Removed for Edge Function security
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'config/supabase_config.dart';
import 'services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart'; // Firebase Core
import 'services/fcm_service.dart'; // Import FCM Service
import 'screens/chat_screen.dart'; // Import chat screen
import 'utils/page_transitions.dart'; // Import page transitions

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Global error handler - uygulama crash olmasını önle
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    print('Flutter Error: ${details.exception}');
    print('Stack trace: ${details.stack}');
  };

  // Platform error handler
  PlatformDispatcher.instance.onError = (error, stack) {
    print('Platform Error: $error');
    print('Stack trace: $stack');
    return true;
  };

  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase ve Supabase'i PARALEL başlat (sıralı değil - 2-3 sn kazanç)
  await Future.wait([
    // Firebase başlatma
    () async {
      try {
        await Firebase.initializeApp();
      } catch (e) {
        if (kDebugMode) print('Warning: Firebase init failed: $e');
      }
    }(),
    // Supabase başlatma
    () async {
      try {
        await Supabase.initialize(
          url: SupabaseConfig.supabaseUrl,
          anonKey: SupabaseConfig.supabaseAnonKey,
        );
      } catch (e) {
        if (kDebugMode) print('Warning: Supabase init failed: $e');
      }
    }(),
  ]);
 
  // Bildirim + FCM PARALEL başlat
  try {
    await Future.wait([
      NotificationService.initialize(
        onNotificationTap: (payload) {
          if (payload != null && payload.startsWith('chat|')) {
            final parts = payload.split('|');
            if (parts.length >= 5) {
              navigatorKey.currentState?.push(
                PageTransitions.modernSlideTransition(
                  page: ChatScreen(
                    listingId: parts[1],
                    otherUserId: parts[2],
                    otherUserName: parts[3],
                    listingTitle: parts[4],
                  ),
                ),
              );
            }
          }
        },
      ),
      FCMService.initialize(),
    ]);
  } catch (e) {
    if (kDebugMode) print('Warning: Notification init failed: $e');
  }
  
  runApp(const FlexTarmApp());
}

class FlexTarmApp extends StatelessWidget {
  const FlexTarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // Global navigation key
      title: 'Flex Farm',
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/splash_bg.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                // İsteğe bağlı, yazının daha iyi okunması için hafif karartma
                color: Colors.black.withValues(alpha: 0.3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 100), // Logonun eskiden olduğu boşluk
                    // App Name
                    const Text(
                      'FLEX FARM',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2.0,
                        shadows: [
                          Shadow(
                            blurRadius: 10.0,
                            color: Colors.black45,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Tar\u0131m Yapay Zeka Asistan\u0131',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(
                            blurRadius: 8.0,
                            color: Colors.black45,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 60),
                    // Loading indicator
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Check if user is authenticated
        final session = snapshot.hasData ? snapshot.data!.session : null;
        
        if (session != null) {
          // User is logged in, go to home screen
          // Hasat hatırlatıcılarını zamanla (arka planda)
          NotificationService.scheduleAllHarvestReminders();
          NotificationService.scheduleAllCustomReminders();
          return const HomeScreen();
        } else {
          // User is not logged in, go to login screen
          return const LoginScreen();
        }
      },
    );
  }
}
