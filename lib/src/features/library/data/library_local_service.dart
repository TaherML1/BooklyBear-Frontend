import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum BookDisplayStyle { cover, spine, flat, auto }

// Provides SharedPreferences (assumed to be initialized in main or overridden as needed,
// but we'll use a FutureProvider here to avoid throwing UnimplementedError if not overridden)
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((
  ref,
) async {
  return await SharedPreferences.getInstance();
});

/// A service to save and retrieve the custom sorting order of books in the bookshelf,
/// as well as individual visual display styles.
class LibraryOrderService {
  final SharedPreferences _prefs;

  LibraryOrderService(this._prefs);

  /// Saves the ordered list of ISBNs for a specific reading status list
  Future<void> saveOrder(String statusKey, List<String> isbns) async {
    await _prefs.setStringList('library_order_$statusKey', isbns);
  }

  /// Retrieves the ordered list of ISBNs
  List<String>? getOrder(String statusKey) {
    return _prefs.getStringList('library_order_$statusKey');
  }

  /// Retrieves the persisted display style overrides
  Map<String, BookDisplayStyle> getDisplayStyles() {
    final str = _prefs.getString('library_display_styles');
    if (str == null) return {};

    try {
      final map = jsonDecode(str) as Map<String, dynamic>;
      return map.map((key, value) {
        final style = BookDisplayStyle.values.firstWhere(
          (e) => e.name == value,
          orElse: () => BookDisplayStyle.auto,
        );
        return MapEntry(key, style);
      });
    } catch (e) {
      return {};
    }
  }

  /// Saves a specific display style for a book
  Future<void> saveDisplayStyle(String isbn, BookDisplayStyle style) async {
    final currentMap = getDisplayStyles();
    currentMap[isbn] = style;

    final strMap = currentMap.map((key, value) => MapEntry(key, value.name));
    await _prefs.setString('library_display_styles', jsonEncode(strMap));
  }
}

final libraryOrderServiceProvider = FutureProvider<LibraryOrderService>((
  ref,
) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return LibraryOrderService(prefs);
});
