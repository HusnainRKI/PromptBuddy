// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prompt.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Prompt _$PromptFromJson(Map<String, dynamic> json) => Prompt(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      categoryId: json['category_id'] as String?,
      categoryName: json['category_name'] as String?,
      categoryColor: json['category_color'] as int?,
      categoryIcon: json['category_icon'] as String?,
      language: json['language'] as String,
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      variables: (json['variables'] as List<dynamic>).map((e) => e as String).toList(),
      usageCount: json['usage_count'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isFavorite: json['is_favorite'] as bool?,
      lastUsedAt: json['last_used_at'] == null
          ? null
          : DateTime.parse(json['last_used_at'] as String),
    );

Map<String, dynamic> _$PromptToJson(Prompt instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'body': instance.body,
      'category_id': instance.categoryId,
      'category_name': instance.categoryName,
      'category_color': instance.categoryColor,
      'category_icon': instance.categoryIcon,
      'language': instance.language,
      'tags': instance.tags,
      'variables': instance.variables,
      'usage_count': instance.usageCount,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'is_favorite': instance.isFavorite,
      'last_used_at': instance.lastUsedAt?.toIso8601String(),
    };