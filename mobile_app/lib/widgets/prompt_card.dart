import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/prompt.dart';
import '../providers/theme_provider.dart';

class PromptCard extends StatelessWidget {
  final Prompt prompt;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final VoidCallback? onShare;
  final bool showCategory;
  final bool compact;

  const PromptCard({
    super.key,
    required this.prompt,
    this.onTap,
    this.onFavorite,
    this.onShare,
    this.showCategory = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormatter = DateFormat.yMMMd();

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(compact ? 12.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and actions
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prompt.title,
                          style: compact 
                              ? theme.textTheme.titleMedium
                              : theme.textTheme.titleLarge,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!compact) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Updated ${dateFormatter.format(prompt.updatedAt)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onFavorite != null)
                        IconButton(
                          icon: Icon(
                            prompt.isFavorite == true
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: prompt.isFavorite == true
                                ? Colors.red
                                : null,
                          ),
                          onPressed: onFavorite,
                          tooltip: prompt.isFavorite == true
                              ? 'Remove from favorites'
                              : 'Add to favorites',
                        ),
                      if (onShare != null)
                        IconButton(
                          icon: const Icon(Icons.share),
                          onPressed: onShare,
                          tooltip: 'Share prompt',
                        ),
                    ],
                  ),
                ],
              ),

              if (!compact) ...[
                const SizedBox(height: 8),
                
                // Body preview
                Text(
                  prompt.bodyPreview,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 12),
              ],

              // Category and metadata
              Row(
                children: [
                  // Category pill
                  if (showCategory && prompt.categoryName != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: prompt.categoryColor != null
                            ? AppColors.getCategoryColor(
                                prompt.categoryColor!,
                                context,
                              ).withOpacity(0.2)
                            : theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (prompt.categoryIcon != null) ...[
                            Icon(
                              _getCategoryIcon(prompt.categoryIcon!),
                              size: 14,
                              color: prompt.categoryColor != null
                                  ? AppColors.getCategoryColor(
                                      prompt.categoryColor!,
                                      context,
                                    )
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            prompt.categoryName!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: prompt.categoryColor != null
                                  ? AppColors.getCategoryColor(
                                      prompt.categoryColor!,
                                      context,
                                    )
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.medium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Variables indicator
                  if (prompt.hasVariables) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.code,
                            size: 12,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${prompt.variables.length}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  const Spacer(),

                  // Usage count
                  if (prompt.usageCount > 0) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.trending_up,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${prompt.usageCount}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),

              // Tags
              if (!compact && prompt.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: prompt.tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#$tag',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'camera':
        return Icons.camera_alt;
      case 'code':
        return Icons.code;
      case 'share':
        return Icons.share;
      case 'folder':
        return Icons.folder;
      case 'edit':
        return Icons.edit;
      case 'image':
        return Icons.image;
      case 'text':
        return Icons.text_fields;
      case 'video':
        return Icons.videocam;
      case 'music':
        return Icons.music_note;
      default:
        return Icons.folder;
    }
  }
}