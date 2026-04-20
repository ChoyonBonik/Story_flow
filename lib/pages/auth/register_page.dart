import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../services/storage_service.dart';
import 'login_page.dart';


class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        setState(() { _errorMessage = 'Passwords do not match.'; });
        if (mounted) { // Ensure context is available
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_errorMessage),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }
      setState(() { _isLoading = true; _errorMessage = ''; });

      await Future.delayed(const Duration(seconds: 2)); // Simulate network delay

      final bool registrationSuccess = await StorageService.registerUser(_phoneController.text, _passwordController.text);

      if (registrationSuccess) {
        await StorageService.setLoggedIn(true); // Log in the user immediately after registration
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        setState(() { _errorMessage = 'Phone number already registered. Please login.'; });
        if (mounted) { // Ensure context is available
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_errorMessage),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register', style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true, backgroundColor: Colors.brown.shade100),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Lottie.network(
                  'https://assets5.lottiefiles.com/packages/lf20_vvq86bvj.json', // User creation/secure access animation
                  width: 150, height: 150, fit: BoxFit.contain, repeat: true,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.person_add_alt_1, size: 80, color: Colors.brown),
                ),
                const SizedBox(height: 20),
                const Text('Create Account', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text('Enter your phone number and password to register.', style: TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true, fillColor: Colors.grey.shade100
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your phone number';
                    if (value.length != 10) return 'Phone number must be 10 digits';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true, fillColor: Colors.grey.shade100
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your password';
                    if (value.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_reset),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true, fillColor: Colors.grey.shade100
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please confirm your password';
                    if (value != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _register,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: Colors.brown,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Register', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage())),
                  child: const Text('Already have an account? Login'),
                ),
                // The Text widget for error display is removed as Snackbar is used.
              ],
            ),
          ),
        ),
      ),
    );
  }
}
