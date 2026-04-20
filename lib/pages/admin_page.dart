import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
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
  final _tokenController = TextEditingController(); // Added token controller
  
  PlatformFile? _selectedFile;
  bool _isPublishing = false;

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a PDF file')),
        );
        return;
      }
      
      if (_tokenController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your GitHub token')),
        );
        return;
      }

      setState(() => _isPublishing = true);

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Book published to GitHub successfully!')),
        );

        _titleController.clear();
        _authorController.clear();
        _coverUrlController.clear();
        setState(() {
          _selectedFile = null;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error publishing: $e')),
          );
        }
      } finally {
        setState(() => _isPublishing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - Publish PDF Book'),
        backgroundColor: Colors.brown.shade100,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    controller: _tokenController,
                    decoration: const InputDecoration(labelText: 'GitHub Personal Access Token', hintText: 'ghp_...'),
                    obscureText: true,
                    validator: (value) => value!.isEmpty ? 'Please enter token' : null,
                  ),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Book Title'),
                    validator: (value) => value!.isEmpty ? 'Please enter a title' : null,
                  ),
                  TextFormField(
                    controller: _authorController,
                    decoration: const InputDecoration(labelText: 'Author'),
                    validator: (value) => value!.isEmpty ? 'Please enter an author' : null,
                  ),
                  TextFormField(
                    controller: _coverUrlController,
                    decoration: const InputDecoration(labelText: 'Cover Image URL'),
                    validator: (value) => value!.isEmpty ? 'Please enter a cover URL' : null,
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
                    onPressed: _isPublishing ? null : _publishBook,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
                    child: _isPublishing 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Publish to GitHub', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
          if (_isPublishing)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
