import 'package:flutter/material.dart';
import '../models/sound_item.dart';
import 'package:uuid/uuid.dart';

/// 内置音效列表
/// 这些音效会在应用首次运行时自动导入到数据库
/// 它们和用户导入的音效等价，可以被编辑、删除或导出
class BuiltInSounds {
  static const _uuid = Uuid();

  static List<SoundItem> get all => [
    // 内置 Meme 音效
    // 注意：soundPath 不要包含 'assets/' 前缀，因为 AssetSource 会自动添加
    SoundItem(
      id: _uuid.v4(),
      name: 'Bruh 猫',
      soundPath: 'sounds/Bruh猫.mp3',
      imagePath: 'images/Bruh猫.png',
      sourceType: SoundSourceType.asset,
      category: '默认',
      isFavorite: false,
      dominantColor: const Color(0xFF8B5A00),
      createdAt: DateTime.now(),
    ),
  ];

  /// 分类对应的图标
  static IconData getCategoryIcon(String category) {
    switch (category) {
      case '全部':
        return Icons.apps_rounded;
      case '收藏':
        return Icons.favorite_rounded;
      default:
        return Icons.folder_rounded; // 用户自定义分类使用文件夹图标
    }
  }

  /// 分类对应的颜色
  static Color getCategoryColor(String category) {
    switch (category) {
      case '全部':
        return Colors.blue;
      case '收藏':
        return Colors.red;
      default:
        return Colors.blueGrey; // 用户自定义分类使用灰蓝色
    }
  }
}
