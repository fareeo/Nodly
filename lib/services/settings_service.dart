import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized settings backed by [SharedPreferences].
///
/// Singleton – access via `SettingsService()`.
/// Notifies listeners on every change so the UI rebuilds automatically.
class SettingsService extends ChangeNotifier {
  // ── Singleton ──────────────────────────────────────────────────────────
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  SharedPreferences? _prefs;

  // ── Defaults ───────────────────────────────────────────────────────────
  String _themeName = 'Legacy';
  ThemeMode _themeMode = ThemeMode.system;
  int _accentColorValue = 0xFF00897B;
  String _fontFamily = 'RobotoCondensed';
  double _fontSizeScale = 1.0;
  int _notificationPeriodMinutes = 180; // 3 h
  bool _notificationsEnabled = true;

  static const Map<String, int> themeDefaultAccents = {
    'Legacy': 0xFF00897B,          // Teal
    'Material You': 0xFF6750A4,    // M3 Purple / System Dynamic
    'Ocean Depths': 0xFF1565C0,    // Blue
    'Sunset Glow': 0xFFE65100,     // Deep Orange
    'Nordic Frost': 0xFF546E7A,    // Slate Blue
    'Rose Garden': 0xFFAD1457,     // Rose Pink
    'Midnight Amethyst': 0xFF7B1FA2, // Purple
    'Forest Canopy': 0xFF2E7D32,   // Green
  };

  // ── Getters ────────────────────────────────────────────────────────────
  String get themeName => _themeName;
  ThemeMode get themeMode => _themeMode;
  Color get accentColor => Color(_accentColorValue);
  int get accentColorValue => _accentColorValue;
  String get fontFamily => _fontFamily;
  double get fontSizeScale => _fontSizeScale;
  int get notificationPeriodMinutes => _notificationPeriodMinutes;
  bool get notificationsEnabled => _notificationsEnabled;

  // ── Initialisation ─────────────────────────────────────────────────────
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _themeName = _prefs?.getString('themeName') ?? _themeName;
    _themeMode = ThemeMode.values[_prefs?.getInt('themeMode') ?? _themeMode.index];
    _accentColorValue = _prefs?.getInt('accentColor') ??
        themeDefaultAccents[_themeName] ??
        _accentColorValue;
    _fontFamily = _prefs?.getString('fontFamily') ?? _fontFamily;
    _fontSizeScale = _prefs?.getDouble('fontSizeScale') ?? _fontSizeScale;
    _notificationPeriodMinutes =
        _prefs?.getInt('notificationPeriodMinutes') ?? _notificationPeriodMinutes;
    _notificationsEnabled =
        _prefs?.getBool('notificationsEnabled') ?? _notificationsEnabled;
    notifyListeners();
  }

  // ── Setters (persist + notify) ─────────────────────────────────────────
  Future<void> setThemeName(String value) async {
    _themeName = value;
    await _prefs?.setString('themeName', value);
    final defaultAccent = themeDefaultAccents[value];
    if (defaultAccent != null) {
      _accentColorValue = defaultAccent;
      await _prefs?.setInt('accentColor', _accentColorValue);
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode value) async {
    _themeMode = value;
    await _prefs?.setInt('themeMode', value.index);
    notifyListeners();
  }

  Future<void> setAccentColor(Color value) async {
    _accentColorValue = value.toARGB32();
    await _prefs?.setInt('accentColor', _accentColorValue);
    notifyListeners();
  }

  Future<void> setFontFamily(String value) async {
    _fontFamily = value;
    await _prefs?.setString('fontFamily', value);
    notifyListeners();
  }

  Future<void> setFontSizeScale(double value) async {
    _fontSizeScale = value;
    await _prefs?.setDouble('fontSizeScale', value);
    notifyListeners();
  }

  Future<void> setNotificationPeriodMinutes(int value) async {
    _notificationPeriodMinutes = value;
    await _prefs?.setInt('notificationPeriodMinutes', value);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    await _prefs?.setBool('notificationsEnabled', value);
    notifyListeners();
  }

  // ── Available options ──────────────────────────────────────────────────
  static const List<String> themeNames = [
    'Legacy',
    'Material You',
    'Ocean Depths',
    'Sunset Glow',
    'Nordic Frost',
    'Rose Garden',
    'Midnight Amethyst',
    'Forest Canopy',
  ];

  static const List<String> fontFamilies = [
    'System',
    'RobotoCondensed',
    'Inter',
    'Poppins',
    'Lato',
    'Nunito',
    'Source Sans 3',
  ];

  static const List<Color> accentPresets = [
    Color(0xFF00897B), // Teal (legacy)
    Color(0xFF1565C0), // Blue
    Color(0xFF7B1FA2), // Purple
    Color(0xFFAD1457), // Pink
    Color(0xFFD84315), // Deep Orange
    Color(0xFFFFA000), // Amber
    Color(0xFF2E7D32), // Green
    Color(0xFF283593), // Indigo
    Color(0xFF00ACC1), // Cyan
    Color(0xFF5D4037), // Brown
  ];

  static const List<int> notificationPresets = [60, 180, 300]; // 1h, 3h, 5h
}
