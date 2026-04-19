import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/storage_service.dart';
import '../pages/chapter_list_page.dart'; // Corrected import path

class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onBookOpen;

  const BookCard({
    super.key,
    required this.book,
    this.onFavoriteToggle,
    this.onBookOpen,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onBookOpen ?? () => _openBook(context),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.network(
                      book.coverUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: Colors.brown.shade200, child: const Icon(Icons.book, size: 50)),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(book.title, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(book.author, style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 5, right: 5,
              child: CircleAvatar(
                backgroundColor: Colors.white70,
                child: FutureBuilder<List<String>>(
                  future: StorageService.getFavorites(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                      final isFav = snapshot.data!.contains(book.id);
                      return IconButton(
                        icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: Colors.red, size: 20),
                        onPressed: () {
                          StorageService.toggleFavorite(book.id).then((_) {
                            if (onFavoriteToggle != null) onFavoriteToggle!();
                          });
                        },
                      );
                    }
                    return const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2));
                  },
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _openBook(BuildContext context) {
    StorageService.saveRecent(book.id);
    Navigator.push(context, MaterialPageRoute(builder: (context) => ChapterListPage(book: book))).then((_) {
      if (onFavoriteToggle != null) onFavoriteToggle!(); // Refresh to update favorite status UI if needed
    });
  }
}
