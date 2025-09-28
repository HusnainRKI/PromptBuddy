import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:logger/logger.dart';

import '../config/app_config.dart';
import '../models/category.dart';
import '../models/prompt.dart';

enum SyncStatus { synced, pending, conflict }

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static DatabaseService get instance => _instance;
  DatabaseService._internal();

  Database? _database;
  final Logger _logger = Logger();

  Database get database {
    if (_database == null) {
      throw Exception('Database not initialized. Call initialize() first.');
    }
    return _database!;
  }

  Future<void> initialize() async {
    try {
      final databasePath = await getDatabasesPath();
      final path = join(databasePath, AppConfig.databaseName);

      _database = await openDatabase(
        path,
        version: AppConfig.databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );

      _logger.i('Database initialized successfully');
    } catch (e) {
      _logger.e('Failed to initialize database: $e');
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create categories table
    await db.execute(CategoryTable.createTableSql);
    
    // Create prompts table
    await db.execute(PromptTable.createTableSql);
    
    // Create indexes
    await db.execute(PromptTable.createIndexSql);
    
    // Create sync metadata table
    await db.execute('''
      CREATE TABLE sync_metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    _logger.i('Database tables created');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here
    _logger.i('Database upgraded from version $oldVersion to $newVersion');
  }

  // Categories CRUD operations
  Future<List<Category>> getCategories() async {
    try {
      final result = await database.query(
        CategoryTable.tableName,
        orderBy: '${CategoryTable.columnOrderIndex} ASC, ${CategoryTable.columnName} ASC',
      );

      return result.map((json) => Category.fromJson(json)).toList();
    } catch (e) {
      _logger.e('Failed to get categories: $e');
      return [];
    }
  }

  Future<Category?> getCategoryById(String id) async {
    try {
      final result = await database.query(
        CategoryTable.tableName,
        where: '${CategoryTable.columnId} = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (result.isNotEmpty) {
        return Category.fromJson(result.first);
      }
      return null;
    } catch (e) {
      _logger.e('Failed to get category by id: $e');
      return null;
    }
  }

  Future<void> insertOrUpdateCategory(Category category, {SyncStatus syncStatus = SyncStatus.pending}) async {
    try {
      final data = category.toJson();
      data[CategoryTable.columnSyncStatus] = syncStatus.index;
      data[CategoryTable.columnLastSyncedAt] = DateTime.now().toIso8601String();

      await database.insertOrReplace(CategoryTable.tableName, data);
      _logger.d('Category ${category.name} inserted/updated');
    } catch (e) {
      _logger.e('Failed to insert/update category: $e');
      rethrow;
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await database.delete(
        CategoryTable.tableName,
        where: '${CategoryTable.columnId} = ?',
        whereArgs: [id],
      );
      _logger.d('Category $id deleted');
    } catch (e) {
      _logger.e('Failed to delete category: $e');
      rethrow;
    }
  }

  // Prompts CRUD operations
  Future<List<Prompt>> getPrompts({
    String? categoryId,
    String? search,
    List<String>? tags,
    List<String>? excludeTags,
    int? limit,
    int? offset,
    String? orderBy,
  }) async {
    try {
      String query = '''
        SELECT p.*, c.name as category_name, c.color as category_color, c.icon as category_icon
        FROM ${PromptTable.tableName} p
        LEFT JOIN ${CategoryTable.tableName} c ON p.${PromptTable.columnCategoryId} = c.${CategoryTable.columnId}
      ''';
      
      List<String> whereConditions = [];
      List<dynamic> whereArgs = [];

      // Category filter
      if (categoryId != null) {
        whereConditions.add('p.${PromptTable.columnCategoryId} = ?');
        whereArgs.add(categoryId);
      }

      // Search filter using FTS
      if (search != null && search.isNotEmpty) {
        query = '''
          SELECT p.*, c.name as category_name, c.color as category_color, c.icon as category_icon
          FROM prompts_fts fts
          JOIN ${PromptTable.tableName} p ON fts.rowid = p.rowid
          LEFT JOIN ${CategoryTable.tableName} c ON p.${PromptTable.columnCategoryId} = c.${CategoryTable.columnId}
          WHERE prompts_fts MATCH ?
        ''';
        whereArgs.insert(0, '*$search*');
      }

      // Tag filters
      if (tags != null && tags.isNotEmpty) {
        for (final tag in tags) {
          whereConditions.add('p.${PromptTable.columnTags} LIKE ?');
          whereArgs.add('%"$tag"%');
        }
      }

      if (excludeTags != null && excludeTags.isNotEmpty) {
        for (final tag in excludeTags) {
          whereConditions.add('p.${PromptTable.columnTags} NOT LIKE ?');
          whereArgs.add('%"$tag"%');
        }
      }

      if (whereConditions.isNotEmpty) {
        final whereClause = search != null && search.isNotEmpty ? 'AND' : 'WHERE';
        query += ' $whereClause ${whereConditions.join(' AND ')}';
      }

      // Order by
      query += ' ORDER BY ${orderBy ?? 'p.${PromptTable.columnUpdatedAt} DESC'}';

      // Limit and offset
      if (limit != null) {
        query += ' LIMIT $limit';
        if (offset != null) {
          query += ' OFFSET $offset';
        }
      }

      final result = await database.rawQuery(query, whereArgs);
      
      return result.map((json) {
        // Parse JSON arrays
        json['tags'] = jsonDecode(json['tags'] as String? ?? '[]');
        json['variables'] = jsonDecode(json['variables'] as String? ?? '[]');
        json['is_favorite'] = (json['is_favorite'] as int?) == 1;
        return Prompt.fromJson(json);
      }).toList();
    } catch (e) {
      _logger.e('Failed to get prompts: $e');
      return [];
    }
  }

  Future<Prompt?> getPromptById(String id) async {
    try {
      final result = await database.rawQuery('''
        SELECT p.*, c.name as category_name, c.color as category_color, c.icon as category_icon
        FROM ${PromptTable.tableName} p
        LEFT JOIN ${CategoryTable.tableName} c ON p.${PromptTable.columnCategoryId} = c.${CategoryTable.columnId}
        WHERE p.${PromptTable.columnId} = ?
      ''', [id]);

      if (result.isNotEmpty) {
        final json = result.first;
        json['tags'] = jsonDecode(json['tags'] as String? ?? '[]');
        json['variables'] = jsonDecode(json['variables'] as String? ?? '[]');
        json['is_favorite'] = (json['is_favorite'] as int?) == 1;
        return Prompt.fromJson(json);
      }
      return null;
    } catch (e) {
      _logger.e('Failed to get prompt by id: $e');
      return null;
    }
  }

  Future<void> insertOrUpdatePrompt(Prompt prompt, {SyncStatus syncStatus = SyncStatus.pending}) async {
    try {
      final data = prompt.toJson();
      data[PromptTable.columnTags] = jsonEncode(prompt.tags);
      data[PromptTable.columnVariables] = jsonEncode(prompt.variables);
      data[PromptTable.columnIsFavorite] = prompt.isFavorite == true ? 1 : 0;
      data[PromptTable.columnSyncStatus] = syncStatus.index;
      data[PromptTable.columnLastSyncedAt] = DateTime.now().toIso8601String();

      await database.insertOrReplace(PromptTable.tableName, data);
      
      // Update FTS index
      await database.rawInsert('''
        INSERT OR REPLACE INTO prompts_fts(rowid, title, body, tags)
        VALUES ((SELECT rowid FROM ${PromptTable.tableName} WHERE ${PromptTable.columnId} = ?), ?, ?, ?)
      ''', [prompt.id, prompt.title, prompt.body, jsonEncode(prompt.tags)]);
      
      _logger.d('Prompt ${prompt.title} inserted/updated');
    } catch (e) {
      _logger.e('Failed to insert/update prompt: $e');
      rethrow;
    }
  }

  Future<void> deletePrompt(String id) async {
    try {
      await database.delete(
        PromptTable.tableName,
        where: '${PromptTable.columnId} = ?',
        whereArgs: [id],
      );
      
      // Remove from FTS index
      await database.rawDelete('''
        DELETE FROM prompts_fts WHERE rowid = (
          SELECT rowid FROM ${PromptTable.tableName} WHERE ${PromptTable.columnId} = ?
        )
      ''', [id]);
      
      _logger.d('Prompt $id deleted');
    } catch (e) {
      _logger.e('Failed to delete prompt: $e');
      rethrow;
    }
  }

  Future<void> toggleFavorite(String promptId) async {
    try {
      final prompt = await getPromptById(promptId);
      if (prompt != null) {
        final updatedPrompt = prompt.copyWith(
          isFavorite: !(prompt.isFavorite ?? false),
          updatedAt: DateTime.now(),
        );
        await insertOrUpdatePrompt(updatedPrompt);
      }
    } catch (e) {
      _logger.e('Failed to toggle favorite: $e');
      rethrow;
    }
  }

  Future<void> incrementUsageCount(String promptId) async {
    try {
      final prompt = await getPromptById(promptId);
      if (prompt != null) {
        final updatedPrompt = prompt.copyWith(
          usageCount: prompt.usageCount + 1,
          lastUsedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await insertOrUpdatePrompt(updatedPrompt);
      }
    } catch (e) {
      _logger.e('Failed to increment usage count: $e');
      rethrow;
    }
  }

  // Favorites
  Future<List<Prompt>> getFavoritePrompts({int? limit}) async {
    return getPrompts(
      orderBy: 'p.${PromptTable.columnLastUsedAt} DESC',
      limit: limit,
    ).then((prompts) => prompts.where((p) => p.isFavorite == true).toList());
  }

  // Recently used
  Future<List<Prompt>> getRecentlyUsedPrompts({int limit = 10}) async {
    return getPrompts(
      orderBy: 'p.${PromptTable.columnLastUsedAt} DESC',
      limit: limit,
    ).then((prompts) => prompts.where((p) => p.lastUsedAt != null).toList());
  }

  // Sync metadata
  Future<void> setSyncMetadata(String key, String value) async {
    try {
      await database.insertOrReplace('sync_metadata', {
        'key': key,
        'value': value,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _logger.e('Failed to set sync metadata: $e');
      rethrow;
    }
  }

  Future<String?> getSyncMetadata(String key) async {
    try {
      final result = await database.query(
        'sync_metadata',
        where: 'key = ?',
        whereArgs: [key],
        limit: 1,
      );

      if (result.isNotEmpty) {
        return result.first['value'] as String?;
      }
      return null;
    } catch (e) {
      _logger.e('Failed to get sync metadata: $e');
      return null;
    }
  }

  // Get items that need to be synced
  Future<List<Category>> getCategoriesPendingSync() async {
    try {
      final result = await database.query(
        CategoryTable.tableName,
        where: '${CategoryTable.columnSyncStatus} = ?',
        whereArgs: [SyncStatus.pending.index],
      );

      return result.map((json) => Category.fromJson(json)).toList();
    } catch (e) {
      _logger.e('Failed to get categories pending sync: $e');
      return [];
    }
  }

  Future<List<Prompt>> getPromptsPendingSync() async {
    try {
      final result = await database.query(
        PromptTable.tableName,
        where: '${PromptTable.columnSyncStatus} = ?',
        whereArgs: [SyncStatus.pending.index],
      );

      return result.map((json) {
        json['tags'] = jsonDecode(json['tags'] as String? ?? '[]');
        json['variables'] = jsonDecode(json['variables'] as String? ?? '[]');
        json['is_favorite'] = (json['is_favorite'] as int?) == 1;
        return Prompt.fromJson(json);
      }).toList();
    } catch (e) {
      _logger.e('Failed to get prompts pending sync: $e');
      return [];
    }
  }

  // Clear all data
  Future<void> clearAllData() async {
    try {
      await database.delete(CategoryTable.tableName);
      await database.delete(PromptTable.tableName);
      await database.delete('prompts_fts');
      await database.delete('sync_metadata');
      _logger.i('All data cleared');
    } catch (e) {
      _logger.e('Failed to clear data: $e');
      rethrow;
    }
  }

  // Close database
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}