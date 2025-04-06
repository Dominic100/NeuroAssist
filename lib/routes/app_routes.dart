import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/registration_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/TTS_STT/tts_stt.dart';
import '../screens/Pomodoro/habit.dart';
import '../screens/Leaderboard/leaderboard_screen.dart';
import '../screens/NeurodiversityQuiz/neurodiversity_quiz.dart';
import 'route_names.dart';

class AppRoutes {
  static final Map<String, WidgetBuilder> routes = {
    RouteNames.login: (context) => const LoginScreen(),
    RouteNames.register: (context) => const RegistrationScreen(),
    RouteNames.home: (context) => const HomeScreen(),
    RouteNames.profile: (context) => const ProfileScreen(),
    RouteNames.settings: (context) => const SettingsScreen(),
    RouteNames.ttsStt: (context) => TTSSTTHome(),
    RouteNames.habit: (context) => const Habit(),
    RouteNames.leaderboard: (context) => const LeaderboardScreen(),
    RouteNames.quiz: (context) => const NeurodiversityQuizScreen(),
  };
}
