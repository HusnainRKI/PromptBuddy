import 'package:json_annotation/json_annotation.dart';

part 'prompt.g.dart';

@JsonSerializable()
class Prompt {
  final String id;
  final String title;
  final String body;
  @JsonKey(name: 'category_id')
  final String? categoryId;
  @JsonKey(name: 'category_name')
  final String? categoryName;
  @JsonKey(name: 'category_color')
  final int? categoryColor;
  @JsonKey(name: 'category_icon')
  final String? categoryIcon;
  final String language;
  final List<String> tags;
  final List<String> variables;
  @JsonKey(name: 'usage_count')
  final int usageCount;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  
  // Local-only fields
  final bool? isFavorite;
  final DateTime? lastUsedAt;

  const Prompt({
    required this.id,
    required this.title,
    required this.body,
    this.categoryId,
    this.categoryName,
    this.categoryColor,
    this.categoryIcon,
    required this.language,
    required this.tags,
    required this.variables,
    required this.usageCount,
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite,
    this.lastUsedAt,
  });

  factory Prompt.fromJson(Map<String, dynamic> json) => _$PromptFromJson(json);
  Map<String, dynamic> toJson() => _$PromptToJson(this);

  Prompt copyWith({
    String? id,
    String? title,
    String? body,
    String? categoryId,
    String? categoryName,
    int? categoryColor,
    String? categoryIcon,
    String? language,
    List<String>? tags,
    List<String>? variables,
    int? usageCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
    DateTime? lastUsedAt,
  }) {
    return Prompt(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryColor: categoryColor ?? this.categoryColor,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      language: language ?? this.language,
      tags: tags ?? this.tags,
      variables: variables ?? this.variables,
      usageCount: usageCount ?? this.usageCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Prompt && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Prompt(id: $id, title: $title, categoryId: $categoryId, language: $language, tags: $tags, variables: $variables, usageCount: $usageCount, isFavorite: $isFavorite)';
  }

  // Helper methods
  String get bodyPreview {
    if (body.length <= 100) return body;
    return '${body.substring(0, 97)}...';
  }

  bool get hasVariables => variables.isNotEmpty;

  // Parse variables from body text (for validation)
  static List<String> parseVariables(String bodyText) {
    final regex = RegExp(r'\{\{([^}]+)\}\}');
    final matches = regex.allMatches(bodyText);
    return matches
        .map((match) => match.group(1)?.trim())
        .where((variable) => variable != null && variable.isNotEmpty)
        .map((variable) => variable!)
        .toSet()
        .toList();
  }

  // Replace variables in body with provided values
  String renderWithVariables(Map<String, String> values) {
    String result = body;
    for (final variable in variables) {
      final value = values[variable] ?? '{{$variable}}';
      result = result.replaceAll('{{$variable}}', value);
    }
    return result;
  }
}

// For local database storage
class PromptTable {
  static const String tableName = 'prompts';
  static const String columnId = 'id';
  static const String columnTitle = 'title';
  static const String columnBody = 'body';
  static const String columnCategoryId = 'category_id';
  static const String columnLanguage = 'language';
  static const String columnTags = 'tags';
  static const String columnVariables = 'variables';
  static const String columnUsageCount = 'usage_count';
  static const String columnCreatedAt = 'created_at';
  static const String columnUpdatedAt = 'updated_at';
  static const String columnIsFavorite = 'is_favorite';
  static const String columnLastUsedAt = 'last_used_at';
  static const String columnSyncStatus = 'sync_status';
  static const String columnLastSyncedAt = 'last_synced_at';

  static const String createTableSql = '''
    CREATE TABLE $tableName (
      $columnId TEXT PRIMARY KEY,
      $columnTitle TEXT NOT NULL,
      $columnBody TEXT NOT NULL,
      $columnCategoryId TEXT,
      $columnLanguage TEXT NOT NULL DEFAULT 'en',
      $columnTags TEXT NOT NULL DEFAULT '[]',
      $columnVariables TEXT NOT NULL DEFAULT '[]',
      $columnUsageCount INTEGER NOT NULL DEFAULT 0,
      $columnCreatedAt TEXT NOT NULL,
      $columnUpdatedAt TEXT NOT NULL,
      $columnIsFavorite INTEGER DEFAULT 0,
      $columnLastUsedAt TEXT,
      $columnSyncStatus INTEGER DEFAULT 0,
      $columnLastSyncedAt TEXT,
      FOREIGN KEY ($columnCategoryId) REFERENCES categories(id)
    )
  ''';

  static const String createIndexSql = '''
    CREATE INDEX idx_prompts_category ON $tableName($columnCategoryId);
    CREATE INDEX idx_prompts_updated ON $tableName($columnUpdatedAt);
    CREATE INDEX idx_prompts_title ON $tableName($columnTitle);
    CREATE VIRTUAL TABLE prompts_fts USING fts5(title, body, tags, content=$tableName);
  ''';
}