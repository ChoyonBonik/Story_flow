import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book.dart';

class GitHubService {
  final String owner = 'ChoyonBonik';
  final String repo = 'Story_flow';
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

    await _uploadFile(
      path: pdfPath,
      content: base64Encode(pdfBytes),
      message: 'Upload PDF: ${book.title}',
    );

    final booksJsonData = await _getFile(jsonPath);
    final String currentJsonString = utf8.decode(base64Decode(booksJsonData['content'].replaceAll('\n', '')));
    final List<dynamic> currentBooks = json.decode(currentJsonString);
    
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

  Future<void> deleteBook(String bookId, {String? pdfFileName}) async {
    if (token == null || token!.isEmpty) {
      throw Exception('GitHub token is missing');
    }

    final jsonPath = 'docs/books.json';

    // 1. Update books.json
    final booksJsonData = await _getFile(jsonPath);
    final String currentJsonString = utf8.decode(base64Decode(booksJsonData['content'].replaceAll('\n', '')));
    List<dynamic> currentBooks = json.decode(currentJsonString);
    
    currentBooks.removeWhere((book) => book['id'] == bookId);

    await _uploadFile(
      path: jsonPath,
      content: base64Encode(utf8.encode(json.encode(currentBooks))),
      sha: booksJsonData['sha'],
      message: 'Update books.json: Delete book $bookId',
    );

    // 2. Optionally delete PDF file if fileName is provided
    if (pdfFileName != null && pdfFileName.isNotEmpty) {
      try {
        final pdfPath = 'docs/books/$pdfFileName';
        final pdfFileData = await _getFile(pdfPath);
        await _deleteFile(
          path: pdfPath,
          sha: pdfFileData['sha'],
          message: 'Delete PDF: $pdfFileName',
        );
      } catch (e) {
        // Log error but don't fail if PDF is already gone
        print('Could not delete PDF file: $e');
      }
    }
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

  Future<void> _deleteFile({
    required String path,
    required String sha,
    required String message,
  }) async {
    final url = Uri.parse('https://api.github.com/repos/$owner/$repo/contents/$path');
    final body = {
      'message': message,
      'sha': sha,
    };

    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'token $token',
        'Accept': 'application/vnd.github.v3+json',
      },
      body: json.encode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete file: ${response.body}');
    }
  }
}
