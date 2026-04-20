import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book.dart';

class GitHubService {
  final String owner = 'ChoyonBonik';
  final String repo = 'Story_flow';
  
  // NEVER hardcode secrets. In a real app, this should be provided by the user 
  // or a secure backend. For now, we expect it to be passed or stored locally.
  final String? token;

  GitHubService({this.token});

  Future<void> uploadBook({
    required Book book,
    required List<int> pdfBytes,
    required String pdfFileName,
  }) async {
    if (token == null || token!.isEmpty) {
      throw Exception('GitHub token is missing');
    }

    final pdfPath = 'docs/books/$pdfFileName';
    final jsonPath = 'docs/books.json';

    // 1. Upload PDF
    await _uploadFile(
      path: pdfPath,
      content: base64Encode(pdfBytes),
      message: 'Upload PDF: ${book.title}',
    );

    // 2. Update books.json
    final booksJsonData = await _getFile(jsonPath);
    final String currentJsonString = utf8.decode(base64Decode(booksJsonData['content'].replaceAll('\n', '')));
    final List<dynamic> currentBooks = json.decode(currentJsonString);
    
    // Create new book entry for JSON
    final newEntry = book.toJson();
    newEntry['pdfUrl'] = 'https://ChoyonBonik.github.io/Story_flow/books/$pdfFileName';
    currentBooks.add(newEntry);

    await _uploadFile(
      path: jsonPath,
      content: base64Encode(utf8.encode(json.encode(currentBooks))),
      sha: booksJsonData['sha'],
      message: 'Update books.json: Add ${book.title}',
    );
  }

  Future<Map<String, dynamic>> _getFile(String path) async {
    final url = Uri.parse('https://api.github.com/repos/$owner/$repo/contents/$path');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'token $token',
        'Accept': 'application/vnd.github.v3+json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get file: ${response.body}');
    }
  }

  Future<void> _uploadFile({
    required String path,
    required String content,
    required String message,
    String? sha,
  }) async {
    final url = Uri.parse('https://api.github.com/repos/$owner/$repo/contents/$path');
    final body = {
      'message': message,
      'content': content,
    };
    if (sha != null) {
      body['sha'] = sha;
    }

    final response = await http.put(
      url,
      headers: {
        'Authorization': 'token $token',
        'Accept': 'application/vnd.github.v3+json',
      },
      body: json.encode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to upload file: ${response.body}');
    }
  }
}
