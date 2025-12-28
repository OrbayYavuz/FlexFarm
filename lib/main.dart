import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  
  // Environment variables'ı yükle (varsa)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('Warning: .env file not found or corrupted, using default values');
  }

  // Firebase'i başlat
  try {
    await Firebase.initializeApp();
    print('Firebase initialized successfully');
  } catch (e) {
    print('Warning: Firebase initialization failed: $e');
  }
  
  // Supabase'i başlat
  try {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
    // print('Supabase initialized successfully');
  } catch (e) {
    // print('ERROR: Supabase initialization failed: $e');
    // Uygulama çalışmaya devam edecek
  }
 
  // Bildirim servisini başlat
  try {
    await NotificationService.initialize(
      onNotificationTap: (payload) {
        if (payload != null && payload.startsWith('chat|')) {
          final parts = payload.split('|');
          if (parts.length >= 5) {
            final listingId = parts[1];
            final otherUserId = parts[2];
            final otherUserName = parts[3];
            final listingTitle = parts[4];
            
            navigatorKey.currentState?.push(
              PageTransitions.modernSlideTransition(
                page: ChatScreen(
                  listingId: listingId,
                  otherUserId: otherUserId,
                  otherUserName: otherUserName,
                  listingTitle: listingTitle,
                ),
              ),
            );
          }
        }
      },
    );
    
    // FCM (Firebase Cloud Messaging) Başlat
    await FCMService.initialize();
    
  } catch (e) {
    print('Warning: Notification service initialization failed: $e');
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
        // Loading state - Splash Screen
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo - Bigger size
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(125),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/splash_logo.png',
                      fit: BoxFit.contain,
                      width: 250,
                      height: 250,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.agriculture,
                          size: 100,
                          color: Colors.green[700],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  // App Name
                  Text(
                    'FLEX FARM',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Tarım Yapay Zeka Asistanı',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Loading indicator
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green[700]!),
                    strokeWidth: 3,
                  ),
                ],
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
