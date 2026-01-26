import 'package:flutter/material.dart';

/// 应用全局常量定义
class AppConstants {
  // ============ 分类常量 ============
  static const String categoryAll = '全部';
  static const String categoryFavorites = '收藏';
  static const String categoryDefault = '默认';
  static const String categoryOther = '其他';

  static const List<String> systemCategories = [
    categoryAll,
    categoryFavorites,
    categoryDefault,
  ];

  // ============ 文件目录常量 ============
  static const String appDataDir = 'meme_soundboard';
  static const String databaseFileName = 'meme_soundboard.db';

  // ============ 导入导出常量 ============
  static const String exportFileExtension = '.msb';
  static const String exportVersion = '2.0';

  // ============ 示例音效包常量 ============
  /// 预制示例音效包的 asset 路径（放在 assets/samples/ 目录下）
  static const String samplePackAssetPath = 'assets/samples/示例.msb';
  /// 示例音效包的名称（用于显示）
  static const String samplePackName = '示例音效包';

  // ============ 音频格式常量 ============
  static const List<String> supportedAudioFormats = [
    'mp3',
    'wav',
    'aac',
    'm4a',
    'flac',
    'ogg',
    'wma',
    'aiff',
  ];

  // ============ 方法 ============
  static bool isSystemCategory(String category) =>
      systemCategories.contains(category);

  static bool isValidAudioFormat(String filePath) {
    final parts = filePath.split('.');
    if (parts.isEmpty) return false;
    final extension = parts.last.toLowerCase();
    return supportedAudioFormats.contains(extension);
  }

  static String getSupportedFormatsText() {
    return supportedAudioFormats.map((f) => f.toUpperCase()).join(', ');
  }

  // ============ 分类图标和颜色 ============
  /// 分类对应的图标
  static IconData getCategoryIcon(String category) {
    switch (category) {
      case categoryAll:
        return Icons.apps_rounded;
      case categoryFavorites:
        return Icons.favorite_rounded;
      default:
        return Icons.folder_rounded; // 用户自定义分类使用文件夹图标
    }
  }

  /// 分类对应的颜色
  static Color getCategoryColor(String category) {
    switch (category) {
      case categoryAll:
        return Colors.blue;
      case categoryFavorites:
        return Colors.red;
      default:
        return Colors.blueGrey; // 用户自定义分类使用灰蓝色
    }
  }
}