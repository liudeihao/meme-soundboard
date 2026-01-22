import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 设置服务 - 管理用户偏好设置
class SettingsService extends ChangeNotifier {
  static SettingsService? _instance;
  static SettingsService get instance => _instance ??= SettingsService._();

  SettingsService._();

  SharedPreferences? _prefs;

  // 设置项的键名
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyGridColumns = 'grid_columns';
  static const String _keyHapticFeedback = 'haptic_feedback';
  static const String _keyAllowMultiPlay = 'allow_multi_play';
  static const String _keyCustomCategories = 'custom_categories';
  static const String _keyHasImportedDefaults = 'has_imported_defaults';
  static const String _keyStartupCategory = 'startup_category';

  // 默认值
  ThemeMode _themeMode = ThemeMode.system;
  int _gridColumns = 3;
  bool _hapticFeedback = true;
  bool _allowMultiPlay = false;
  List<String> _customCategories = [];
  bool _hasImportedDefaults = false;
  String _startupCategory = '全部'; // 默认启动时显示全部

  // Getters
  ThemeMode get themeMode => _themeMode;
  int get gridColumns => _gridColumns;
  bool get hapticFeedback => _hapticFeedback;
  bool get allowMultiPlay => _allowMultiPlay;
  List<String> get customCategories => _customCategories;
  bool get hasImportedDefaults => _hasImportedDefaults;
  String get startupCategory => _startupCategory;

  /// 获取所有分类（全部、收藏、默认 + 用户自定义分类）
  List<String> get allCategories => ['全部', '收藏', '默认', ..._customCategories];

  /// 初始化设置
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadSettings();
  }

  /// 加载设置
  void _loadSettings() {
    // 主题模式
    final themeModeIndex = _prefs?.getInt(_keyThemeMode) ?? 0;
    _themeMode = ThemeMode.values[themeModeIndex];

    // 网格列数
    _gridColumns = _prefs?.getInt(_keyGridColumns) ?? 3;

    // 触觉反馈
    _hapticFeedback = _prefs?.getBool(_keyHapticFeedback) ?? true;

    // 同时播放
    _allowMultiPlay = _prefs?.getBool(_keyAllowMultiPlay) ?? false;

    // 自定义分类
    _customCategories = _prefs?.getStringList(_keyCustomCategories) ?? [];

    // 是否已导入默认音效
    _hasImportedDefaults = _prefs?.getBool(_keyHasImportedDefaults) ?? false;

    // 启动时显示的分类
    _startupCategory = _prefs?.getString(_keyStartupCategory) ?? '全部';

    notifyListeners();
  }

  /// 设置主题模式
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs?.setInt(_keyThemeMode, mode.index);
    notifyListeners();
  }

  /// 设置网格列数
  Future<void> setGridColumns(int columns) async {
    _gridColumns = columns.clamp(2, 5);
    await _prefs?.setInt(_keyGridColumns, _gridColumns);
    debugPrint('✅ 网格列数已更新为: $_gridColumns');
    notifyListeners();
  }

  /// 设置触觉反馈
  Future<void> setHapticFeedback(bool enabled) async {
    _hapticFeedback = enabled;
    await _prefs?.setBool(_keyHapticFeedback, enabled);
    notifyListeners();
  }

  /// 设置同时播放
  Future<void> setAllowMultiPlay(bool enabled) async {
    _allowMultiPlay = enabled;
    await _prefs?.setBool(_keyAllowMultiPlay, enabled);
    notifyListeners();
  }

  /// 添加自定义分类
  Future<void> addCategory(String category) async {
    if (category.isNotEmpty && !_customCategories.contains(category)) {
      _customCategories.add(category);
      await _prefs?.setStringList(_keyCustomCategories, _customCategories);
      notifyListeners();
    }
  }

  /// 删除自定义分类
  Future<void> removeCategory(String category) async {
    _customCategories.remove(category);
    await _prefs?.setStringList(_keyCustomCategories, _customCategories);
    notifyListeners();
  }

  /// 重置所有自定义分类
  Future<void> resetCategories() async {
    _customCategories.clear();
    await _prefs?.setStringList(_keyCustomCategories, _customCategories);
    notifyListeners();
  }

  /// 标记已导入默认音效
  Future<void> markDefaultsImported() async {
    _hasImportedDefaults = true;
    await _prefs?.setBool(_keyHasImportedDefaults, true);
  }

  /// 重置默认音效状态（用于清空所有数据时）
  Future<void> resetDefaultsImported() async {
    _hasImportedDefaults = false;
    await _prefs?.setBool(_keyHasImportedDefaults, false);
  }

  /// 设置启动时显示的分类
  Future<void> setStartupCategory(String category) async {
    _startupCategory = category;
    await _prefs?.setString(_keyStartupCategory, category);
    notifyListeners();
  }

  /// 获取主题模式的显示文本
  String getThemeModeText() {
    switch (_themeMode) {
      case ThemeMode.system:
        return '跟随系统';
      case ThemeMode.light:
        return '浅色模式';
      case ThemeMode.dark:
        return '深色模式';
    }
  }
}
