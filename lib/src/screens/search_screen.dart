import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _isbnController = TextEditingController();

  void _onSearch() {
    if (_isbnController.text.isNotEmpty) {
      // We navigate to the book details page and pass the ISBN in the URL
      context.push('/book/${_isbnController.text}');
    }
  }

  @override
  void dispose() {
    _isbnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Book')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Enter an ISBN to find and add a book to your library.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _isbnController,
              decoration: const InputDecoration(
                labelText: 'Enter ISBN',
                hintText: 'e.g., 9780132350884',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _onSearch,
              icon: const Icon(Icons.search),
              label: const Text('Search'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}