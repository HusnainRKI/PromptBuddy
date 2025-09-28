import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/home_screen.dart';
import '../screens/categories_screen.dart';
import '../screens/category_detail_screen.dart';
import '../screens/prompt_detail_screen.dart';
import '../screens/prompt_editor_screen.dart';
import '../screens/search_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/import_export_screen.dart';
import '../screens/onboarding_screen.dart';

// Route names
class Routes {
  static const String onboarding = '/onboarding';
  static const String home = '/';
  static const String categories = '/categories';
  static const String categoryDetail = '/categories/:categoryId';
  static const String promptDetail = '/prompts/:promptId';
  static const String promptEditor = '/prompts/editor';
  static const String promptEditExisting = '/prompts/:promptId/edit';
  static const String search = '/search';
  static const String favorites = '/favorites';
  static const String settings = '/settings';
  static const String importExport = '/import-export';
}

// Custom transition builder for smooth animations
Page<T> _buildPageWithTransition<T extends Object?>(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: animation.drive(
          Tween(begin: const Offset(1.0, 0.0), end: Offset.zero).chain(
            CurveTween(curve: Curves.easeInOut),
          ),
        ),
        child: child,
      );
    },
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.home,
    debugLogDiagnostics: true,
    routes: [
      // Onboarding
      GoRoute(
        path: Routes.onboarding,
        name: 'onboarding',
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const OnboardingScreen(),
        ),
      ),

      // Home
      GoRoute(
        path: Routes.home,
        name: 'home',
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const HomeScreen(),
        ),
      ),

      // Categories
      GoRoute(
        path: Routes.categories,
        name: 'categories',
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const CategoriesScreen(),
        ),
      ),

      // Category Detail
      GoRoute(
        path: Routes.categoryDetail,
        name: 'categoryDetail',
        pageBuilder: (context, state) {
          final categoryId = state.pathParameters['categoryId']!;
          return _buildPageWithTransition(
            context,
            state,
            CategoryDetailScreen(categoryId: categoryId),
          );
        },
      ),

      // Prompt Detail
      GoRoute(
        path: Routes.promptDetail,
        name: 'promptDetail',
        pageBuilder: (context, state) {
          final promptId = state.pathParameters['promptId']!;
          return _buildPageWithTransition(
            context,
            state,
            PromptDetailScreen(promptId: promptId),
          );
        },
      ),

      // Prompt Editor (New)
      GoRoute(
        path: Routes.promptEditor,
        name: 'promptEditor',
        pageBuilder: (context, state) {
          final categoryId = state.uri.queryParameters['categoryId'];
          return _buildPageWithTransition(
            context,
            state,
            PromptEditorScreen(categoryId: categoryId),
          );
        },
      ),

      // Prompt Editor (Edit Existing)
      GoRoute(
        path: Routes.promptEditExisting,
        name: 'promptEditExisting',
        pageBuilder: (context, state) {
          final promptId = state.pathParameters['promptId']!;
          return _buildPageWithTransition(
            context,
            state,
            PromptEditorScreen(promptId: promptId),
          );
        },
      ),

      // Search
      GoRoute(
        path: Routes.search,
        name: 'search',
        pageBuilder: (context, state) {
          final query = state.uri.queryParameters['q'] ?? '';
          final categoryId = state.uri.queryParameters['categoryId'];
          return _buildPageWithTransition(
            context,
            state,
            SearchScreen(
              initialQuery: query,
              categoryId: categoryId,
            ),
          );
        },
      ),

      // Favorites
      GoRoute(
        path: Routes.favorites,
        name: 'favorites',
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const FavoritesScreen(),
        ),
      ),

      // Settings
      GoRoute(
        path: Routes.settings,
        name: 'settings',
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const SettingsScreen(),
        ),
      ),

      // Import/Export
      GoRoute(
        path: Routes.importExport,
        name: 'importExport',
        pageBuilder: (context, state) => _buildPageWithTransition(
          context,
          state,
          const ImportExportScreen(),
        ),
      ),
    ],

    // Error handling
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(
        title: const Text('Page Not Found'),
      ),
      body: Center(
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
              'Page Not Found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'The page "${state.uri}" could not be found.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(Routes.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});

// Helper functions for navigation
extension GoRouterExtensions on GoRouter {
  void goToCategory(String categoryId) {
    go(Routes.categoryDetail.replaceAll(':categoryId', categoryId));
  }

  void goToPrompt(String promptId) {
    go(Routes.promptDetail.replaceAll(':promptId', promptId));
  }

  void goToPromptEditor({String? promptId, String? categoryId}) {
    if (promptId != null) {
      go(Routes.promptEditExisting.replaceAll(':promptId', promptId));
    } else {
      final uri = Uri(
        path: Routes.promptEditor,
        queryParameters: categoryId != null ? {'categoryId': categoryId} : null,
      );
      go(uri.toString());
    }
  }

  void goToSearch({String? query, String? categoryId}) {
    final queryParams = <String, String>{};
    if (query != null && query.isNotEmpty) queryParams['q'] = query;
    if (categoryId != null) queryParams['categoryId'] = categoryId;

    final uri = Uri(
      path: Routes.search,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    go(uri.toString());
  }
}

// Helper extension for BuildContext
extension BuildContextNavigation on BuildContext {
  void goToCategory(String categoryId) {
    go(Routes.categoryDetail.replaceAll(':categoryId', categoryId));
  }

  void goToPrompt(String promptId) {
    go(Routes.promptDetail.replaceAll(':promptId', promptId));
  }

  void goToPromptEditor({String? promptId, String? categoryId}) {
    if (promptId != null) {
      go(Routes.promptEditExisting.replaceAll(':promptId', promptId));
    } else {
      final uri = Uri(
        path: Routes.promptEditor,
        queryParameters: categoryId != null ? {'categoryId': categoryId} : null,
      );
      go(uri.toString());
    }
  }

  void goToSearch({String? query, String? categoryId}) {
    final queryParams = <String, String>{};
    if (query != null && query.isNotEmpty) queryParams['q'] = query;
    if (categoryId != null) queryParams['categoryId'] = categoryId;

    final uri = Uri(
      path: Routes.search,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    go(uri.toString());
  }
}