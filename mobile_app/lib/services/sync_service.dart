import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';

import '../config/app_config.dart';
import '../models/category.dart';
import '../models/prompt.dart';
import 'api_service.dart';
import 'database_service.dart';

enum SyncState { idle, syncing, error }

class SyncResult {
  final bool success;
  final String? error;
  final int categoriesSynced;
  final int promptsSynced;
  final int conflicts;

  const SyncResult({
    required this.success,
    this.error,
    this.categoriesSynced = 0,
    this.promptsSynced = 0,
    this.conflicts = 0,
  });
}

class SyncService {
  static final SyncService _instance = SyncService._internal();
  static SyncService get instance => _instance;
  SyncService._internal();

  final Logger _logger = Logger();
  final _connectivity = Connectivity();
  Timer? _syncTimer;
  
  final StreamController<SyncState> _syncStateController = StreamController<SyncState>.broadcast();
  final StreamController<SyncResult> _syncResultController = StreamController<SyncResult>.broadcast();
  
  Stream<SyncState> get syncStateStream => _syncStateController.stream;
  Stream<SyncResult> get syncResultStream => _syncResultController.stream;
  
  SyncState _currentState = SyncState.idle;
  SyncState get currentState => _currentState;
  
  bool _isInitialized = false;
  bool _wifiOnlySync = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize API service
      ApiService.instance.initialize();
      
      // Load sync preferences
      await _loadSyncPreferences();
      
      // Start periodic sync
      _startPeriodicSync();
      
      // Listen to connectivity changes
      _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
      
      _isInitialized = true;
      _logger.i('Sync service initialized');
    } catch (e) {
      _logger.e('Failed to initialize sync service: $e');
      rethrow;
    }
  }

  Future<void> _loadSyncPreferences() async {
    // Load Wi-Fi only setting from database or shared preferences
    final wifiOnly = await DatabaseService.instance.getSyncMetadata('wifi_only_sync');
    _wifiOnlySync = wifiOnly == 'true';
  }

  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(AppConfig.syncInterval, (_) async {
      if (_currentState == SyncState.idle) {
        await performSync();
      }
    });
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.none)) {
      _logger.d('Lost network connectivity');
    } else {
      _logger.d('Network connectivity restored');
      // Trigger sync when connection is restored
      if (_currentState == SyncState.idle) {
        Future.delayed(const Duration(seconds: 2), () => performSync());
      }
    }
  }

  Future<bool> _canSync() async {
    final connectivityResults = await _connectivity.checkConnectivity();
    
    if (connectivityResults.contains(ConnectivityResult.none)) {
      return false;
    }
    
    if (_wifiOnlySync) {
      return connectivityResults.contains(ConnectivityResult.wifi);
    }
    
    return true;
  }

  void _setState(SyncState state) {
    _currentState = state;
    _syncStateController.add(state);
  }

  Future<SyncResult> performSync({bool force = false}) async {
    if (!_isInitialized) {
      throw Exception('Sync service not initialized');
    }

    if (_currentState == SyncState.syncing && !force) {
      return const SyncResult(success: false, error: 'Sync already in progress');
    }

    if (!await _canSync()) {
      return const SyncResult(success: false, error: 'No network connection or Wi-Fi only mode enabled');
    }

    _setState(SyncState.syncing);
    _logger.i('Starting sync...');

    try {
      // Test API connection
      final healthCheck = await ApiService.instance.healthCheck();
      if (!healthCheck.success) {
        throw Exception('API health check failed: ${healthCheck.error}');
      }

      int categoriesSynced = 0;
      int promptsSynced = 0;
      int conflicts = 0;

      // Sync categories
      final categoryResult = await _syncCategories();
      categoriesSynced = categoryResult.categoriesSynced;
      conflicts += categoryResult.conflicts;

      // Sync prompts
      final promptResult = await _syncPrompts();
      promptsSynced = promptResult.promptsSynced;
      conflicts += promptResult.conflicts;

      // Update last sync timestamp
      await DatabaseService.instance.setSyncMetadata(
        'last_sync_timestamp',
        DateTime.now().toIso8601String(),
      );

      final result = SyncResult(
        success: true,
        categoriesSynced: categoriesSynced,
        promptsSynced: promptsSynced,
        conflicts: conflicts,
      );

      _syncResultController.add(result);
      _setState(SyncState.idle);
      _logger.i('Sync completed successfully');
      
      return result;
    } catch (e) {
      final result = SyncResult(success: false, error: e.toString());
      _syncResultController.add(result);
      _setState(SyncState.error);
      _logger.e('Sync failed: $e');
      
      return result;
    }
  }

  Future<SyncResult> _syncCategories() async {
    int synced = 0;
    int conflicts = 0;

    try {
      // Get last sync timestamp for delta sync
      final lastSync = await DatabaseService.instance.getSyncMetadata('categories_last_sync');
      
      // Fetch categories from server
      final response = await ApiService.instance.getCategoriesWithCounts();
      if (!response.success) {
        throw Exception('Failed to fetch categories: ${response.error}');
      }

      final serverCategories = response.data ?? [];
      
      // Get local categories
      final localCategories = await DatabaseService.instance.getCategories();
      final localCategoriesMap = {for (var cat in localCategories) cat.id: cat};

      // Process server categories
      for (final serverCategory in serverCategories) {
        final localCategory = localCategoriesMap[serverCategory.id];
        
        if (localCategory == null) {
          // New category from server
          await DatabaseService.instance.insertOrUpdateCategory(
            serverCategory,
            syncStatus: SyncStatus.synced,
          );
          synced++;
        } else {
          // Check for conflicts
          if (serverCategory.updatedAt.isAfter(localCategory.updatedAt)) {
            // Server version is newer
            await DatabaseService.instance.insertOrUpdateCategory(
              serverCategory,
              syncStatus: SyncStatus.synced,
            );
            synced++;
          } else if (localCategory.updatedAt.isAfter(serverCategory.updatedAt)) {
            // Local version is newer - conflict
            conflicts++;
            _logger.w('Category conflict detected: ${serverCategory.name}');
            // Keep server version and mark local as conflict
            await DatabaseService.instance.insertOrUpdateCategory(
              serverCategory,
              syncStatus: SyncStatus.conflict,
            );
          }
        }
      }

      // Update sync timestamp
      await DatabaseService.instance.setSyncMetadata(
        'categories_last_sync',
        DateTime.now().toIso8601String(),
      );

      return SyncResult(
        success: true,
        categoriesSynced: synced,
        conflicts: conflicts,
      );
    } catch (e) {
      _logger.e('Category sync failed: $e');
      return SyncResult(success: false, error: e.toString());
    }
  }

  Future<SyncResult> _syncPrompts() async {
    int synced = 0;
    int conflicts = 0;

    try {
      // Get last sync timestamp for delta sync
      final lastSync = await DatabaseService.instance.getSyncMetadata('prompts_last_sync');
      
      // Fetch prompts from server with delta sync
      int page = 1;
      bool hasMore = true;
      
      while (hasMore) {
        final response = await ApiService.instance.getPrompts(
          page: page,
          limit: 50,
          updatedAfter: lastSync,
          sortBy: 'updated_at',
          sortOrder: 'DESC',
        );
        
        if (!response.success) {
          throw Exception('Failed to fetch prompts: ${response.error}');
        }

        final serverPrompts = response.data ?? [];
        if (serverPrompts.isEmpty) {
          hasMore = false;
          break;
        }

        // Get local prompts for comparison
        final localPromptsMap = <String, Prompt>{};
        for (final serverPrompt in serverPrompts) {
          final localPrompt = await DatabaseService.instance.getPromptById(serverPrompt.id);
          if (localPrompt != null) {
            localPromptsMap[serverPrompt.id] = localPrompt;
          }
        }

        // Process server prompts
        for (final serverPrompt in serverPrompts) {
          final localPrompt = localPromptsMap[serverPrompt.id];
          
          if (localPrompt == null) {
            // New prompt from server
            await DatabaseService.instance.insertOrUpdatePrompt(
              serverPrompt,
              syncStatus: SyncStatus.synced,
            );
            synced++;
          } else {
            // Check for conflicts
            if (serverPrompt.updatedAt.isAfter(localPrompt.updatedAt)) {
              // Server version is newer
              final mergedPrompt = _mergePrompts(localPrompt, serverPrompt);
              await DatabaseService.instance.insertOrUpdatePrompt(
                mergedPrompt,
                syncStatus: SyncStatus.synced,
              );
              synced++;
            } else if (localPrompt.updatedAt.isAfter(serverPrompt.updatedAt)) {
              // Local version is newer - conflict
              conflicts++;
              _logger.w('Prompt conflict detected: ${serverPrompt.title}');
              // Keep server version and preserve local favorites/usage
              final mergedPrompt = _mergePrompts(localPrompt, serverPrompt);
              await DatabaseService.instance.insertOrUpdatePrompt(
                mergedPrompt,
                syncStatus: SyncStatus.conflict,
              );
            }
          }
        }

        page++;
        hasMore = response.pagination?['page'] < response.pagination?['pages'];
      }

      // Update sync timestamp
      await DatabaseService.instance.setSyncMetadata(
        'prompts_last_sync',
        DateTime.now().toIso8601String(),
      );

      return SyncResult(
        success: true,
        promptsSynced: synced,
        conflicts: conflicts,
      );
    } catch (e) {
      _logger.e('Prompt sync failed: $e');
      return SyncResult(success: false, error: e.toString());
    }
  }

  // Merge local and server prompts, preserving local-only fields
  Prompt _mergePrompts(Prompt local, Prompt server) {
    return server.copyWith(
      isFavorite: local.isFavorite,
      lastUsedAt: local.lastUsedAt,
    );
  }

  // Manual sync trigger
  Future<SyncResult> syncNow() async {
    return performSync(force: true);
  }

  // Get sync status
  Future<Map<String, dynamic>> getSyncStatus() async {
    final lastSync = await DatabaseService.instance.getSyncMetadata('last_sync_timestamp');
    final categoriesLastSync = await DatabaseService.instance.getSyncMetadata('categories_last_sync');
    final promptsLastSync = await DatabaseService.instance.getSyncMetadata('prompts_last_sync');
    
    final pendingCategories = await DatabaseService.instance.getCategoriesPendingSync();
    final pendingPrompts = await DatabaseService.instance.getPromptsPendingSync();

    return {
      'last_sync': lastSync,
      'categories_last_sync': categoriesLastSync,
      'prompts_last_sync': promptsLastSync,
      'pending_categories': pendingCategories.length,
      'pending_prompts': pendingPrompts.length,
      'current_state': _currentState.toString(),
      'wifi_only': _wifiOnlySync,
    };
  }

  // Update sync preferences
  Future<void> setWifiOnlySync(bool enabled) async {
    _wifiOnlySync = enabled;
    await DatabaseService.instance.setSyncMetadata('wifi_only_sync', enabled.toString());
  }

  Future<bool> getWifiOnlySync() async {
    return _wifiOnlySync;
  }

  void dispose() {
    _syncTimer?.cancel();
    _syncStateController.close();
    _syncResultController.close();
  }
}