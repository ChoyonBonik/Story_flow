import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../models/book.dart';

class ChapterListPage extends StatelessWidget {
  final Book book;
  const ChapterListPage({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(book.title)),
      body: ListView.builder(
        itemCount: book.chapters.length,
        padding: const EdgeInsets.all(12),
        itemBuilder: (context, index) {
          final chapter = book.chapters[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(child: Text('${index + 1}')),
              title: Text(chapter.title, style: const TextStyle(fontWeight: FontWeight.w500)),
              trailing: const Icon(Icons.chrome_reader_mode_outlined),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => PDFViewerPage(chapter: chapter)));
              },
            ),
          );
        },
      ),
    );
  }
}

class PDFViewerPage extends StatelessWidget {
  final Chapter chapter;
  const PDFViewerPage({super.key, required this.chapter});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(chapter.title)),
      body: SfPdfViewer.network(
        chapter.url,
        onDocumentLoadFailed: (details) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load: ${details.description}')),
        ),
      ),
    );
  }
}
