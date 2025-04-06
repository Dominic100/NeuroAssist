import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:neuroassist/services/notification_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermissions();

  runApp(const MyApp());
}