import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
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

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
  }

  void _onDocumentLoaded(PdfDocumentLoadedDetails details) async {
    final highlights = await StorageService.getHighlights(widget.chapter.title);
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
            // result.nextInstance();
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
        await StorageService.saveHighlight(widget.chapter.title, highlight);
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
        title: Text(widget.chapter.title),
      ),
      body: SfPdfViewer.network(
        widget.chapter.url,
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
