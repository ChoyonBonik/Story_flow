import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book.dart';
import '../services/storage_service.dart';
import '../widgets/book_card.dart';
import '../widgets/search_bar_widget.dart';
import 'chapter_list_page.dart';
import 'auth/login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Book> library = [];
  List<Book> filteredBooks = [];
  List<String> favoriteIds = [];
  bool showOnlyFavorites = false;
  bool isLoading = true;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchLibrary();
    _refreshData();
  }

  Future<void> _fetchLibrary() async {
    const url = 'https://ChoyonBonik.github.io/StoryFlow/books.json';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          library = data.map((b) => Book.fromJson(b)).toList();
          filteredBooks = library;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load library');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading library: $e')),
        );
      }
    }
  }

  void _refreshData() async {
    final favs = await StorageService.getFavorites();
    setState(() {
      favoriteIds = favs;
    });
  }

  void _filterBooks(String query) {
    setState(() {
      filteredBooks = library.where((book) {
        final matchesQuery = book.title.toLowerCase().contains(query.toLowerCase()) || 
                             book.author.toLowerCase().contains(query.toLowerCase());
        final matchesFav = !showOnlyFavorites || favoriteIds.contains(book.id);
        return matchesQuery && matchesFav;
      }).toList();
    });
  }
  
  void _toggleFavorites() {
    setState(() {
      showOnlyFavorites = !showOnlyFavorites;
    });
    _filterBooks(searchController.text);
  }

  void _logout() async {
    await StorageService.setLoggedIn(false);
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StoryFlow Library', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.brown.shade100,
        actions: [
          IconButton(
            icon: Icon(showOnlyFavorites ? Icons.favorite : Icons.favorite_border, color: Colors.red),
            onPressed: _toggleFavorites,
          )
        ],
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration( color: Colors.brown),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 40,
                    // Ensure this asset exists: assets/images/profile_placeholder.png
                    // backgroundImage: AssetImage('assets/images/profile_placeholder.png'), 
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 05),
                  const Text('User Name', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const Text('user@example.com', style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Library'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile section coming soon!')),
                );
              },
            ),
             ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings section coming soon!')),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : CustomScrollView(
            slivers: [
          SliverToBoxAdapter(
            child: SearchBarWidget(
              controller: searchController,
              onChanged: _filterBooks,
              onFavoritePressed: _toggleFavorites,
              isFavoriteActive: showOnlyFavorites,
            ),
          ),
          
          SliverToBoxAdapter(child: _buildSectionTitle(showOnlyFavorites ? 'Your Favorites' : 'All Books')),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, 
                childAspectRatio: 0.6, // Adjusted for better fit
                crossAxisSpacing: 16, 
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => BookCard(
                  book: filteredBooks[index],
                  onBookOpen: () => _openBook(filteredBooks[index]),
                  onFavoriteToggle: _refreshData, 
                ),
                childCount: filteredBooks.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }
  
  void _openBook(Book book) async {
    await StorageService.saveRecent(book.id);
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (context) => ChapterListPage(book: book))).then((_) => _refreshData());
  }
}
