import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart' show Color;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart'
    show
        getDownloadsDirectory,
        getApplicationDocumentsDirectory,
        getExternalStorageDirectory;
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../models/sound_item.dart';
import '../utils/app_constants.dart';
import 'database_service.dart';
import 'settings_service.dart';

/// 导入导出服务
class ImportExportService {
  final DatabaseService _databaseService;

  ImportExportService(this._databaseService);

  /// 判断是否为系统默认分类
  static bool isSystemCategory(String category) =>
      AppConstants.isSystemCategory(category);

  /// 文件名安全化（移除非法字符）
  static String sanitizeFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }

  /// 导出单个音效（包含文件内容）
  Future<String?> exportSound(SoundItem sound) async {
    try {
      final soundData = await _createExportDataWithFiles(sound);

      final exportData = {
        'version': AppConstants.exportVersion,
        'type': 'sound',
        'data': soundData,
        'exportedAt': DateTime.now().toIso8601String(),
      };

      return await _saveExportFile(
        jsonEncode(exportData),
        '${sound.name}${AppConstants.exportFileExtension}',
      );
    } catch (e) {
      debugPrint('导出单个音效失败: $e');
      rethrow;
    }
  }

  /// 创建包含文件内容的导出数据
  Future<Map<String, dynamic>> _createExportDataWithFiles(
    SoundItem sound,
  ) async {
    String? soundBase64;
    String? imageBase64;
    String? soundFileName;
    String? imageFileName;

    // 读取并编码音频文件
    if (sound.sourceType == SoundSourceType.asset) {
      // Asset 资源从 assets 目录读取
      try {
        final byteData = await rootBundle.load('assets/${sound.soundPath}');
        soundBase64 = base64Encode(byteData.buffer.asUint8List());
        soundFileName = p.basename(sound.soundPath);
      } catch (e) {
        // ignore: avoid_print
        print('读取 asset 音频失败: $e');
      }
    } else if (sound.sourceType == SoundSourceType.file) {
      // 本地文件
      final soundFile = File(sound.soundPath);
      if (await soundFile.exists()) {
        final bytes = await soundFile.readAsBytes();
        soundBase64 = base64Encode(bytes);
        soundFileName = p.basename(sound.soundPath);
      }
    }

    // 读取并编码图片文件
    if (sound.imagePath != null) {
      if (sound.sourceType == SoundSourceType.asset &&
          sound.imagePath!.startsWith('images/')) {
        // Asset 图片
        try {
          final byteData = await rootBundle.load('assets/${sound.imagePath}');
          imageBase64 = base64Encode(byteData.buffer.asUint8List());
          imageFileName = p.basename(sound.imagePath!);
        } catch (e) {
          // ignore: avoid_print
          print('读取 asset 图片失败: $e');
        }
      } else if (!sound.imagePath!.startsWith('http')) {
        // 本地图片文件
        final imageFile = File(sound.imagePath!);
        if (await imageFile.exists()) {
          final bytes = await imageFile.readAsBytes();
          imageBase64 = base64Encode(bytes);
          imageFileName = p.basename(sound.imagePath!);
        }
      }
    }

    return {
      'name': sound.name,
      'category': sound.category,
      'isFavorite': sound.isFavorite,
      'dominantColor': sound.dominantColor?.value,
      'advancedSettings': {'volumeLevel': sound.advancedSettings.volumeLevel},
      // 嵌入文件内容
      'soundData': soundBase64,
      'soundFileName': soundFileName,
      'imageData': imageBase64,
      'imageFileName': imageFileName,
    };
  }

  /// 导出分类下的所有音效（包含文件内容）
  Future<String?> exportCategory(
    String category,
    List<SoundItem> sounds,
  ) async {
    try {
      final categorySounds = sounds
          .where((s) => s.category == category)
          .toList();
      final categoryExportData = <Map<String, dynamic>>[];

      for (final sound in categorySounds) {
        final soundData = await _createExportDataWithFiles(sound);
        categoryExportData.add(soundData);
      }

      final exportData = {
        'version': AppConstants.exportVersion,
        'type': 'category',
        'category': category,
        'data': categoryExportData,
        'exportedAt': DateTime.now().toIso8601String(),
      };

      return await _saveExportFile(
        jsonEncode(exportData),
        '${category}_sounds${AppConstants.exportFileExtension}',
      );
    } catch (e) {
      debugPrint('导出分类失败: $e');
      rethrow;
    }
  }

  /// 导出所有音效和配置（包含文件内容）
  Future<String?> exportAll(List<SoundItem> sounds) async {
    try {
      final customCategories = SettingsService.instance.customCategories
          .toList();

      final soundsData = <Map<String, dynamic>>[];
      for (final sound in sounds) {
        final soundData = await _createExportDataWithFiles(sound);
        soundsData.add(soundData);
      }

      final exportData = {
        'version': AppConstants.exportVersion,
        'type': 'full',
        'sounds': soundsData,
        'customCategories': customCategories,
        'settings': {
          'gridColumns': SettingsService.instance.gridColumns,
          'hapticFeedback': SettingsService.instance.hapticFeedback,
          'allowMultiPlay': SettingsService.instance.allowMultiPlay,
        },
        'exportedAt': DateTime.now().toIso8601String(),
      };

      return await _saveExportFile(
        jsonEncode(exportData),
        'backup_${DateTime.now().year}${DateTime.now().month}${DateTime.now().day}${AppConstants.exportFileExtension}',
      );
    } catch (e) {
      debugPrint('导出全部失败: $e');
      rethrow;
    }
  }

  /// 导出多个选中的音效为一个文件
  Future<String> exportMultipleSounds(List<SoundItem> sounds) async {
    final soundsData = <Map<String, dynamic>>[];
    for (final sound in sounds) {
      final soundData = await _createExportDataWithFiles(sound);
      soundsData.add(soundData);
    }

    final exportData = {
      'version': AppConstants.exportVersion,
      'type': 'multiple',
      'sounds': soundsData,
      'count': sounds.length,
      'exportedAt': DateTime.now().toIso8601String(),
    };

    final filename =
        '音效合集_${DateTime.now().millisecondsSinceEpoch}${AppConstants.exportFileExtension}';
    final path = await _saveExportFile(jsonEncode(exportData), filename);

    if (path == null) {
      throw Exception('导出取消');
    }

    return path;
  }

  /// 获取 Android 存储目录（用于导出）
  Future<Directory> _getAndroidStorageDirectory() async {
    // 尝试多个目录选项
    Directory? targetDir;
    String lastError = '';

    // 方案 1: 尝试 Downloads 目录
    try {
      targetDir = await getDownloadsDirectory();
      if (targetDir != null) {
        debugPrint('✓ 使用 Downloads 目录: ${targetDir.path}');
        return targetDir;
      }
    } catch (e) {
      lastError = '下载目录: $e';
      debugPrint('✗ Downloads 目录失败: $e');
    }

    // 方案 2: 尝试外部存储
    try {
      targetDir = await getExternalStorageDirectory();
      if (targetDir != null) {
        debugPrint('✓ 使用外部存储目录: ${targetDir.path}');
        return targetDir;
      }
    } catch (e) {
      lastError = '外部存储: $e';
      debugPrint('✗ 外部存储目录失败: $e');
    }

    // 方案 3: 尝试应用文档目录
    try {
      targetDir = await getApplicationDocumentsDirectory();
      if (targetDir != null) {
        debugPrint('✓ 使用应用文档目录: ${targetDir.path}');
        return targetDir;
      }
    } catch (e) {
      lastError = '文档目录: $e';
      debugPrint('✗ 应用文档目录失败: $e');
    }

    throw Exception('无法获取存储目录。$lastError');
  }

  /// 保存导出文件（允许用户选择位置）
  Future<String?> _saveExportFile(String content, String filename) async {
    try {
      // 在 Android 上使用不同的方式
      if (Platform.isAndroid) {
        final targetDir = await _getAndroidStorageDirectory();

        // 确保目录存在
        if (!await targetDir.exists()) {
          await targetDir.create(recursive: true);
          debugPrint('创建目录: ${targetDir.path}');
        }

        final file = File('${targetDir.path}/$filename');
        await file.writeAsString(content, encoding: utf8);
        debugPrint('✓ 导出文件保存到: ${file.path}');
        return file.path;
      } else {
        // Windows/Mac/Linux 上使用文件选择器
        final result = await FilePicker.platform.saveFile(
          type: FileType.custom,
          allowedExtensions: ['msb'],
          fileName: filename,
          dialogTitle: '选择导出位置',
        );

        if (result == null) {
          return null; // 用户取消
        }

        final file = File(result);
        await file.writeAsString(content, encoding: utf8);
        debugPrint('✓ 导出文件保存到: ${file.path}');
        return file.path;
      }
    } catch (e) {
      debugPrint('✗ 导出文件保存失败: $e');
      rethrow;
    }
  }

  /// 导入文件
  Future<ImportResult> importFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['msb', 'json'],
        dialogTitle: '选择导入文件',
      );

      if (result == null || result.files.isEmpty) {
        return ImportResult(success: false, message: '未选择文件');
      }

      final file = File(result.files.single.path!);
      final content = await file.readAsString(encoding: utf8);

      return await importFromContent(content);
    } catch (e) {
      return ImportResult(success: false, message: '导入失败: $e');
    }
  }

  /// 从URL导入（支持直接粘贴JSON）
  Future<ImportResult> importFromJson(String jsonContent) async {
    try {
      return await importFromContent(jsonContent);
    } catch (e) {
      return ImportResult(success: false, message: '解析失败: $e');
    }
  }

  /// 打开文件选择器并返回文件内容和类型信息
  Future<({String content, String type})?> pickFileAndGetType() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['msb', 'json'],
        dialogTitle: '选择导入文件',
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final file = File(result.files.single.path!);
      final content = await file.readAsString(encoding: utf8);

      try {
        final Map<String, dynamic> data = jsonDecode(content);
        final type = data['type'] as String? ?? 'unknown';
        return (content: content, type: type);
      } catch (e) {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// 统一的导入接口
  /// [content] - 导入文件内容
  /// [overrideCategory] - 是否覆盖原分类为指定分类（为 null 则保持原分类）
  /// [clearFirst] - 导入前是否清空数据库（仅用于完整备份导入）
  Future<ImportResult> importFromContent(
    String content, {
    String? overrideCategory,
    bool clearFirst = false,
  }) async {
    try {
      final Map<String, dynamic> data = jsonDecode(content);

      final version = data['version'] as String?;
      final type = data['type'] as String?;

      if (version == null || type == null) {
        return ImportResult(success: false, message: '无效的导入文件格式');
      }

      // 对于完整备份且需要覆盖，先清空数据库
      if (clearFirst && type == 'full') {
        await _databaseService.clearAllSounds();
        await SettingsService.instance.resetCategories();
      }

      // 确保目标分类存在（如果指定了覆盖分类）
      if (overrideCategory != null && !isSystemCategory(overrideCategory)) {
        final settings = SettingsService.instance;
        if (!settings.allCategories.contains(overrideCategory)) {
          await settings.addCategory(overrideCategory);
        }
      }

      switch (type) {
        case 'sound':
          return await _importSingleSound(data, overrideCategory);
        case 'category':
          return await _importCategory(data, overrideCategory);
        case 'multiple':
          return await _importMultipleSounds(data, overrideCategory);
        case 'full':
          return await _importFull(data, overrideCategory);
        default:
          return ImportResult(success: false, message: '未知的导入类型: $type');
      }
    } catch (e) {
      return ImportResult(success: false, message: 'JSON解析失败: $e');
    }
  }

  /// 导入文件并指定分类
  Future<ImportResult> importFromFileWithCategory(String targetCategory) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['msb', 'json'],
        dialogTitle: '选择导入文件',
      );

      if (result == null || result.files.isEmpty) {
        return ImportResult(success: false, message: '未选择文件');
      }

      final file = File(result.files.single.path!);
      final content = await file.readAsString(encoding: utf8);

      return await importFromContent(content, overrideCategory: targetCategory);
    } catch (e) {
      return ImportResult(success: false, message: '导入失败: $e');
    }
  }

  /// 解析并导入数据（内部方法 - 保持向后兼容）
  /// 导入单个音效
  Future<ImportResult> _importSingleSound(
    Map<String, dynamic> data,
    String? overrideCategory,
  ) async {
    try {
      final soundData = data['data'] as Map<String, dynamic>;

      // 从嵌入的数据创建音效
      final (sound, error) = await _createSoundFromExportData(soundData);

      if (sound == null) {
        return ImportResult(
          success: false,
          message: '导入音效失败: ${error ?? "无法解析文件数据"}',
        );
      }

      // 如果指定了覆盖分类，使用该分类，否则保持原分类
      var finalSound = sound;
      if (overrideCategory != null) {
        finalSound = sound.copyWith(category: overrideCategory);
      }

      // 确保分类存在
      final settings = SettingsService.instance;
      if (!isSystemCategory(finalSound.category) &&
          !settings.allCategories.contains(finalSound.category)) {
        await settings.addCategory(finalSound.category);
      }

      await _databaseService.insertSound(finalSound);

      return ImportResult(
        success: true,
        message: '成功导入音效: ${sound.name}',
        importedCount: 1,
      );
    } catch (e) {
      return ImportResult(success: false, message: '导入音效失败: $e');
    }
  }

  /// 从导出数据创建音效（解码并保存嵌入的文件）
  /// 返回 (sound, error) 元组，error 为 null 表示成功
  Future<(SoundItem?, String?)> _createSoundFromExportData(
    Map<String, dynamic> soundData,
  ) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final soundId = const Uuid().v4();

      String? soundPath;
      String? imagePath;

      // 解码并保存音频文件
      final soundBase64 = soundData['soundData'] as String?;
      final soundFileName = soundData['soundFileName'] as String?;

      if (soundBase64 != null && soundFileName != null) {
        try {
          final soundBytes = base64Decode(soundBase64);
          final sanitizedName = sanitizeFileName(soundFileName);
          final soundFile = File(
            p.join(
              appDir.path,
              'meme_soundboard',
              'sounds',
              '${timestamp}_${soundId}_$sanitizedName',
            ),
          );
          await soundFile.parent.create(recursive: true);
          await soundFile.writeAsBytes(soundBytes);
          soundPath = soundFile.path;
        } catch (e) {
          return (null, '音频文件解码/保存失败: $e');
        }
      }

      // 解码并保存图片文件
      final imageBase64 = soundData['imageData'] as String?;
      final imageFileName = soundData['imageFileName'] as String?;

      if (imageBase64 != null && imageFileName != null) {
        try {
          final imageBytes = base64Decode(imageBase64);
          final sanitizedName = sanitizeFileName(imageFileName);
          final imageFile = File(
            p.join(
              appDir.path,
              'meme_soundboard',
              'images',
              '${timestamp}_${soundId}_$sanitizedName',
            ),
          );
          await imageFile.parent.create(recursive: true);
          await imageFile.writeAsBytes(imageBytes);
          imagePath = imageFile.path;
        } catch (e) {
          // 图片失败不影响音效导入，只记录警告
          // ignore: avoid_print
          print('图片文件解码/保存失败: $e');
        }
      }

      if (soundPath == null) {
        return (null, '没有有效的音频数据');
      }

      final advSettings =
          soundData['advancedSettings'] as Map<String, dynamic>?;

      return (
        SoundItem(
          id: soundId,
          name: soundData['name'] as String,
          soundPath: soundPath,
          imagePath: imagePath,
          sourceType: SoundSourceType.file,
          category: soundData['category'] as String? ?? '默认',
          isFavorite: soundData['isFavorite'] as bool? ?? false,
          dominantColor: soundData['dominantColor'] != null
              ? Color(soundData['dominantColor'] as int)
              : null,
          advancedSettings: SoundAdvancedSettings(
            volumeLevel:
                (advSettings?['volumeLevel'] as num?)?.toDouble() ?? 1.0,
          ),
        ),
        null,
      );
    } catch (e) {
      return (null, '创建音效失败: $e');
    }
  }

  /// 导入分类
  Future<ImportResult> _importCategory(
    Map<String, dynamic> data,
    String? overrideCategory,
  ) async {
    try {
      final category = data['category'] as String;
      final soundsData = data['data'] as List;

      // 确保分类存在
      final targetCategory = overrideCategory ?? category;
      final settings = SettingsService.instance;
      if (!isSystemCategory(targetCategory) &&
          !settings.allCategories.contains(targetCategory)) {
        await settings.addCategory(targetCategory);
      }

      int importedCount = 0;
      final failedSounds = <String>[];

      for (final soundJson in soundsData) {
        try {
          final (sound, error) = await _createSoundFromExportData(
            soundJson as Map<String, dynamic>,
          );

          if (sound != null) {
            var finalSound = sound.copyWith(category: targetCategory);
            await _databaseService.insertSound(finalSound);
            importedCount++;
          } else {
            failedSounds.add(
              '${soundJson['name'] ?? 'unknown'}: ${error ?? "未知错误"}',
            );
          }
        } catch (e) {
          failedSounds.add('${soundJson['name'] ?? 'unknown'}: $e');
        }
      }

      String message = '成功导入分类 "$targetCategory" 中的 $importedCount 个音效';
      if (failedSounds.isNotEmpty) {
        message +=
            '\n失败 ${failedSounds.length} 个: ${failedSounds.take(3).join("; ")}';
        if (failedSounds.length > 3) message += '...';
      }

      return ImportResult(
        success: importedCount > 0,
        message: message,
        importedCount: importedCount,
      );
    } catch (e) {
      return ImportResult(success: false, message: '导入分类失败: $e');
    }
  }

  /// 导入多个音效
  Future<ImportResult> _importMultipleSounds(
    Map<String, dynamic> data,
    String? overrideCategory,
  ) async {
    try {
      final soundsData = data['sounds'] as List;

      int importedCount = 0;
      final failedSounds = <String>[];
      final settings = SettingsService.instance;

      for (final soundJson in soundsData) {
        try {
          final (sound, error) = await _createSoundFromExportData(
            soundJson as Map<String, dynamic>,
          );

          if (sound != null) {
            var finalSound = sound;

            // 如果指定了覆盖分类，使用该分类
            if (overrideCategory != null) {
              finalSound = sound.copyWith(category: overrideCategory);
            }

            // 确保分类存在
            if (!isSystemCategory(finalSound.category) &&
                !settings.allCategories.contains(finalSound.category)) {
              await settings.addCategory(finalSound.category);
            }

            await _databaseService.insertSound(finalSound);
            importedCount++;
          } else {
            failedSounds.add(
              '${soundJson['name'] ?? 'unknown'}: ${error ?? "未知错误"}',
            );
          }
        } catch (e) {
          failedSounds.add('${soundJson['name'] ?? 'unknown'}: $e');
        }
      }

      String message = '成功导入 $importedCount 个音效';
      if (failedSounds.isNotEmpty) {
        message +=
            '\n失败 ${failedSounds.length} 个: ${failedSounds.take(3).join("; ")}';
        if (failedSounds.length > 3) message += '...';
      }

      return ImportResult(
        success: importedCount > 0,
        message: message,
        importedCount: importedCount,
      );
    } catch (e) {
      return ImportResult(success: false, message: '导入音效失败: $e');
    }
  }

  /// 导入完整备份
  Future<ImportResult> _importFull(
    Map<String, dynamic> data,
    String? overrideCategory,
  ) async {
    try {
      final soundsData = data['sounds'] as List;
      final customCategories = data['customCategories'] as List?;
      final settingsData = data['settings'] as Map<String, dynamic>?;

      // 导入自定义分类
      final settings = SettingsService.instance;
      if (customCategories != null) {
        for (final category in customCategories) {
          final catStr = category as String;
          if (!isSystemCategory(catStr)) {
            await settings.addCategory(catStr);
          }
        }
      }

      // 导入设置（可选）
      if (settingsData != null) {
        if (settingsData['gridColumns'] != null) {
          await settings.setGridColumns(settingsData['gridColumns'] as int);
        }
        if (settingsData['hapticFeedback'] != null) {
          await settings.setHapticFeedback(
            settingsData['hapticFeedback'] as bool,
          );
        }
        if (settingsData['allowMultiPlay'] != null) {
          await settings.setAllowMultiPlay(
            settingsData['allowMultiPlay'] as bool,
          );
        }
      }

      // 导入音效
      int importedCount = 0;
      final failedSounds = <String>[];

      for (final soundJson in soundsData) {
        try {
          final (sound, error) = await _createSoundFromExportData(
            soundJson as Map<String, dynamic>,
          );

          if (sound != null) {
            var finalSound = sound;

            // 如果指定了覆盖分类，使用该分类
            if (overrideCategory != null) {
              finalSound = sound.copyWith(category: overrideCategory);
            }

            // 确保分类存在
            if (!isSystemCategory(finalSound.category) &&
                !settings.allCategories.contains(finalSound.category)) {
              await settings.addCategory(finalSound.category);
            }

            await _databaseService.insertSound(finalSound);
            importedCount++;
          } else {
            failedSounds.add(
              '${soundJson['name'] ?? 'unknown'}: ${error ?? "未知错误"}',
            );
          }
        } catch (e) {
          failedSounds.add('${soundJson['name'] ?? 'unknown'}: $e');
        }
      }

      String message = '成功导入 $importedCount 个音效';
      if (failedSounds.isNotEmpty) {
        message +=
            '\n失败 ${failedSounds.length} 个: ${failedSounds.take(3).join("; ")}';
        if (failedSounds.length > 3) message += '...';
      }

      return ImportResult(
        success: importedCount > 0,
        message: message,
        importedCount: importedCount,
      );
    } catch (e) {
      return ImportResult(success: false, message: '导入备份失败: $e');
    }
  }
}

/// 导入结果
class ImportResult {
  final bool success;
  final String message;
  final int importedCount;

  ImportResult({
    required this.success,
    required this.message,
    this.importedCount = 0,
  });
}
