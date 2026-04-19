class Chapter {
  final String title;
  final String fileName;
  Chapter({required this.title, required this.fileName});
  String get url => "https://raw.githubusercontent.com/ChoyonBonik/StoryFlow/main/${Uri.encodeComponent(fileName)}";
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
}
