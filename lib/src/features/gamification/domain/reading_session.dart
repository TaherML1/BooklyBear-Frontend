import '../../library/domain/user_book.dart';

class ReadingSession {
  final String id;
  final UserBook userBook;
  final int pagesRead;
  final int? minutesSpent;
  final int? startPage;
  final int? endPage;
  final String? notes;
  final DateTime sessionDate;

  ReadingSession({
    required this.id,
    required this.userBook,
    required this.pagesRead,
    this.minutesSpent,
    this.startPage,
    this.endPage,
    this.notes,
    required this.sessionDate,
  });

  factory ReadingSession.fromJson(Map<String, dynamic> json) {
    return ReadingSession(
      id: json['id'] as String,
      userBook: UserBook.fromJson(json['userBook'] as Map<String, dynamic>),
      pagesRead: (json['pagesRead'] as num).toInt(),
      minutesSpent: (json['minutesSpent'] as num?)?.toInt(),
      startPage: (json['startPage'] as num?)?.toInt(),
      endPage: (json['endPage'] as num?)?.toInt(),
      notes: json['notes'] as String?,
      sessionDate: DateTime.tryParse(json['sessionDate'].toString()) ?? DateTime.now(),
    );
  }
}
