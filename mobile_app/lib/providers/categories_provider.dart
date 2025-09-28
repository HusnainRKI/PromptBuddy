import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../models/category.dart';
import '../services/database_service.dart';
import '../services/api_service.dart';
import '../services/sync_service.dart';

final _logger = Logger();

// Categories state
class CategoriesState {
  final List<Category> categories;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const CategoriesState({
    this.categories = const [],
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  CategoriesState copyWith({
    List<Category>? categories,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return CategoriesState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

// Categories notifier
class CategoriesNotifier extends StateNotifier<CategoriesState> {
  CategoriesNotifier() : super(const CategoriesState()) {
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // Load from local database first
      final localCategories = await DatabaseService.instance.getCategories();
      
      state = state.copyWith(
        categories: localCategories,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );

      // Trigger background sync if needed
      _syncCategoriesInBackground();
    } catch (e) {
      _logger.e('Failed to load categories: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> _syncCategoriesInBackground() async {
    try {
      if (await ApiService.instance.isConnected()) {
        await SyncService.instance.performSync();
        
        // Reload categories after sync
        final updatedCategories = await DatabaseService.instance.getCategories();
        if (mounted) {
          state = state.copyWith(
            categories: updatedCategories,
            lastUpdated: DateTime.now(),
          );
        }
      }
    } catch (e) {
      _logger.w('Background sync failed: $e');
      // Don't update error state for background sync failures
    }
  }

  Future<void> refresh() async {
    await _loadCategories();
  }

  Future<void> forceSync() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      await SyncService.instance.syncNow();
      
      final updatedCategories = await DatabaseService.instance.getCategories();
      state = state.copyWith(
        categories: updatedCategories,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      _logger.e('Force sync failed: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Category? getCategoryById(String id) {
    try {
      return state.categories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Category> getCategoriesWithPrompts() {
    return state.categories.where((category) => 
      category.promptCount != null && category.promptCount! > 0
    ).toList();
  }

  List<Category> getCategoriesSorted() {
    final categories = List<Category>.from(state.categories);
    categories.sort((a, b) {
      // First sort by order index
      final orderComparison = a.orderIndex.compareTo(b.orderIndex);
      if (orderComparison != 0) return orderComparison;
      
      // Then by name
      return a.name.compareTo(b.name);
    });
    return categories;
  }
}

// Provider for categories
final categoriesProvider = StateNotifierProvider<CategoriesNotifier, CategoriesState>(
  (ref) => CategoriesNotifier(),
);

// Provider for a single category by ID
final categoryProvider = Provider.family<Category?, String>((ref, categoryId) {
  final categoriesState = ref.watch(categoriesProvider);
  try {
    return categoriesState.categories.firstWhere((category) => category.id == categoryId);
  } catch (e) {
    return null;
  }
});

// Provider for sorted categories
final sortedCategoriesProvider = Provider<List<Category>>((ref) {
  final categoriesState = ref.watch(categoriesProvider);
  final categories = List<Category>.from(categoriesState.categories);
  
  categories.sort((a, b) {
    // First sort by order index
    final orderComparison = a.orderIndex.compareTo(b.orderIndex);
    if (orderComparison != 0) return orderComparison;
    
    // Then by name
    return a.name.compareTo(b.name);
  });
  
  return categories;
});

// Provider for categories with prompts
final categoriesWithPromptsProvider = Provider<List<Category>>((ref) {
  final categoriesState = ref.watch(categoriesProvider);
  return categoriesState.categories.where((category) => 
    category.promptCount != null && category.promptCount! > 0
  ).toList();
});

// Provider for category statistics
final categoryStatsProvider = Provider<Map<String, int>>((ref) {
  final categoriesState = ref.watch(categoriesProvider);
  
  int totalCategories = categoriesState.categories.length;
  int categoriesWithPrompts = categoriesState.categories
      .where((cat) => cat.promptCount != null && cat.promptCount! > 0)
      .length;
  int totalPrompts = categoriesState.categories
      .fold(0, (sum, cat) => sum + (cat.promptCount ?? 0));

  return {
    'totalCategories': totalCategories,
    'categoriesWithPrompts': categoriesWithPrompts,
    'totalPrompts': totalPrompts,
  };
});