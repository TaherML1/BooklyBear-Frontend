# Bookly-Bear: Dynamic Bookshelf Architecture

This document tracks the technical implementation and architectural decisions made for the "My Collection" Bookshelf view in the Bookly-Bear Flutter Frontend.

## 1. Feature Overview

The interactive bookshelf allows users to organize their digital physical books in a highly personalized, visually premium interface. The bookshelf organically layouts books, extracting accurate cover colors dynamically, and offering drag-and-drop customization.

Key Capabilities:
- **Algorithmic Organic Placements:** Books subtly vary in height and width.
- **Dynamic Spine Colors:** Spines perfectly match their real-world uploaded covers using `palette_generator`.
- **Drag & Drop Ordering:** Users can define exact spatial relationships.
- **Custom Display Poses:** Users can explicitly pick if a book shows its spine, faces front, or lies flat.

## 2. Technical Stack & State Management

- **UI Framework:** Flutter / Dart
- **State Management:** Riverpod (`StateNotifierProvider`, `FutureProvider`)
- **Persistence:** Local Storage via `shared_preferences`
- **Image Processing:** `palette_generator` package

## 3. Core Components

### 3.1. Color Caching (`book_palette_provider.dart`)
Extracting vibrant colors from network images is an expensive CPU task. If done synchronously during `ListView` scrolling, it generates immense frame drops.
- **Implementation:** `BookPaletteNotifier` acts as an asynchronous in-memory cache.
- **Workflow:** When `BookshelfView` requests a color syncing `getColorSync(isbn, url)`, the provider instantly returns a default `AppTheme.primary` color. In the background, it triggers the `palette_generator` engine to parse the network image. Once the computation completes, it caches the `Color` object against the `ISBN` string and forces a state rebuild, allowing the UI to snap into the correct color smoothly.

### 3.2. Order & Style Persistence (`library_local_service.dart`)
Local persistence ensures immediate and offline-ready responsiveness without hitting backend database limits for minor styling configurations.
- **Component:** `LibraryOrderService`
- **Sorting Storage:** Saves lists of Strings (`ISBN` IDs) indexed by `statusKey` ('reading', 'to_read', 'finished') mapped as: `library_order_$statusKey`.
- **Display Style Storage:** Uses a globally serialized JSON Map encoding the `ISBN` against a `BookDisplayStyle` enum (`cover`, `spine`, `flat`, `auto`).

### 3.3. Visual Rendering Engine (`bookshelf_view.dart`)
Instead of a simple generic list, books are chunked into shelves containing 2 to 4 items.
- **Widgets:** `_CoverBook`, `_SpineBook`, `_FlatBook`.
- **Texturing Details:**
  * **Spine:** Modulates the base color's saturation and lightness via `HSLColor` manipulation to create realistic dark leather textures.
  * **Stack:** Contains gold foil text overlays `(Color(0xFFE8CF94))` rendered vertically or horizontally with sharp box shadows that simulate engraving.
  * **Shelves:** Designed using layered gradients, drop shadows, and gloss highlights to simulate highly polished dark wood (`Color(0xFF5D4037)`).

### 3.4. Edit Mode Interface (`library_screen.dart`)
The UI leverages `ReorderableListView` to handle exact positioning.
- **Toggles:** We implemented a `trailing` cyclical state button inside each `ListTile` allowing rapid cycling among `Auto -> Cover -> Spine -> Flat` saving changes instantly to `LibraryOrderService`.

## 4. Future Considerations

- **Backend Sync:** If users desire seamless cloud transfer, the JSON Map and Ordering Arrays within `LibraryOrderService` can be attached to the existing `User` or `Profile` backend endpoints.
- **SQLite / Hive:** If libraries scale to thousands of entries, `shared_preferences` read limitations could occur making `Hive` a stronger choice for the explicit image Color Caching.
