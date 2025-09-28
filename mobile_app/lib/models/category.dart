import 'package:json_annotation/json_annotation.dart';

part 'category.g.dart';

@JsonSerializable()
class Category {
  final String id;
  final String name;
  final String icon;
  final int color;
  @JsonKey(name: 'order_index')
  final int orderIndex;
  @JsonKey(name: 'prompt_count')
  final int? promptCount;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.orderIndex,
    this.promptCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) => _$CategoryFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryToJson(this);

  Category copyWith({
    String? id,
    String? name,
    String? icon,
    int? color,
    int? orderIndex,
    int? promptCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      orderIndex: orderIndex ?? this.orderIndex,
      promptCount: promptCount ?? this.promptCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Category(id: $id, name: $name, icon: $icon, color: $color, orderIndex: $orderIndex, promptCount: $promptCount)';
  }
}

// For local database storage
class CategoryTable {
  static const String tableName = 'categories';
  static const String columnId = 'id';
  static const String columnName = 'name';
  static const String columnIcon = 'icon';
  static const String columnColor = 'color';
  static const String columnOrderIndex = 'order_index';
  static const String columnCreatedAt = 'created_at';
  static const String columnUpdatedAt = 'updated_at';
  static const String columnSyncStatus = 'sync_status';
  static const String columnLastSyncedAt = 'last_synced_at';

  static const String createTableSql = '''
    CREATE TABLE $tableName (
      $columnId TEXT PRIMARY KEY,
      $columnName TEXT NOT NULL,
      $columnIcon TEXT NOT NULL,
      $columnColor INTEGER NOT NULL,
      $columnOrderIndex INTEGER NOT NULL,
      $columnCreatedAt TEXT NOT NULL,
      $columnUpdatedAt TEXT NOT NULL,
      $columnSyncStatus INTEGER DEFAULT 0,
      $columnLastSyncedAt TEXT
    )
  ''';
}