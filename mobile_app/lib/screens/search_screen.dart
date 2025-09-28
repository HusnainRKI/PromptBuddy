import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchScreen extends ConsumerWidget {
  final String? initialQuery;
  final String? categoryId;

  const SearchScreen({super.key, this.initialQuery, this.categoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: Center(
        child: Text('Search - Coming Soon\nQuery: $initialQuery\nCategory: $categoryId'),
      ),
    );
  }
}
