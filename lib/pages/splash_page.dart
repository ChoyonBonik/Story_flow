import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../services/storage_service.dart'; // Import StorageService
import 'home_page.dart'; // To navigate to HomePage
import 'package:story_flow/pages/auth/login_page.dart'; // To navigate to LoginPage

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    // Navigation is handled in onLoaded callback after animation plays.
  }

  Future<void> _navigateToNextScreen() async {
    final isLoggedIn = await StorageService.isLoggedIn();
    if (mounted) {
      if (isLoggedIn) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const HomePage()));
      } else {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const LoginPage()));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.network(
              // Reverted to the original Lottie URL as requested
              'https://assets9.lottiefiles.com/packages/lf20_1a8dx7zj.json', // Book reading animation
              controller: _controller,
              onLoaded: (composition) {
                // Configure the animation.
                _controller
                  ..duration = composition.duration
                  ..forward().whenComplete(() {
                    // Navigate after the animation is complete
                    _navigateToNextScreen();
                  });
              },
              width: 300,
              height: 300,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Fallback icon if Lottie fails to load
                return const Icon(Icons.book_online_outlined, size: 100, color: Colors.deepPurple);
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'StoryFlow',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
