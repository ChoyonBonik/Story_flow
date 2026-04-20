import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../models/book.dart';
import '../services/storage_service.dart';
import '../widgets/book_card.dart';
import '../widgets/search_bar_widget.dart';
import 'chapter_list_page.dart';
import 'admin_page.dart';

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
    _loadAllBooks();
    _refreshData();
  }

  Future<void> _loadAllBooks() async {
    setState(() => isLoading = true);

    List<Book> remoteBooks = [];
    List<Book> localBooks = [];

    // Fetch remote books
    const url = 'https://ChoyonBonik.github.io/Story_flow/books.json';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        remoteBooks = data.map((b) => Book.fromJson(b)).toList();
      }
    } catch (e) {
      debugPrint('Error loading remote library: $e');
    }

    // Fetch local books
    try {
      localBooks = await StorageService.getPublishedBooks();
    } catch (e) {
      debugPrint('Error loading local library: $e');
    }

    setState(() {
      library = [...remoteBooks, ...localBooks];
      filteredBooks = library;
      isLoading = false;
    });
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
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 50, color: Colors.brown),
                  ),
                  const SizedBox(height: 05),
                  const Text('Choyon', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const Text('choyon.com', style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Library'),
              onTap: () {
                Navigator.pop(context);
                _loadAllBooks();
              },
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Admin Panel'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminPage())).then((_) => _loadAllBooks());
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
                childAspectRatio: 0.6,
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

    if (book.pdfUrl != null && book.pdfUrl!.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FullBookPDFViewer(book: book)
        )
      ).then((_) => _refreshData());
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ChapterListPage(book: book))
      ).then((_) => _refreshData());
    }
  }
}

class FullBookPDFViewer extends StatelessWidget {
  final Book book;
  const FullBookPDFViewer({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(book.title)),
      body: SfPdfViewer.network(
        book.pdfUrl!,
        onDocumentLoadFailed: (details) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load: ${details.description}')),
        ),
      ),
    );
  }
}
