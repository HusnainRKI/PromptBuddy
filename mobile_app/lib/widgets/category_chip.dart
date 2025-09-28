import 'package:flutter/material.dart';

import '../models/category.dart';
import '../providers/theme_provider.dart';

class CategoryChip extends StatelessWidget {
  final Category category;
  final VoidCallback? onTap;
  final bool selected;
  final bool showCount;

  const CategoryChip({
    super.key,
    required this.category,
    this.onTap,
    this.selected = false,
    this.showCount = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryColor = AppColors.getCategoryColor(category.color, context);
    final onCategoryColor = AppColors.getOnCategoryColor(category.color, context);

    return Material(
      color: selected ? categoryColor : categoryColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getCategoryIcon(category.icon),
                size: 16,
                color: selected ? onCategoryColor : categoryColor,
              ),
              const SizedBox(width: 6),
              Text(
                category.name,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: selected ? onCategoryColor : categoryColor,
                  fontWeight: FontWeight.medium,
                ),
              ),
              if (showCount && category.promptCount != null) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: selected 
                        ? onCategoryColor.withOpacity(0.2)
                        : categoryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${category.promptCount}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: selected ? onCategoryColor : categoryColor,
                      fontSize: 10,
                    ),
                  ),
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