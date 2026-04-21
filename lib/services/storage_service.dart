import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // For JSON encoding/decoding
import '../models/book.dart';

class StorageService {
  static const String _recentKey = 'recently_read';
  static const String _favKey = 'favorites';
  static const String _loggedInKey = 'is_logged_in'; 
  static const String _publishedBooksKey = 'published_books';
  static const String _userCredentialsKey = 'user_credentials';

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

  static Future<void> savePublishedBook(Book book) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> books = prefs.getStringList(_publishedBooksKey) ?? [];
    books.add(json.encode(book.toJson()));
    await prefs.setStringList(_publishedBooksKey, books);
  }

  static Future<List<Book>> getPublishedBooks() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> booksJson = prefs.getStringList(_publishedBooksKey) ?? [];
    return booksJson.map((b) => Book.fromJson(json.decode(b))).toList();
  }

  static Future<void> removePublishedBook(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> booksJson = prefs.getStringList(_publishedBooksKey) ?? [];
    List<Book> books = booksJson.map((b) => Book.fromJson(json.decode(b))).toList();
    books.removeWhere((b) => b.id == bookId);
    await prefs.setStringList(_publishedBooksKey, books.map((b) => json.encode(b.toJson())).toList());
  }

  static Future<void> setLoggedIn(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, isLoggedIn);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_loggedInKey) ?? false;
  }

  static Future<bool> registerUser(String phone, String password) async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> credentials = json.decode(prefs.getString(_userCredentialsKey) ?? '{}');
    if (credentials.containsKey(phone)) return false;
    credentials[phone] = password;
    await prefs.setString(_userCredentialsKey, json.encode(credentials));
    return true;
  }

  static Future<void> saveHighlight(String bookId, Map<String, dynamic> highlight) async {
    final prefs = await SharedPreferences.getInstance();
    String key = 'highlights_$bookId';
    List<String> highlights = prefs.getStringList(key) ?? [];
    highlights.add(json.encode(highlight));
    await prefs.setStringList(key, highlights);
  }

  static Future<List<Map<String, dynamic>>> getHighlights(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    String key = 'highlights_$bookId';
    List<String> highlightsJson = prefs.getStringList(key) ?? [];
    return highlightsJson.map((h) => json.decode(h) as Map<String, dynamic>).toList();
  }

  static Future<void> clearHighlights(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('highlights_$bookId');
  }

  static Future<bool> verifyLogin(String phone, String password) async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> credentials = json.decode(prefs.getString(_userCredentialsKey) ?? '{}');
    if (credentials.containsKey(phone)) {
      return credentials[phone] == password;
    }
    return false;
  }
}
