import 'package:flutter/material.dart';

/// 音效来源类型
enum SoundSourceType {
  asset, // 内置资源
  file, // 本地文件
  url, // 网络链接
}

/// 音效高级设置
class SoundAdvancedSettings {
  final double volumeLevel; // 音量级别 0.0-1.0

  const SoundAdvancedSettings({this.volumeLevel = 1.0});

  Map<String, dynamic> toMap() {
    return {'volumeLevel': volumeLevel};
  }

  factory SoundAdvancedSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const SoundAdvancedSettings();
    return SoundAdvancedSettings(
      volumeLevel: (map['volumeLevel'] as num?)?.toDouble() ?? 1.0,
    );
  }

  SoundAdvancedSettings copyWith({double? volumeLevel}) {
    return SoundAdvancedSettings(volumeLevel: volumeLevel ?? this.volumeLevel);
  }
}

/// 音效项模型
class SoundItem {
  final String id;
  final String name;
  final String soundPath;
  final String? imagePath;
  final SoundSourceType sourceType;
  final String category;
  final bool isFavorite;
  final Color? dominantColor;
  final DateTime createdAt;
  final SoundAdvancedSettings advancedSettings;

  SoundItem({
    required this.id,
    required this.name,
    required this.soundPath,
    this.imagePath,
    this.sourceType = SoundSourceType.file,
    this.category = '其他',
    this.isFavorite = false,
    this.dominantColor,
    DateTime? createdAt,
    this.advancedSettings = const SoundAdvancedSettings(),
  }) : createdAt = createdAt ?? DateTime.now();

  /// 兼容旧的 isAsset 属性
  bool get isAsset => sourceType == SoundSourceType.asset;

  /// 是否为URL来源
  bool get isUrl => sourceType == SoundSourceType.url;

  /// 图片是否为URL
  bool get isImageUrl =>
      imagePath != null &&
      (imagePath!.startsWith('http://') || imagePath!.startsWith('https://'));

  /// 获取用于显示的图片路径（内置资源需要加 assets/ 前缀）
  String? get displayImagePath {
    if (imagePath == null) return null;
    if (isImageUrl) return imagePath;
    if (isAsset && !imagePath!.startsWith('assets/')) {
      return 'assets/$imagePath';
    }
    return imagePath;
  }

  SoundItem copyWith({
    String? id,
    String? name,
    String? soundPath,
    String? imagePath,
    SoundSourceType? sourceType,
    String? category,
    bool? isFavorite,
    Color? dominantColor,
    DateTime? createdAt,
    SoundAdvancedSettings? advancedSettings,
  }) {
    return SoundItem(
      id: id ?? this.id,
      name: name ?? this.name,
      soundPath: soundPath ?? this.soundPath,
      imagePath: imagePath ?? this.imagePath,
      sourceType: sourceType ?? this.sourceType,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      dominantColor: dominantColor ?? this.dominantColor,
      createdAt: createdAt ?? this.createdAt,
      advancedSettings: advancedSettings ?? this.advancedSettings,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'soundPath': soundPath,
      'imagePath': imagePath,
      'sourceType': sourceType.index,
      'category': category,
      'isFavorite': isFavorite ? 1 : 0,
      'dominantColor': dominantColor?.value,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'advVolumeLevel': advancedSettings.volumeLevel,
    };
  }

  factory SoundItem.fromMap(Map<String, dynamic> map) {
    // 兼容旧的 isAsset 字段
    SoundSourceType sourceType;
    if (map.containsKey('sourceType')) {
      sourceType = SoundSourceType.values[map['sourceType'] as int];
    } else if ((map['isAsset'] as int?) == 1) {
      sourceType = SoundSourceType.asset;
    } else {
      // 检查是否为URL
      final soundPath = map['soundPath'] as String;
      sourceType =
          (soundPath.startsWith('http://') || soundPath.startsWith('https://'))
          ? SoundSourceType.url
          : SoundSourceType.file;
    }

    return SoundItem(
      id: map['id'] as String,
      name: map['name'] as String,
      soundPath: map['soundPath'] as String,
      imagePath: map['imagePath'] as String?,
      sourceType: sourceType,
      category: map['category'] as String? ?? '其他',
      isFavorite: (map['isFavorite'] as int?) == 1,
      dominantColor: map['dominantColor'] != null
          ? Color(map['dominantColor'] as int)
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
      advancedSettings: SoundAdvancedSettings(
        volumeLevel: (map['advVolumeLevel'] as num?)?.toDouble() ?? 1.0,
      ),
    );
  }

  /// 导出为JSON格式（用于分享）
  Map<String, dynamic> toExportJson() {
    return {
      'name': name,
      'soundPath': soundPath,
      'imagePath': imagePath,
      'sourceType': sourceType.name,
      'category': category,
      'isFavorite': isFavorite,
      'dominantColor': dominantColor?.value,
      'advancedSettings': {'volumeLevel': advancedSettings.volumeLevel},
    };
  }

  /// 从导出JSON导入
  factory SoundItem.fromExportJson(Map<String, dynamic> json) {
    final advSettings = json['advancedSettings'] as Map<String, dynamic>?;

    return SoundItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] as String,
      soundPath: json['soundPath'] as String,
      imagePath: json['imagePath'] as String?,
      sourceType: SoundSourceType.values.firstWhere(
        (e) => e.name == json['sourceType'],
        orElse: () => SoundSourceType.url,
      ),
      category: json['category'] as String? ?? '默认',
      isFavorite: json['isFavorite'] as bool? ?? false,
      dominantColor: json['dominantColor'] != null
          ? Color(json['dominantColor'] as int)
          : null,
      advancedSettings: SoundAdvancedSettings(
        volumeLevel: (advSettings?['volumeLevel'] as num?)?.toDouble() ?? 1.0,
      ),
    );
  }
}
