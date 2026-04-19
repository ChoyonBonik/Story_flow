import 'package:flutter/material.dart';
import 'package:story_flow/pages/auth/login_page.dart';
import 'package:story_flow/pages/auth/register_page.dart';
import 'package:story_flow/pages/home_page.dart';
import 'package:story_flow/services/storage_service.dart';
import 'package:story_flow/pages/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool isLoggedIn = await StorageService.isLoggedIn();
  runApp(StoryFlowApp(isLoggedIn: isLoggedIn));
}

class StoryFlowApp extends StatelessWidget {
  final bool isLoggedIn;

  const StoryFlowApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StoryFlow Library',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
      ),
      initialRoute: '/', // Start with SplashPage
      routes: {
        '/': (context) => const SplashPage(), // Splash screen is the entry point
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
      },
      // Determine initial route based on login status after splash
      // This is handled within SplashPage now.
    );
  }
}
