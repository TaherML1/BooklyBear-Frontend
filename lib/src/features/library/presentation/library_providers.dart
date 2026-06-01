import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/library_repository.dart';
import '../domain/user_book.dart';
import '../../gamification/domain/reading_session.dart';

/// Fetches and caches the full library list.
final libraryProvider = FutureProvider<List<UserBook>>((ref) async {
  return ref.watch(libraryRepositoryProvider).getMyLibrary();
});

/// Convenience providers that filter by status — saves rebuilds.
final readingBooksProvider = Provider<AsyncValue<List<UserBook>>>((ref) {
  return ref
      .watch(libraryProvider)
      .whenData(
        (books) =>
            books.where((b) => b.status == ReadingStatus.reading).toList(),
      );
});

final toReadBooksProvider = Provider<AsyncValue<List<UserBook>>>((ref) {
  return ref
      .watch(libraryProvider)
      .whenData(
        (books) =>
            books.where((b) => b.status == ReadingStatus.toRead).toList(),
      );
});

final finishedBooksProvider = Provider<AsyncValue<List<UserBook>>>((ref) {
  return ref
      .watch(libraryProvider)
      .whenData(
        (books) => books.where((b) => b.status == ReadingStatus.read).toList(),
      );
});

final favoriteBooksProvider = Provider<AsyncValue<List<UserBook>>>((ref) {
  return ref
      .watch(libraryProvider)
      .whenData(
        (books) => books.where((b) => b.isFavorite).toList(),
      );
});

// --- Activity Providers ---
final readingHistoryProvider = FutureProvider<List<ReadingSession>>((ref) async {
  final repository = ref.watch(libraryRepositoryProvider);
  final rawData = await repository.getRawReadingHistory();
  return rawData.map((e) => ReadingSession.fromJson(e as Map<String, dynamic>)).toList();
});
