import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PromptEditorScreen extends ConsumerWidget {
  final String? promptId;
  final String? categoryId;

  const PromptEditorScreen({super.key, this.promptId, this.categoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(promptId != null ? 'Edit Prompt' : 'New Prompt'),
      ),
      body: Center(
        child: Text(
          promptId != null 
              ? 'Edit Prompt - Coming Soon\nPrompt ID: $promptId'
              : 'New Prompt - Coming Soon\nCategory ID: $categoryId',
        ),
      ),
    );
  }
}
