import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _themeModeKey = 'theme_mode';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeIndex = prefs.getInt(_themeModeKey) ?? ThemeMode.system.index;
      state = ThemeMode.values[themeModeIndex];
    } catch (e) {
      // If loading fails, keep the default system theme
      state = ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeModeKey, themeMode.index);
      state = themeMode;
    } catch (e) {
      // If saving fails, still update the state
      state = themeMode;
    }
  }

  void toggleTheme() {
    switch (state) {
      case ThemeMode.light:
        setThemeMode(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        setThemeMode(ThemeMode.system);
        break;
      case ThemeMode.system:
        setThemeMode(ThemeMode.light);
        break;
    }
  }

  String get themeModeDisplayName {
    switch (state) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  IconData get themeModeIcon {
    switch (state) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

// Helper to get theme-aware colors
class AppColors {
  static Color getCategoryColor(int colorValue, BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final color = Color(colorValue);
    
    if (brightness == Brightness.dark) {
      // Make colors slightly more muted in dark mode
      return Color.lerp(color, Colors.white, 0.2) ?? color;
    }
    
    return color;
  }

  static Color getOnCategoryColor(int colorValue, BuildContext context) {
    final color = getCategoryColor(colorValue, context);
    final luminance = color.computeLuminance();
    
    // Return white text on dark backgrounds, black text on light backgrounds
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}

// Provider for getting current brightness
final brightnessProvider = Provider<Brightness>((ref) {
  final themeMode = ref.watch(themeModeProvider);
  
  switch (themeMode) {
    case ThemeMode.light:
      return Brightness.light;
    case ThemeMode.dark:
      return Brightness.dark;
    case ThemeMode.system:
      // This would need to be updated based on system settings
      // For now, we'll default to light
      return Brightness.light;
  }
});

// Text scaling provider for accessibility
class TextScaleNotifier extends StateNotifier<double> {
  static const String _textScaleKey = 'text_scale';
  static const double _defaultScale = 1.0;
  static const double _minScale = 0.8;
  static const double _maxScale = 1.6;

  TextScaleNotifier() : super(_defaultScale) {
    _loadTextScale();
  }

  Future<void> _loadTextScale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scale = prefs.getDouble(_textScaleKey) ?? _defaultScale;
      state = scale.clamp(_minScale, _maxScale);
    } catch (e) {
      state = _defaultScale;
    }
  }

  Future<void> setTextScale(double scale) async {
    final clampedScale = scale.clamp(_minScale, _maxScale);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_textScaleKey, clampedScale);
      state = clampedScale;
    } catch (e) {
      state = clampedScale;
    }
  }

  void resetTextScale() {
    setTextScale(_defaultScale);
  }

  double get minScale => _minScale;
  double get maxScale => _maxScale;
  double get defaultScale => _defaultScale;

  bool get isAtDefault => (state - _defaultScale).abs() < 0.01;
  bool get isAtMin => (state - _minScale).abs() < 0.01;
  bool get isAtMax => (state - _maxScale).abs() < 0.01;
}

final textScaleProvider = StateNotifierProvider<TextScaleNotifier, double>(
  (ref) => TextScaleNotifier(),
);