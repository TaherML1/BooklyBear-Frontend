class Book {
  final String id;
  final String isbn;
  final String title;
  final String author;
  final String? description;
  final String coverImageUrl;
  final int pageCount;
  final DateTime? publishedDate;
  final List<String> authors;
  final String? publisher;
  final List<String> categories;


  Book({
    required this.id,
    required this.isbn,
    required this.title,
    required this.author,
    this.description,
    required this.coverImageUrl,
    required this.pageCount,
    this.publishedDate,
    required this.authors,
    this.publisher,
    required this.categories,
  });

  // Factory constructor to create a Book from JSON
  // Updated to match your backend entity
  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      isbn: json['isbn'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      description: json['description'] as String?,
      coverImageUrl: json['coverImageUrl'] as String,
      pageCount: json['pageCount'] as int,
      publishedDate: json['publishedDate'] != null 
          ? DateTime.parse(json['publishedDate']) 
          : null,
      authors: (json['authors'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      publisher: json['publisher'] as String?,
      categories: (json['categories'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
    );
  }
}