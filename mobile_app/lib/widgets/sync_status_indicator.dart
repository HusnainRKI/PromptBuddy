import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/sync_service.dart';

final syncServiceProvider = Provider<SyncService>((ref) => SyncService.instance);

class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncService = ref.watch(syncServiceProvider);
    final theme = Theme.of(context);

    return StreamBuilder<SyncState>(
      stream: syncService.syncStateStream,
      initialData: syncService.currentState,
      builder: (context, snapshot) {
        final state = snapshot.data ?? SyncState.idle;
        
        return IconButton(
          icon: _buildIcon(state, theme),
          onPressed: () => _showSyncDialog(context, syncService),
          tooltip: _getTooltip(state),
        );
      },
    );
  }

  Widget _buildIcon(SyncState state, ThemeData theme) {
    switch (state) {
      case SyncState.idle:
        return Icon(
          Icons.cloud_done,
          color: theme.colorScheme.onSurfaceVariant,
        );
      case SyncState.syncing:
        return SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
        );
      case SyncState.error:
        return Icon(
          Icons.cloud_off,
          color: theme.colorScheme.error,
        );
    }
  }

  String _getTooltip(SyncState state) {
    switch (state) {
      case SyncState.idle:
        return 'Sync status';
      case SyncState.syncing:
        return 'Syncing...';
      case SyncState.error:
        return 'Sync failed';
    }
  }

  void _showSyncDialog(BuildContext context, SyncService syncService) {
    showDialog(
      context: context,
      builder: (context) => SyncStatusDialog(syncService: syncService),
    );
  }
}

class SyncStatusDialog extends ConsumerStatefulWidget {
  final SyncService syncService;

  const SyncStatusDialog({super.key, required this.syncService});

  @override
  ConsumerState<SyncStatusDialog> createState() => _SyncStatusDialogState();
}

class _SyncStatusDialogState extends ConsumerState<SyncStatusDialog> {
  Map<String, dynamic>? _syncStatus;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSyncStatus();
  }

  Future<void> _loadSyncStatus() async {
    try {
      final status = await widget.syncService.getSyncStatus();
      if (mounted) {
        setState(() {
          _syncStatus = status;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Sync Status'),
      content: _loading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : _buildContent(theme),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: _syncStatus != null ? _syncNow : null,
          child: const Text('Sync Now'),
        ),
      ],
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_syncStatus == null) {
      return const Text('Failed to load sync status');
    }

    final lastSync = _syncStatus!['last_sync'] as String?;
    final pendingCategories = _syncStatus!['pending_categories'] as int? ?? 0;
    final pendingPrompts = _syncStatus!['pending_prompts'] as int? ?? 0;
    final wifiOnly = _syncStatus!['wifi_only'] as bool? ?? false;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatusRow(
          'Last Sync',
          lastSync != null 
              ? _formatDate(DateTime.parse(lastSync))
              : 'Never',
        ),
        const SizedBox(height: 8),
        _buildStatusRow(
          'Pending Changes',
          '${pendingCategories + pendingPrompts} items',
        ),
        const SizedBox(height: 8),
        _buildStatusRow(
          'Wi-Fi Only',
          wifiOnly ? 'Enabled' : 'Disabled',
        ),
        const SizedBox(height: 16),
        StreamBuilder<SyncState>(
          stream: widget.syncService.syncStateStream,
          builder: (context, snapshot) {
            final state = snapshot.data ?? SyncState.idle;
            return _buildCurrentStatus(state, theme);
          },
        ),
      ],
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStatus(SyncState state, ThemeData theme) {
    Color color;
    String status;

    switch (state) {
      case SyncState.idle:
        color = theme.colorScheme.primary;
        status = 'Ready';
        break;
      case SyncState.syncing:
        color = theme.colorScheme.secondary;
        status = 'Syncing...';
        break;
      case SyncState.error:
        color = theme.colorScheme.error;
        status = 'Error';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            state == SyncState.syncing 
                ? Icons.sync 
                : state == SyncState.error
                    ? Icons.error_outline
                    : Icons.check_circle_outline,
            size: 20,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _syncNow() async {
    try {
      await widget.syncService.syncNow();
      await _loadSyncStatus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e')),
        );
      }
    }
  }
}