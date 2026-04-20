class Chapter {
  final String title;
  final String fileName;
  Chapter({required this.title, required this.fileName});

  String get url => "https://ChoyonBonik.github.io/Story_flow/books/$fileName";

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      title: json['title'],
      fileName: json['fileName'],
    );
  }
}

class Book {
  final String id;
  final String title;
  final String author;
  final String coverUrl;
  final List<Chapter> chapters;

  Book({
    required this.id, 
    required this.title, 
    required this.author, 
    required this.coverUrl, 
    required this.chapters
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'],
      title: json['title'],
      author: json['author'],
      coverUrl: json['coverUrl'],
      chapters: (json['chapters'] as List).map((c) => Chapter.fromJson(c)).toList(),
    );
  }
}
