import 'package:flutter/material.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading Groups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Navigate to create group
            },
            tooltip: 'Create Group',
          ),
        ],
      ),
      body: const Center(child: Text('My Reading Groups (Coming Soon)')),
    );
  }
}
