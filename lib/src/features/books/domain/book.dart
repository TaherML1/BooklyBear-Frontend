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
  // Google Books community rating
  final double? averageRating;
  final int? ratingsCount;

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
    this.averageRating,
    this.ratingsCount,
  });

  // Null-safe: uses fallback values for any missing or null fields.
  // Necessary because Typesense search documents may be missing some fields.
  factory Book.fromJson(Map<String, dynamic> json) {
    // Helper to parse double safely
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    // Helper to parse int safely
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    // Helper to parse List of Strings safely
    List<String> parseStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) return value.map((e) => e?.toString() ?? '').toList();
      return [value.toString()];
    }

    return Book(
      id: json['id']?.toString() ?? '',
      isbn: json['isbn']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Unknown Title',
      author: json['author']?.toString() ?? 'Unknown Author',
      description: json['description']?.toString(),
      coverImageUrl: json['coverImageUrl']?.toString() ?? '',
      pageCount: parseInt(json['pageCount']) ?? 0,
      publishedDate: json['publishedDate'] != null
          ? DateTime.tryParse(json['publishedDate'].toString())
          : null,
      authors: parseStringList(json['authors']),
      publisher: json['publisher']?.toString(),
      categories: parseStringList(json['categories']),
      averageRating: parseDouble(json['averageRating']),
      ratingsCount: parseInt(json['ratingsCount']),
    );
  }
}
