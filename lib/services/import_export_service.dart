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
import '../l10n/app_localizations.dart';
import '../utils/app_constants.dart';
import '../utils/category_l10n.dart';
import 'database_service.dart';
import 'settings_service.dart';

/// Picked .msb / json file metadata for import UI.
typedef PickedMsbFile = ({
  String content,
  String type,
  String displayName,
  int size,
  DateTime modifiedTime,
});

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
  Future<String?> exportSound(
    SoundItem sound, {
    String? customName,
    AppLocalizations? l10n,
  }) async {
    try {
      final soundData = await _createExportDataWithFiles(sound);

      final exportData = {
        'version': AppConstants.exportVersion,
        'type': 'sound',
        'data': soundData,
        'exportedAt': DateTime.now().toIso8601String(),
      };

      // 使用安全的文件名，避免特殊字符导致的覆盖问题
      final safeName = customName != null ? sanitizeFileName(customName) : sanitizeFileName(sound.name);
      return await _saveExportFile(
        jsonEncode(exportData),
        '$safeName${AppConstants.exportFileExtension}',
        dialogTitle: l10n?.dialogSaveExportLocation,
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
    final soundFile = File(sound.soundPath);
    if (await soundFile.exists()) {
      final bytes = await soundFile.readAsBytes();
      soundBase64 = base64Encode(bytes);
      soundFileName = p.basename(sound.soundPath);
    }

    // 读取并编码图片文件
    if (sound.imagePath != null && !sound.imagePath!.startsWith('http')) {
      // 本地图片文件
      final imageFile = File(sound.imagePath!);
      if (await imageFile.exists()) {
        final bytes = await imageFile.readAsBytes();
        imageBase64 = base64Encode(bytes);
        imageFileName = p.basename(sound.imagePath!);
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
    List<SoundItem> sounds, {
    String? customName,
    AppLocalizations? l10n,
  }) async {
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

      // 改进文件名：使用日期时间戳，避免覆盖
      final now = DateTime.now();
      final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
      final safeCategoryName = customName != null ? sanitizeFileName(customName) : sanitizeFileName(category);
      final filename = customName != null ? '$safeCategoryName${AppConstants.exportFileExtension}' : '${safeCategoryName}_${dateStr}${AppConstants.exportFileExtension}';

      return await _saveExportFile(
        jsonEncode(exportData),
        filename,
        dialogTitle: l10n?.dialogSaveExportLocation,
      );
    } catch (e) {
      debugPrint('导出分类失败: $e');
      rethrow;
    }
  }

  /// 导出所有音效和配置（包含文件内容）
  Future<String?> exportAll(
    List<SoundItem> sounds, {
    String? customName,
    AppLocalizations? l10n,
  }) async {
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

      // 改进文件名：使用日期时间，避免覆盖
      final now = DateTime.now();
      final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
      final backupBase = l10n?.defaultExportBackupName ?? '梗音效备份';
      final safeName = customName != null
          ? sanitizeFileName(customName)
          : '${sanitizeFileName(backupBase)}_$dateStr';
      final filename = '$safeName${AppConstants.exportFileExtension}';

      return await _saveExportFile(
        jsonEncode(exportData),
        filename,
        dialogTitle: l10n?.dialogSaveExportLocation,
      );
    } catch (e) {
      debugPrint('导出全部失败: $e');
      rethrow;
    }
  }

  /// 导出多个选中的音效为一个文件
  Future<String> exportMultipleSounds(
    List<SoundItem> sounds, {
    String? customName,
    AppLocalizations? l10n,
  }) async {
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

    // 改进文件名：使用日期时间和序列号，避免覆盖
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    final multiBase = l10n?.defaultExportMultiName ?? '音效合集';
    final safeName = customName != null
        ? sanitizeFileName(customName)
        : '${sanitizeFileName(multiBase)}_$dateStr';
    final filename = '$safeName${AppConstants.exportFileExtension}';
    final path = await _saveExportFile(
      jsonEncode(exportData),
      filename,
      dialogTitle: l10n?.dialogSaveExportLocation,
    );

    if (path == null) {
      throw Exception(l10n?.exportCancelledException ?? '导出取消');
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
      final docsDir = await getApplicationDocumentsDirectory();
      debugPrint('✓ 使用应用文档目录: ${docsDir.path}');
      return docsDir;
    } catch (e) {
      lastError = '文档目录: $e';
      debugPrint('✗ 应用文档目录失败: $e');
    }

    throw Exception('无法获取存储目录。$lastError');
  }

  /// 获取默认导出目录路径
  Future<String?> getDefaultExportDirectory() async {
    try {
      if (Platform.isAndroid) {
        final dir = await _getAndroidStorageDirectory();
        return dir.path;
      } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        // 在桌面平台，导出到下载目录
        try {
          final dir = await getDownloadsDirectory();
          if (dir != null) {
            return dir.path;
          }
        } catch (e) {
          debugPrint('获取下载目录失败: $e');
        }
        
        // 降级方案：使用文档目录
        try {
          final dir = await getApplicationDocumentsDirectory();
          return dir.path;
        } catch (e) {
          debugPrint('获取文档目录失败: $e');
        }
      }
      return null;
    } catch (e) {
      debugPrint('获取默认导出目录失败: $e');
      return null;
    }
  }

  /// 打开默认导出目录（使用系统文件管理器）
  Future<bool> openDefaultExportDirectory() async {
    try {
      final dirPath = await getDefaultExportDirectory();
      if (dirPath == null) {
        debugPrint('获取导出目录失败');
        return false;
      }

      final dir = Directory(dirPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      debugPrint('尝试打开目录: $dirPath');

      if (Platform.isWindows) {
        // Windows 上使用 explorer /root 打开文件夹
        try {
          await Process.run('explorer.exe', [dirPath]);
          debugPrint('✓ 已打开 Windows 文件管理器');
          return true;
        } catch (e) {
          debugPrint('✗ Windows explorer 失败: $e');
          return false;
        }
      } else if (Platform.isMacOS) {
        // macOS 上使用 open 命令
        try {
          await Process.run('open', [dirPath]);
          debugPrint('✓ 已打开 macOS Finder');
          return true;
        } catch (e) {
          debugPrint('✗ macOS open 失败: $e');
          return false;
        }
      } else if (Platform.isLinux) {
        // Linux 上尝试用 xdg-open
        try {
          await Process.run('xdg-open', [dirPath]);
          debugPrint('✓ 已打开 Linux 文件管理器');
          return true;
        } catch (e) {
          debugPrint('✗ Linux xdg-open 失败: $e');
          return false;
        }
      } else if (Platform.isAndroid) {
        // Android 上使用隐式 Intent
        try {
          await Process.run('am', [
            'start',
            '-a',
            'android.intent.action.VIEW',
            '-d',
            'file://$dirPath',
          ]);
          debugPrint('✓ 已打开 Android 文件管理器');
          return true;
        } catch (e) {
          debugPrint('✗ Android 打开失败: $e');
          return false;
        }
      }
      return false;
    } catch (e) {
      debugPrint('✗ 打开导出目录失败: $e');
      return false;
    }
  }

  /// 保存导出文件（允许用户选择位置）
  Future<String?> _saveExportFile(
    String content,
    String filename, {
    String? dialogTitle,
  }) async {
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
          dialogTitle: dialogTitle ?? '选择导出位置',
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
  Future<ImportResult> importFromFile({AppLocalizations? l10n}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['msb', 'json'],
        dialogTitle: l10n?.dialogPickImportFile ?? '选择导入文件',
      );

      if (result == null || result.files.isEmpty) {
        return ImportResult(
          success: false,
          message: l10n?.importNoFile ?? '未选择文件',
        );
      }

      final file = File(result.files.single.path!);
      final content = await file.readAsString(encoding: utf8);

      return await importFromContent(content, l10n: l10n);
    } catch (e) {
      return ImportResult(
        success: false,
        message: l10n?.importErrorGeneric(e.toString()) ?? '导入失败: $e',
      );
    }
  }

  /// 从指定文件路径导入
  Future<ImportResult> importFromFilePath(
    String filePath, {
    AppLocalizations? l10n,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return ImportResult(
          success: false,
          message: l10n?.importFileMissing ?? '文件不存在',
        );
      }
      final content = await file.readAsString(encoding: utf8);
      return await importFromContent(content, l10n: l10n);
    } catch (e) {
      return ImportResult(
        success: false,
        message: l10n?.importErrorGeneric(e.toString()) ?? '导入失败: $e',
      );
    }
  }

  /// 从 assets 目录导入预制的 .msb 文件（用于导入示例音效包）
  /// [assetPath] - asset 路径，例如 'assets/samples/示例音效包.msb'
  Future<ImportResult> importFromAsset(
    String assetPath, {
    AppLocalizations? l10n,
  }) async {
    try {
      debugPrint('从 asset 导入示例音效包: $assetPath');
      final content = await rootBundle.loadString(assetPath);
      return await importFromContent(content, l10n: l10n);
    } catch (e) {
      debugPrint('从 asset 导入失败: $e');
      return ImportResult(
        success: false,
        message: l10n?.importSampleFailed(e.toString()) ??
            '导入示例音效包失败: $e',
      );
    }
  }

  /// 将预制的示例音效包复制到导出目录（使其出现在"导出文件管理"中）
  Future<bool> copySamplePackToExportDir() async {
    try {
      final exportDir = await getDefaultExportDirectory();
      if (exportDir == null) return false;

      final targetPath = p.join(exportDir, '${AppConstants.samplePackName}${AppConstants.exportFileExtension}');
      final targetFile = File(targetPath);

      // 如果已存在则不重复复制
      if (await targetFile.exists()) {
        debugPrint('示例音效包已存在于导出目录');
        return true;
      }

      // 从 assets 读取并写入
      final content = await rootBundle.loadString(AppConstants.samplePackAssetPath);
      await targetFile.writeAsString(content, encoding: utf8);
      debugPrint('示例音效包已复制到导出目录: $targetPath');
      return true;
    } catch (e) {
      debugPrint('复制示例音效包失败: $e');
      return false;
    }
  }

  /// 从URL导入（支持直接粘贴JSON）
  Future<ImportResult> importFromJson(
    String jsonContent, {
    AppLocalizations? l10n,
  }) async {
    try {
      return await importFromContent(jsonContent, l10n: l10n);
    } catch (e) {
      return ImportResult(
        success: false,
        message: l10n?.importParseFailed(e.toString()) ?? '解析失败: $e',
      );
    }
  }

  /// 打开文件选择器并返回文件内容和类型信息
  Future<PickedMsbFile?> pickFileAndGetType({AppLocalizations? l10n}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['msb', 'json'],
        dialogTitle: l10n?.dialogPickImportFile ?? '选择导入文件',
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final file = File(result.files.single.path!);
      final content = await file.readAsString(encoding: utf8);
      final stat = await file.stat();

      try {
        final Map<String, dynamic> data = jsonDecode(content);
        final type = data['type'] as String? ?? 'unknown';
        return (
          content: content,
          type: type,
          displayName: p.basenameWithoutExtension(file.path),
          size: stat.size,
          modifiedTime: stat.modified,
        );
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
    AppLocalizations? l10n,
  }) async {
    try {
      final Map<String, dynamic> data = jsonDecode(content);

      final version = data['version'] as String?;
      final type = data['type'] as String?;

      if (version == null || type == null) {
        return ImportResult(
          success: false,
          message: l10n?.invalidImportFormat ?? '无效的导入文件格式',
        );
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
          return await _importSingleSound(data, overrideCategory, l10n: l10n);
        case 'category':
          return await _importCategory(data, overrideCategory, l10n: l10n);
        case 'multiple':
          return await _importMultipleSounds(data, overrideCategory, l10n: l10n);
        case 'full':
          return await _importFull(data, overrideCategory, l10n: l10n);
        default:
          return ImportResult(
            success: false,
            message: l10n?.importUnknownType(type) ?? '未知的导入类型: $type',
          );
      }
    } catch (e) {
      return ImportResult(
        success: false,
        message: l10n?.importJsonFailed(e.toString()) ?? 'JSON解析失败: $e',
      );
    }
  }

  /// 导入文件并指定分类
  Future<ImportResult> importFromFileWithCategory(
    String targetCategory, {
    AppLocalizations? l10n,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['msb', 'json'],
        dialogTitle: l10n?.dialogPickImportFile ?? '选择导入文件',
      );

      if (result == null || result.files.isEmpty) {
        return ImportResult(
          success: false,
          message: l10n?.importNoFile ?? '未选择文件',
        );
      }

      final file = File(result.files.single.path!);
      final content = await file.readAsString(encoding: utf8);

      return await importFromContent(
        content,
        overrideCategory: targetCategory,
        l10n: l10n,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        message: l10n?.importErrorGeneric(e.toString()) ?? '导入失败: $e',
      );
    }
  }

  /// 解析并导入数据（内部方法 - 保持向后兼容）
  /// 导入单个音效
  String _failureDetail(List<String> failedSounds) {
    final detail =
        '${failedSounds.take(3).join("; ")}${failedSounds.length > 3 ? "..." : ""}';
    return detail;
  }

  Future<ImportResult> _importSingleSound(
    Map<String, dynamic> data,
    String? overrideCategory, {
    AppLocalizations? l10n,
  }) async {
    try {
      final soundData = data['data'] as Map<String, dynamic>;

      // 从嵌入的数据创建音效
      final (sound, error) = await _createSoundFromExportData(soundData);

      if (sound == null) {
        final detail = error ?? (l10n?.cannotParseSoundData ?? '无法解析文件数据');
        return ImportResult(
          success: false,
          message: l10n?.importSoundFailedWith(detail) ?? '导入音效失败: $detail',
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
        message: l10n?.importSoundSuccessNamed(sound.name) ??
            '成功导入音效: ${sound.name}',
        importedCount: 1,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        message: l10n?.importSoundFailedWith(e.toString()) ?? '导入音效失败: $e',
      );
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
    String? overrideCategory, {
    AppLocalizations? l10n,
  }) async {
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
              '${soundJson['name'] ?? 'unknown'}: ${error ?? (l10n?.unknownError ?? "未知错误")}',
            );
          }
        } catch (e) {
          failedSounds.add('${soundJson['name'] ?? 'unknown'}: $e');
        }
      }

      String message = l10n != null
          ? l10n.successImportCategoryCount(
              l10n.categoryLabelForStored(targetCategory),
              importedCount,
            )
          : '成功导入分类 "$targetCategory" 中的 $importedCount 个音效';
      if (failedSounds.isNotEmpty) {
        message += l10n != null
            ? l10n.importFailuresLine(
                failedSounds.length,
                _failureDetail(failedSounds),
              )
            : '\n失败 ${failedSounds.length} 个: ${_failureDetail(failedSounds)}';
      }

      return ImportResult(
        success: importedCount > 0,
        message: message,
        importedCount: importedCount,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        message: l10n?.importCategoryFailedWith(e.toString()) ??
            '导入分类失败: $e',
      );
    }
  }

  /// 导入多个音效
  Future<ImportResult> _importMultipleSounds(
    Map<String, dynamic> data,
    String? overrideCategory, {
    AppLocalizations? l10n,
  }) async {
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
              '${soundJson['name'] ?? 'unknown'}: ${error ?? (l10n?.unknownError ?? "未知错误")}',
            );
          }
        } catch (e) {
          failedSounds.add('${soundJson['name'] ?? 'unknown'}: $e');
        }
      }

      String message = l10n?.successImportCount(importedCount) ??
          '成功导入 $importedCount 个音效';
      if (failedSounds.isNotEmpty) {
        message += l10n != null
            ? l10n.importFailuresLine(
                failedSounds.length,
                _failureDetail(failedSounds),
              )
            : '\n失败 ${failedSounds.length} 个: ${_failureDetail(failedSounds)}';
      }

      return ImportResult(
        success: importedCount > 0,
        message: message,
        importedCount: importedCount,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        message: l10n?.importSoundFailedWith(e.toString()) ?? '导入音效失败: $e',
      );
    }
  }

  /// 导入完整备份
  Future<ImportResult> _importFull(
    Map<String, dynamic> data,
    String? overrideCategory, {
    AppLocalizations? l10n,
  }) async {
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
              '${soundJson['name'] ?? 'unknown'}: ${error ?? (l10n?.unknownError ?? "未知错误")}',
            );
          }
        } catch (e) {
          failedSounds.add('${soundJson['name'] ?? 'unknown'}: $e');
        }
      }

      String message = l10n?.successImportCount(importedCount) ??
          '成功导入 $importedCount 个音效';
      if (failedSounds.isNotEmpty) {
        message += l10n != null
            ? l10n.importFailuresLine(
                failedSounds.length,
                _failureDetail(failedSounds),
              )
            : '\n失败 ${failedSounds.length} 个: ${_failureDetail(failedSounds)}';
      }

      return ImportResult(
        success: importedCount > 0,
        message: message,
        importedCount: importedCount,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        message: l10n?.importBackupFailedWith(e.toString()) ?? '导入备份失败: $e',
      );
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
