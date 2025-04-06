import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:neuroassist/services/notification_service.dart'; 
import 'package:neuroassist/services/chatbot_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Add try-catch for Firebase initialization
  try {
    // Initialize Firebase with platform-specific options
    await Firebase.initializeApp();
    
    // Initialize services safely
    try {
      final notificationService = NotificationService();
      await notificationService.initialize();
      await notificationService.requestPermissions();
    } catch (e) {
      print('Notification service initialization failed: $e');
      // Continue without notification service
    }
    
    // Initialize chatbot service (pre-warm the service)
    try {
      ChatbotService();
    } catch (e) {
      print('ChatbotService initialization failed: $e');
      // Continue without pre-warming
    }
  } catch (e) {
    print('Firebase initialization failed: $e');
    // You can show an error dialog here if needed
  }

  // Set system UI overlay style
  // SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
  //   statusBarColor: Colors.transparent,
  //   statusBarIconBrightness: Brightness.light,
  //   systemNavigationBarColor: Colors.black,
  //   systemNavigationBarIconBrightness: Brightness.light,
  // ));

  // Run app regardless of initialization status
  runApp(const MyApp());
}