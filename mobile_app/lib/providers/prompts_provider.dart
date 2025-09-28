import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../models/prompt.dart';
import '../services/database_service.dart';
import '../services/api_service.dart';
import '../services/sync_service.dart';

final _logger = Logger();

// Prompts filter state
class PromptsFilter {
  final String? categoryId;
  final String? search;
  final List<String> tags;
  final List<String> excludeTags;
  final String sortBy;
  final String sortOrder;
  final bool favoritesOnly;

  const PromptsFilter({
    this.categoryId,
    this.search,
    this.tags = const [],
    this.excludeTags = const [],
    this.sortBy = 'updated_at',
    this.sortOrder = 'DESC',
    this.favoritesOnly = false,
  });

  PromptsFilter copyWith({
    String? categoryId,
    String? search,
    List<String>? tags,
    List<String>? excludeTags,
    String? sortBy,
    String? sortOrder,
    bool? favoritesOnly,
  }) {
    return PromptsFilter(
      categoryId: categoryId ?? this.categoryId,
      search: search ?? this.search,
      tags: tags ?? this.tags,
      excludeTags: excludeTags ?? this.excludeTags,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PromptsFilter &&
        other.categoryId == categoryId &&
        other.search == search &&
        other.tags.toString() == tags.toString() &&
        other.excludeTags.toString() == excludeTags.toString() &&
        other.sortBy == sortBy &&
        other.sortOrder == sortOrder &&
        other.favoritesOnly == favoritesOnly;
  }

  @override
  int get hashCode {
    return Object.hash(
      categoryId,
      search,
      tags.toString(),
      excludeTags.toString(),
      sortBy,
      sortOrder,
      favoritesOnly,
    );
  }
}

// Prompts state
class PromptsState {
  final List<Prompt> prompts;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final PromptsFilter filter;
  final DateTime? lastUpdated;
  final int currentPage;

  const PromptsState({
    this.prompts = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.filter = const PromptsFilter(),
    this.lastUpdated,
    this.currentPage = 1,
  });

  PromptsState copyWith({
    List<Prompt>? prompts,
    bool? isLoading,
    bool? hasMore,
    String? error,
    PromptsFilter? filter,
    DateTime? lastUpdated,
    int? currentPage,
  }) {
    return PromptsState(
      prompts: prompts ?? this.prompts,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      filter: filter ?? this.filter,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

// Prompts notifier
class PromptsNotifier extends StateNotifier<PromptsState> {
  PromptsNotifier() : super(const PromptsState()) {
    _loadPrompts();
  }

  Future<void> _loadPrompts({bool append = false}) async {
    try {
      if (!append) {
        state = state.copyWith(isLoading: true, error: null, currentPage: 1);
      }

      final prompts = await DatabaseService.instance.getPrompts(
        categoryId: state.filter.categoryId,
        search: state.filter.search,
        tags: state.filter.tags.isNotEmpty ? state.filter.tags : null,
        excludeTags: state.filter.excludeTags.isNotEmpty ? state.filter.excludeTags : null,
        limit: 20,
        offset: append ? state.prompts.length : 0,
        orderBy: '${state.filter.sortBy} ${state.filter.sortOrder}',
      );

      List<Prompt> filteredPrompts = prompts;
      
      // Apply favorites filter if needed
      if (state.filter.favoritesOnly) {
        filteredPrompts = prompts.where((p) => p.isFavorite == true).toList();
      }

      final List<Prompt> updatedPrompts = append 
          ? [...state.prompts, ...filteredPrompts]
          : filteredPrompts;

      state = state.copyWith(
        prompts: updatedPrompts,
        isLoading: false,
        hasMore: prompts.length >= 20,
        lastUpdated: DateTime.now(),
      );

      // Trigger background sync if needed
      if (!append) {
        _syncPromptsInBackground();
      }
    } catch (e) {
      _logger.e('Failed to load prompts: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> _syncPromptsInBackground() async {
    try {
      if (await ApiService.instance.isConnected()) {
        await SyncService.instance.performSync();
        
        // Reload prompts after sync if still relevant
        if (mounted) {
          await _loadPrompts();
        }
      }
    } catch (e) {
      _logger.w('Background sync failed: $e');
    }
  }

  Future<void> setFilter(PromptsFilter newFilter) async {
    if (state.filter == newFilter) return;
    
    state = state.copyWith(filter: newFilter, prompts: []);
    await _loadPrompts();
  }

  Future<void> refresh() async {
    await _loadPrompts();
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    
    state = state.copyWith(currentPage: state.currentPage + 1);
    await _loadPrompts(append: true);
  }

  Future<void> toggleFavorite(String promptId) async {
    try {
      await DatabaseService.instance.toggleFavorite(promptId);
      
      // Update the prompt in the current list
      final updatedPrompts = state.prompts.map((prompt) {
        if (prompt.id == promptId) {
          return prompt.copyWith(
            isFavorite: !(prompt.isFavorite ?? false),
            updatedAt: DateTime.now(),
          );
        }
        return prompt;
      }).toList();
      
      state = state.copyWith(prompts: updatedPrompts);
    } catch (e) {
      _logger.e('Failed to toggle favorite: $e');
    }
  }

  Future<void> incrementUsage(String promptId) async {
    try {
      await DatabaseService.instance.incrementUsageCount(promptId);
      
      // Also send to API if connected
      if (await ApiService.instance.isConnected()) {
        await ApiService.instance.incrementUsageCount(promptId);
      }
      
      // Update the prompt in the current list
      final updatedPrompts = state.prompts.map((prompt) {
        if (prompt.id == promptId) {
          return prompt.copyWith(
            usageCount: prompt.usageCount + 1,
            lastUsedAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }
        return prompt;
      }).toList();
      
      state = state.copyWith(prompts: updatedPrompts);
    } catch (e) {
      _logger.e('Failed to increment usage: $e');
    }
  }

  Prompt? getPromptById(String id) {
    try {
      return state.prompts.firstWhere((prompt) => prompt.id == id);
    } catch (e) {
      return null;
    }
  }

  List<String> getAllTags() {
    final allTags = <String>{};
    for (final prompt in state.prompts) {
      allTags.addAll(prompt.tags);
    }
    return allTags.toList()..sort();
  }

  List<String> getAllVariables() {
    final allVariables = <String>{};
    for (final prompt in state.prompts) {
      allVariables.addAll(prompt.variables);
    }
    return allVariables.toList()..sort();
  }
}

// Provider for prompts
final promptsProvider = StateNotifierProvider<PromptsNotifier, PromptsState>(
  (ref) => PromptsNotifier(),
);

// Provider for a single prompt by ID
final promptProvider = Provider.family<Prompt?, String>((ref, promptId) {
  final promptsState = ref.watch(promptsProvider);
  try {
    return promptsState.prompts.firstWhere((prompt) => prompt.id == promptId);
  } catch (e) {
    return null;
  }
});

// Provider for recent prompts
final recentPromptsProvider = FutureProvider<List<Prompt>>((ref) async {
  try {
    return await DatabaseService.instance.getRecentlyUsedPrompts(limit: 10);
  } catch (e) {
    _logger.e('Failed to load recent prompts: $e');
    return [];
  }
});

// Provider for favorite prompts
final favoritePromptsProvider = FutureProvider<List<Prompt>>((ref) async {
  try {
    return await DatabaseService.instance.getFavoritePrompts(limit: 50);
  } catch (e) {
    _logger.e('Failed to load favorite prompts: $e');
    return [];
  }
});

// Provider for prompts by category
final promptsByCategoryProvider = Provider.family<List<Prompt>, String>((ref, categoryId) {
  final promptsState = ref.watch(promptsProvider);
  return promptsState.prompts.where((prompt) => prompt.categoryId == categoryId).toList();
});

// Provider for search suggestions
final searchSuggestionsProvider = Provider<List<String>>((ref) {
  final promptsState = ref.watch(promptsProvider);
  
  // Combine tags and common words from titles
  final suggestions = <String>{};
  
  for (final prompt in promptsState.prompts) {
    // Add tags
    suggestions.addAll(prompt.tags);
    
    // Add words from titles (simple word extraction)
    final titleWords = prompt.title
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(' ')
        .where((word) => word.length > 2)
        .take(3);
    suggestions.addAll(titleWords);
  }
  
  return suggestions.toList()..sort();
});

// Provider for prompt statistics
final promptStatsProvider = Provider<Map<String, int>>((ref) {
  final promptsState = ref.watch(promptsProvider);
  
  int totalPrompts = promptsState.prompts.length;
  int favoritePrompts = promptsState.prompts.where((p) => p.isFavorite == true).length;
  int promptsWithVariables = promptsState.prompts.where((p) => p.hasVariables).length;
  int totalUsage = promptsState.prompts.fold(0, (sum, p) => sum + p.usageCount);

  return {
    'total': totalPrompts,
    'favorites': favoritePrompts,
    'withVariables': promptsWithVariables,
    'totalUsage': totalUsage,
  };
});