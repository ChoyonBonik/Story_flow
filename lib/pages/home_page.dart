import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdf/pdf.dart';
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

  void _clearAllHighlights() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Highlights'),
        content: const Text('Are you sure you want to remove all highlights from all books?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await StorageService.clearAllHighlights();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All highlights cleared')));
    }
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
              leading: const Icon(Icons.history),
              title: const Text('Clear All Highlights'),
              onTap: () {
                Navigator.pop(context);
                _clearAllHighlights();
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

class FullBookPDFViewer extends StatefulWidget {
  final Book book;
  const FullBookPDFViewer({super.key, required this.book});

  @override
  State<FullBookPDFViewer> createState() => _FullBookPDFViewerState();
}

class _FullBookPDFViewerState extends State<FullBookPDFViewer> {
  late PdfViewerController _pdfViewerController;
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  
  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
  }

  void _onDocumentLoaded(PdfDocumentLoadedDetails details) async {
    final highlights = await StorageService.getHighlights(widget.book.id);
    for (var h in highlights) {
      if (h.containsKey('lines')) {
        final List<dynamic> linesData = h['lines'];
        final List<PdfTextLine> lines = linesData.map((ld) {
          return PdfTextLine(
            Rect.fromLTWH(
              (ld['left'] as num).toDouble(),
              (ld['top'] as num).toDouble(),
              (ld['width'] as num).toDouble(),
              (ld['height'] as num).toDouble(),
            ),
            ld['text'] as String? ?? '',
            ld['pageNumber'] as int? ?? 1,
          );
        }).toList();

        _pdfViewerController.addAnnotation(HighlightAnnotation(
          textBoundsCollection: lines,
        ));
      } else {
        // Fallback for old highlights using search
        final String textToSearch = h['text'];
        final PdfTextSearchResult result = await _pdfViewerController.searchText(
          textToSearch,
          searchOption: TextSearchOption.caseSensitive,
        );
        
        if (result.hasResult) {
          while (result.hasResult) {
            // Note: This part was already problematic as getSelectedTextLines() 
            // doesn't work with search results, but keeping fallback structure.
            result.nextInstance();
          }
        }
      }
    }
  }

  void _addHighlight(PdfTextSelectionChangedDetails details, Color color) async {
    if (details.selectedText != null) {
      String cleanedText = details.selectedText!.replaceAll('\r', '').replaceAll('\n', ' ').trim();
      
      final List<PdfTextLine>? lines = _pdfViewerKey.currentState?.getSelectedTextLines();
      if (lines != null && lines.isNotEmpty) {
        _pdfViewerController.addAnnotation(HighlightAnnotation(
          textBoundsCollection: lines,
        ));

        final List<Map<String, dynamic>> serializedLines = lines.map((line) => {
          'left': line.bounds.left,
          'top': line.bounds.top,
          'width': line.bounds.width,
          'height': line.bounds.height,
          'text': line.text,
          'pageNumber': line.pageNumber,
        }).toList();

        final highlight = {
          'text': cleanedText,
          'pageNumber': _pdfViewerController.pageNumber,
          'lines': serializedLines,
          'date': DateTime.now().toIso8601String(),
        };
        await StorageService.saveHighlight(widget.book.id, highlight);
      }
      _pdfViewerController.clearSelection();
    }
  }

  void _showHighlightOptions(PdfTextSelectionChangedDetails details) {
    if (details.selectedText == null) return;

    final OverlayState overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: details.globalSelectedRegion!.top - 60,
        left: details.globalSelectedRegion!.left,
        child: Material(
          elevation: 4.0,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.border_color, color: Colors.orangeAccent, size: 22),
                  onPressed: () {
                    _addHighlight(details, Colors.yellow.withOpacity(0.5));
                    overlayEntry.remove();
                  },
                ),
                const VerticalDivider(width: 1, thickness: 1, indent: 5, endIndent: 5),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () {
                    _pdfViewerController.clearSelection();
                    overlayEntry.remove();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlayState.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 5), () {
      if (overlayEntry.mounted) overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.title),
      ),
      body: SfPdfViewer.network(
        widget.book.pdfUrl!,
        key: _pdfViewerKey,
        controller: _pdfViewerController,
        onDocumentLoaded: _onDocumentLoaded,
        onTextSelectionChanged: (PdfTextSelectionChangedDetails details) {
          if (details.selectedText != null) {
            _showHighlightOptions(details);
          }
        },
        onDocumentLoadFailed: (details) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load: ${details.description}')),
        ),
      ),
    );
  }
}
