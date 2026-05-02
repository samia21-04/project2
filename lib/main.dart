import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/profile_screen.dart';
import 'screens/home/invite_collaborator_screen.dart';
import 'screens/home/optimizer_result_screen.dart';
import 'models/activity.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
  runApp(const TropicaGuideApp());
}

class TropicaGuideApp extends StatelessWidget {
  const TropicaGuideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TropicaGuide',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0D1F18),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF1D9E75),
          surface: Color(0xFF0D1F18),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF0F2820),
          border: OutlineInputBorder(),
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
              builder: (_) => const SplashScreen(),
            );
          case '/login':
            return MaterialPageRoute(
              builder: (_) => const LoginScreen(),
            );
          case '/signup':
            return MaterialPageRoute(
              builder: (_) => const SignUpScreen(),
            );
          case '/home':
            return MaterialPageRoute(
              builder: (_) => const HomeScreen(),
            );
          case '/profile':
            return MaterialPageRoute(
              builder: (_) => const ProfileScreen(),
            );
          case '/invite':
            final tripId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (_) =>
                  InviteCollaboratorScreen(tripId: tripId),
            );
          case '/optimizer':
            final args =
                settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => OptimizerResultScreen(
                tripId:   args['tripId'] as String,
                sorted:   args['activities'] as List<Activity>,
                original: args['original'] as List<Activity>,
              ),
            );
          default:
            // Fallback — unknown route goes back to splash
            return MaterialPageRoute(
              builder: (_) => const SplashScreen(),
            );
        }
      },
    );
  }
}