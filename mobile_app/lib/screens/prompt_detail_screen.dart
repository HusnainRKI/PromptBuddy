import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PromptDetailScreen extends ConsumerWidget {
  final String promptId;

  const PromptDetailScreen({super.key, required this.promptId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prompt Details'),
      ),
      body: Center(
        child: Text('Prompt Details - Coming Soon\nPrompt ID: $promptId'),
      ),
    );
  }
}
