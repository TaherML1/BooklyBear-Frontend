import '../../books/domain/book.dart';

enum ReadingStatus { toRead, reading, read, dnf }

ReadingStatus readingStatusFromString(String s) {
  switch (s) {
    case 'reading':
      return ReadingStatus.reading;
    case 'read':
      return ReadingStatus.read;
    case 'dnf':
      return ReadingStatus.dnf;
    default:
      return ReadingStatus.toRead;
  }
}

String readingStatusToString(ReadingStatus s) {
  switch (s) {
    case ReadingStatus.reading:
      return 'reading';
    case ReadingStatus.read:
      return 'read';
    case ReadingStatus.dnf:
      return 'dnf';
    default:
      return 'to_read';
  }
}

class UserBook {
  final String id;
  final Book book;
  final ReadingStatus status;
  final int currentPage;
  final int? rating;
  final DateTime addedAt;

  UserBook({
    required this.id,
    required this.book,
    required this.status,
    required this.currentPage,
    this.rating,
    required this.addedAt,
  });

  factory UserBook.fromJson(Map<String, dynamic> json) {
    return UserBook(
      id: json['id'] as String,
      book: Book.fromJson(json['book'] as Map<String, dynamic>),
      status: readingStatusFromString(json['status'] as String),
      currentPage: json['currentPage'] as int? ?? 0,
      rating: json['rating'] as int?,
      addedAt: DateTime.parse(json['addedAt'] as String),
    );
  }

  double get progressPercent {
    if (book.pageCount <= 0) return 0.0;
    return (currentPage / book.pageCount).clamp(0.0, 1.0);
  }
}
