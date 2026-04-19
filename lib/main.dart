import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

void main() {
  runApp(const StoryFlowApp());
}

class StoryFlowApp extends StatelessWidget {
  const StoryFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StoryFlow',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class Chapter {
  final String title;
  final String fileName;

  Chapter({required this.title, required this.fileName});

  String get url =>
      'https://raw.githubusercontent.com/ChoyonBonik/StoryFlow/main/${Uri.encodeComponent(fileName)}';
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Chapter> chapters = [
    Chapter(title: '১-২. হাসপাতাল এসে পৌঁছলাম', fileName: '১-২_হাসপাতাল_এসে_পৌঁছলাম.pdf'),
    Chapter(title: '৩-৪. ঘুম ভাঙলো দেরিতে', fileName: '৩-৪_ঘুম_ভাঙলো_দেরিতে.pdf'),
    Chapter(title: '৫-৬. হাসপাতাল থেকে', fileName: '৫-৬_হাসপাতাল_থেকে.pdf'),
    Chapter(title: '৭-৮. তারপরদিন সকালবেলা', fileName: '৭-৮_তারপরদিন_সকালবেলা.pdf'),
    Chapter(title: '৯-১০. আগস্ট মাসের চৌদ্দ তারিখ', fileName: '৯-১০_আগস্ট_মাসের_চৌদ্দ_তারিখ.pdf'),
    Chapter(title: '১১-১২. অনিমেষবাবুর অনুবাদের কাজ', fileName: '১১-১২_অনিমেষবাবুর_অনুবাদের_কাজ.pdf'),
    Chapter(title: '১৩-১৪. হতবিহ্বল হয়ে পড়েছিলাম', fileName: '১৩-১৪_হতবিহ্বল_হয়ে_পড়েছিলাম.pdf'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('অলাতচক্র - আহমদ ছফা'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView.builder(
        itemCount: chapters.length,
        padding: const EdgeInsets.all(12),
        itemBuilder: (context, index) {
          final chapter = chapters[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                child: Text('${index + 1}'),
              ),
              title: Text(
                chapter.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PDFViewerPage(chapter: chapter),
                  ),
                );
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
      appBar: AppBar(
        title: Text(chapter.title),
      ),
      body: SfPdfViewer.network(
        chapter.url,
        onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load PDF: ${details.description}')),
          );
        },
      ),
    );
  }
}
