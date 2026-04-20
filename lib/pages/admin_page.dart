import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/book.dart';
import '../services/storage_service.dart';
import '../services/github_service.dart';
import 'dart:io';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _coverUrlController = TextEditingController();
  final _tokenController = TextEditingController();
  
  PlatformFile? _selectedFile;
  bool _isProcessing = false;
  List<Book> _books = [];
  bool _isLoadingBooks = false;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() => _isLoadingBooks = true);
    try {
      final response = await http.get(Uri.parse('https://ChoyonBonik.github.io/Story_flow/books.json'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _books = data.map((b) => Book.fromJson(b)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading books: $e');
    } finally {
      setState(() => _isLoadingBooks = false);
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      setState(() {
        _selectedFile = result.files.first;
      });
    }
  }

  void _publishBook() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a PDF file')));
        return;
      }
      if (_tokenController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter GitHub token')));
        return;
      }

      setState(() => _isProcessing = true);
      try {
        final pdfFileName = _selectedFile!.name;
        final pdfUrl = 'https://ChoyonBonik.github.io/Story_flow/books/$pdfFileName';
        final newBook = Book(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleController.text,
          author: _authorController.text,
          coverUrl: _coverUrlController.text,
          chapters: [],
          pdfUrl: pdfUrl,
        );

        final githubService = GitHubService(token: _tokenController.text);
        await githubService.uploadBook(
          book: newBook,
          pdfBytes: _selectedFile!.bytes ?? await File(_selectedFile!.path!).readAsBytes(),
          pdfFileName: pdfFileName,
        );

        await StorageService.savePublishedBook(newBook);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Published successfully!')));
        _titleController.clear();
        _authorController.clear();
        _coverUrlController.clear();
        setState(() => _selectedFile = null);
        _loadBooks();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _deleteBook(Book book) async {
    if (_tokenController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter GitHub token to delete')));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Book'),
        content: Text('Are you sure you want to delete "${book.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isProcessing = true);
      try {
        final githubService = GitHubService(token: _tokenController.text);
        
        // Try to extract filename from pdfUrl if possible
        String? pdfFileName;
        if (book.pdfUrl != null) {
          pdfFileName = book.pdfUrl!.split('/').last;
        }

        await githubService.deleteBook(book.id, pdfFileName: pdfFileName);
        await StorageService.removePublishedBook(book.id);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted successfully!')));
        _loadBooks();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
          backgroundColor: Colors.brown.shade100,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.publish), text: 'Publish'),
              Tab(icon: Icon(Icons.manage_search), text: 'Manage'),
            ],
          ),
        ),
        body: Stack(
          children: [
            TabBarView(
              children: [
                _buildPublishTab(),
                _buildManageTab(),
              ],
            ),
            if (_isProcessing)
              Container(color: Colors.black26, child: const Center(child: CircularProgressIndicator())),
          ],
        ),
      ),
    );
  }

  Widget _buildPublishTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            TextFormField(
              controller: _tokenController,
              decoration: const InputDecoration(labelText: 'GitHub Token', obscureText: true),
              validator: (value) => value!.isEmpty ? 'Enter token' : null,
            ),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Book Title'),
              validator: (value) => value!.isEmpty ? 'Enter title' : null,
            ),
            TextFormField(
              controller: _authorController,
              decoration: const InputDecoration(labelText: 'Author'),
              validator: (value) => value!.isEmpty ? 'Enter author' : null,
            ),
            TextFormField(
              controller: _coverUrlController,
              decoration: const InputDecoration(labelText: 'Cover Image URL'),
              validator: (value) => value!.isEmpty ? 'Enter cover URL' : null,
            ),
            const SizedBox(height: 20),
            ListTile(
              title: Text(_selectedFile == null ? 'Select PDF' : _selectedFile!.name),
              trailing: const Icon(Icons.picture_as_pdf),
              tileColor: Colors.grey.shade200,
              onTap: _pickFile,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isProcessing ? null : _publishBook,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
              child: const Text('Publish to GitHub', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManageTab() {
    if (_isLoadingBooks) return const Center(child: CircularProgressIndicator());
    
    return RefreshIndicator(
      onRefresh: _loadBooks,
      child: ListView.builder(
        itemCount: _books.length,
        itemBuilder: (context, index) {
          final book = _books[index];
          return ListTile(
            leading: Image.network(book.coverUrl, width: 50, errorBuilder: (_, __, ___) => const Icon(Icons.book)),
            title: Text(book.title),
            subtitle: Text(book.author),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteBook(book),
            ),
          );
        },
      ),
    );
  }
}
