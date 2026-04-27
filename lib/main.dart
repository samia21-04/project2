import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
// import 'screens/home/home_screen.dart'; // add when built

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF1D9E75),
          surface: const Color(0xFF0D1F18),
        ),
        fontFamily: 'DMSans', // add to pubspec if needed
      ),
      initialRoute: '/',
      routes: {
        '/':       (ctx) => const SplashScreen(),
        '/login':  (ctx) => const LoginScreen(),
        '/signup': (ctx) => const SignUpScreen(),
        // '/home': (ctx) => const HomeScreen(),
      },
    );
  }
}