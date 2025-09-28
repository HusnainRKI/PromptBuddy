import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../config/router.dart';
import '../providers/categories_provider.dart';
import '../providers/prompts_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/category_chip.dart';
import '../widgets/prompt_card.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/sync_status_indicator.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> 
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load more prompts when scrolling near the bottom
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(promptsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textScale = ref.watch(textScaleProvider);
    
    return MediaQuery.withTextScaling(
      textScaleFactor: textScale,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Icon(
                MdiIcons.lightbulbOutline,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text('PromptBuddy'),
            ],
          ),
          actions: [
            const SyncStatusIndicator(),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => context.goToSearch(),
              tooltip: 'Search prompts',
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'categories':
                    context.push(Routes.categories);
                    break;
                  case 'favorites':
                    context.push(Routes.favorites);
                    break;
                  case 'import_export':
                    context.push(Routes.importExport);
                    break;
                  case 'settings':
                    context.push(Routes.settings);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'categories',
                  child: ListTile(
                    leading: Icon(Icons.folder),
                    title: Text('Categories'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'favorites',
                  child: ListTile(
                    leading: Icon(Icons.favorite),
                    title: Text('Favorites'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'import_export',
                  child: ListTile(
                    leading: Icon(Icons.import_export),
                    title: Text('Import/Export'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'settings',
                  child: ListTile(
                    leading: Icon(Icons.settings),
                    title: Text('Settings'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Recent', icon: Icon(Icons.history)),
              Tab(text: 'Favorites', icon: Icon(Icons.favorite)),
              Tab(text: 'All Prompts', icon: Icon(Icons.list)),
            ],
          ),
        ),
        body: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SearchBarWidget(
                onTap: () => context.goToSearch(),
                readOnly: true,
              ),
            ),
            
            // Categories horizontal scroll
            _buildCategoriesSection(),
            
            // Main content tabs
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildRecentTab(),
                  _buildFavoritesTab(),
                  _buildAllPromptsTab(),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.goToPromptEditor(),
          icon: const Icon(Icons.add),
          label: const Text('New Prompt'),
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Consumer(
      builder: (context, ref, child) {
        final categoriesState = ref.watch(categoriesProvider);
        
        if (categoriesState.isLoading && categoriesState.categories.isEmpty) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (categoriesState.error != null && categoriesState.categories.isEmpty) {
          return SizedBox(
            height: 120,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load categories',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: () => ref.read(categoriesProvider.notifier).refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final categories = categoriesState.categories;
        if (categories.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Categories',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push(Routes.categories),
                    child: const Text('View All'),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: CategoryChip(
                      category: category,
                      onTap: () => context.goToCategory(category.id),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildRecentTab() {
    return Consumer(
      builder: (context, ref, child) {
        final recentPromptsAsync = ref.watch(recentPromptsProvider);
        
        return recentPromptsAsync.when(
          data: (prompts) {
            if (prompts.isEmpty) {
              return _buildEmptyState(
                icon: Icons.history,
                title: 'No Recent Prompts',
                message: 'Prompts you use will appear here for quick access.',
              );
            }
            
            return _buildPromptsList(prompts);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorState(
            'Failed to load recent prompts',
            () => ref.refresh(recentPromptsProvider),
          ),
        );
      },
    );
  }

  Widget _buildFavoritesTab() {
    return Consumer(
      builder: (context, ref, child) {
        final favoritePromptsAsync = ref.watch(favoritePromptsProvider);
        
        return favoritePromptsAsync.when(
          data: (prompts) {
            if (prompts.isEmpty) {
              return _buildEmptyState(
                icon: Icons.favorite_outline,
                title: 'No Favorite Prompts',
                message: 'Tap the heart icon on prompts to add them to your favorites.',
              );
            }
            
            return _buildPromptsList(prompts);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorState(
            'Failed to load favorite prompts',
            () => ref.refresh(favoritePromptsProvider),
          ),
        );
      },
    );
  }

  Widget _buildAllPromptsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final promptsState = ref.watch(promptsProvider);
        
        if (promptsState.isLoading && promptsState.prompts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (promptsState.error != null && promptsState.prompts.isEmpty) {
          return _buildErrorState(
            'Failed to load prompts',
            () => ref.read(promptsProvider.notifier).refresh(),
          );
        }

        if (promptsState.prompts.isEmpty) {
          return _buildEmptyState(
            icon: Icons.note_add_outlined,
            title: 'No Prompts Yet',
            message: 'Create your first prompt to get started!',
            actionLabel: 'Create Prompt',
            onAction: () => context.goToPromptEditor(),
          );
        }

        return _buildPromptsList(
          promptsState.prompts,
          hasMore: promptsState.hasMore,
          isLoadingMore: promptsState.isLoading,
        );
      },
    );
  }

  Widget _buildPromptsList(
    List<dynamic> prompts, {
    bool hasMore = false,
    bool isLoadingMore = false,
  }) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16.0),
      itemCount: prompts.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == prompts.length) {
          // Loading indicator for "load more"
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: isLoadingMore
                  ? const CircularProgressIndicator()
                  : const Text('Pull to load more'),
            ),
          );
        }

        final prompt = prompts[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: PromptCard(
            prompt: prompt,
            onTap: () => context.goToPrompt(prompt.id),
            onFavorite: () => ref
                .read(promptsProvider.notifier)
                .toggleFavorite(prompt.id),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}