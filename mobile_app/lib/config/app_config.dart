class AppConfig {
  static const String appName = 'PromptBuddy';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
  
  // API Configuration
  static const String baseUrl = 'http://localhost:3001/api';
  static const String apiVersion = 'v1';
  
  // Database Configuration
  static const String databaseName = 'prompt_buddy.db';
  static const int databaseVersion = 1;
  
  // Sync Configuration
  static const Duration syncInterval = Duration(minutes: 15);
  static const Duration retryDelay = Duration(seconds: 30);
  static const int maxRetryAttempts = 3;
  
  // UI Configuration
  static const int promptsPerPage = 20;
  static const int searchDebounceMs = 300;
  static const int maxRecentPrompts = 10;
  
  // File Configuration
  static const List<String> supportedImportExtensions = ['.json'];
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  
  // Cache Configuration
  static const Duration cacheExpiry = Duration(hours: 24);
  static const int maxCachedImages = 100;
  
  // Feature Flags
  static const bool enableAnalytics = false;
  static const bool enableCrashReporting = false;
  static const bool enableDebugLogging = true;
  
  // URLs
  static const String privacyPolicyUrl = 'https://promptbuddy.com/privacy';
  static const String termsOfServiceUrl = 'https://promptbuddy.com/terms';
  static const String supportUrl = 'https://promptbuddy.com/support';
  static const String githubUrl = 'https://github.com/HusnainRKI/PromptBuddy';
}