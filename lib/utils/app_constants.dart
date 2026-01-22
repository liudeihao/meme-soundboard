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
  static const String soundsDir = 'sounds';
  static const String imagesDir = 'images';
  static const String databaseFileName = 'meme_soundboard.db';

  // ============ 导入导出常量 ============
  static const String exportFileExtension = '.msb';
  static const String exportVersion = '2.0';

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
}
