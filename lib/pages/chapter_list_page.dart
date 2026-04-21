import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../models/book.dart';
import '../services/storage_service.dart';

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

class PDFViewerPage extends StatefulWidget {
  final Chapter chapter;
  const PDFViewerPage({super.key, required this.chapter});

  @override
  State<PDFViewerPage> createState() => _PDFViewerPageState();
}

class _PDFViewerPageState extends State<PDFViewerPage> {
  late PdfViewerController _pdfViewerController;
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  List<Map<String, dynamic>> _highlights = [];

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
    _loadHighlights();
  }

  Future<void> _loadHighlights() async {
    final highlights = await StorageService.getHighlights(widget.chapter.title);
    setState(() {
      _highlights = highlights;
    });
  }

  void _addHighlight(PdfTextSelectionChangedDetails details, Color color) async {
    if (details.selectedText != null) {
      final highlight = {
        'text': details.selectedText,
        'pageNumber': _pdfViewerController.pageNumber,
        'color': color.value,
        'date': DateTime.now().toIso8601String(),
      };
      await StorageService.saveHighlight(widget.chapter.title, highlight);
      _loadHighlights();
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
                _colorOption(Colors.yellow, details, () => overlayEntry.remove()),
                _colorOption(Colors.greenAccent, details, () => overlayEntry.remove()),
                _colorOption(Colors.pinkAccent, details, () => overlayEntry.remove()),
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

  Widget _colorOption(Color color, PdfTextSelectionChangedDetails details, VoidCallback onSelected) {
    return GestureDetector(
      onTap: () {
        _addHighlight(details, color);
        onSelected();
      },
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: CircleAvatar(
          backgroundColor: color,
          radius: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chapter.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            onPressed: _showHighlightsSummary,
          ),
        ],
      ),
      body: SfPdfViewer.network(
        widget.chapter.url,
        key: _pdfViewerKey,
        controller: _pdfViewerController,
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

  void _showHighlightsSummary() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Highlights', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Expanded(
                child: _highlights.isEmpty
                    ? const Center(child: Text('No highlights yet'))
                    : ListView.builder(
                        itemCount: _highlights.length,
                        itemBuilder: (context, index) {
                          final h = _highlights[index];
                          return ListTile(
                            leading: CircleAvatar(backgroundColor: Color(h['color']), radius: 10),
                            title: Text(h['text'], maxLines: 2, overflow: TextOverflow.ellipsis),
                            subtitle: Text('Page ${h['pageNumber']}'),
                            onTap: () {
                              _pdfViewerController.jumpToPage(h['pageNumber']);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
