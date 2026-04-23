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
  static const String _keyCategoriesOrder = 'categories_order';
  static const String _keyUiLocale = 'ui_locale';

  /// `system` | `zh` | `en`
  static const String uiLocaleSystem = 'system';
  static const String uiLocaleZh = 'zh';
  static const String uiLocaleEn = 'en';

  // 默认值
  ThemeMode _themeMode = ThemeMode.system;
  int _gridColumns = 3;
  bool _hapticFeedback = true;
  bool _allowMultiPlay = false;
  List<String> _customCategories = [];
  bool _hasImportedDefaults = false;
  String _startupCategory = '全部'; // 默认启动时显示全部
  late List<String> _categoriesOrder; // 分类显示顺序
  String _uiLocale = uiLocaleSystem;

  // Getters
  ThemeMode get themeMode => _themeMode;
  int get gridColumns => _gridColumns;
  bool get hapticFeedback => _hapticFeedback;
  bool get allowMultiPlay => _allowMultiPlay;
  List<String> get customCategories => _customCategories;
  bool get hasImportedDefaults => _hasImportedDefaults;
  String get startupCategory => _startupCategory;
  List<String> get categoriesOrder => _categoriesOrder;

  /// 界面语言偏好：`system` / `zh` / `en`
  String get uiLocale => _uiLocale;

  /// `null` 表示跟随系统，否则为固定界面语言
  Locale? get localeOverride {
    switch (_uiLocale) {
      case uiLocaleZh:
        return const Locale('zh');
      case uiLocaleEn:
        return const Locale('en');
      default:
        return null;
    }
  }

  /// 获取所有分类（根据保存的顺序返回）
  List<String> get allCategories {
    // 确保所有分类都在顺序列表中
    final defaultCategories = ['全部', '收藏', '默认'];
    final allCats = [...defaultCategories, ..._customCategories];
    
    // 筛选出存在的分类并按照保存的顺序排列
    final ordered = <String>[];
    for (final cat in _categoriesOrder) {
      if (allCats.contains(cat)) {
        ordered.add(cat);
      }
    }
    
    // 添加任何未在 _categoriesOrder 中的分类（新添加的分类）
    for (final cat in allCats) {
      if (!ordered.contains(cat)) {
        ordered.add(cat);
      }
    }
    
    return ordered;
  }

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

    // 分类显示顺序
    _categoriesOrder = _prefs?.getStringList(_keyCategoriesOrder) ?? ['全部', '收藏', '默认'];

    _uiLocale = _prefs?.getString(_keyUiLocale) ?? uiLocaleSystem;
    if (_uiLocale != uiLocaleSystem &&
        _uiLocale != uiLocaleZh &&
        _uiLocale != uiLocaleEn) {
      _uiLocale = uiLocaleSystem;
    }

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
      // 添加新分类到顺序列表的末尾
      _categoriesOrder.add(category);
      await _prefs?.setStringList(_keyCategoriesOrder, _categoriesOrder);
      notifyListeners();
    }
  }

  /// 删除自定义分类
  Future<void> removeCategory(String category) async {
    _customCategories.remove(category);
    await _prefs?.setStringList(_keyCustomCategories, _customCategories);
    // 从顺序列表中移除
    _categoriesOrder.remove(category);
    await _prefs?.setStringList(_keyCategoriesOrder, _categoriesOrder);
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

  /// 更新分类显示顺序
  Future<void> setCategoriesOrder(List<String> order) async {
    _categoriesOrder = order;
    await _prefs?.setStringList(_keyCategoriesOrder, order);
    notifyListeners();
  }

  Future<void> setUiLocale(String code) async {
    if (code != uiLocaleSystem &&
        code != uiLocaleZh &&
        code != uiLocaleEn) {
      return;
    }
    _uiLocale = code;
    await _prefs?.setString(_keyUiLocale, code);
    notifyListeners();
  }
}
