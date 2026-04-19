import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // For JSON encoding/decoding

class StorageService {
  static const String _recentKey = 'recently_read';
  static const String _favKey = 'favorites';
  static const String _loggedInKey = 'is_logged_in'; // Key for login status

  // --- Authentication Keys ---
  static const String _userCredentialsKey = 'user_credentials'; // Stores a map of phone -> password

  // --- Recent and Favorites (Keep for now) ---
  static Future<void> saveRecent(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_recentKey, bookId);
  }

  static Future<String?> getRecent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_recentKey);
  }

  static Future<void> toggleFavorite(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favs = prefs.getStringList(_favKey) ?? [];
    if (favs.contains(bookId)) {
      favs.remove(bookId);
    } else {
      favs.add(bookId);
    }
    await prefs.setStringList(_favKey, favs);
  }

  static Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_favKey) ?? [];
  }

  // --- Authentication Methods ---
  static Future<void> setLoggedIn(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, isLoggedIn);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_loggedInKey) ?? false;
  }

  // Store credentials (phone number as key, password as value)
  // WARNING: Storing passwords in plain text is insecure. Use hashing in production.
  static Future<bool> registerUser(String phone, String password) async {
    final prefs = await SharedPreferences.getInstance();
    // Retrieve existing credentials map or create a new one
    Map<String, dynamic> credentials = json.decode(prefs.getString(_userCredentialsKey) ?? '{}');

    if (credentials.containsKey(phone)) {
      return false; // Phone number already registered
    }

    // In a real app, hash the password here
    credentials[phone] = password;
    await prefs.setString(_userCredentialsKey, json.encode(credentials));
    return true; // Registration successful
  }

  // Verify login credentials
  static Future<bool> verifyLogin(String phone, String password) async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> credentials = json.decode(prefs.getString(_userCredentialsKey) ?? '{}');

    if (credentials.containsKey(phone)) {
      // In a real app, compare a hashed version of the entered password with the stored hash
      return credentials[phone] == password;
    }
    return false; // Phone number not found
  }
}
