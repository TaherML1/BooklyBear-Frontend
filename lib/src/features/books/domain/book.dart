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

  // Null-safe: uses fallback values for any missing or null fields.
  // Necessary because Typesense search documents may be missing some fields.
  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id']?.toString() ?? '',
      isbn: json['isbn']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Unknown Title',
      author: json['author']?.toString() ?? 'Unknown Author',
      description: json['description']?.toString(),
      coverImageUrl: json['coverImageUrl']?.toString() ?? '',
      pageCount: (json['pageCount'] as num?)?.toInt() ?? 0,
      publishedDate: json['publishedDate'] != null
          ? DateTime.tryParse(json['publishedDate'].toString())
          : null,
      authors: (json['authors'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      publisher: json['publisher']?.toString(),
      categories: (json['categories'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}
