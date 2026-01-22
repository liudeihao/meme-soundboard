import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:palette_generator/palette_generator.dart';
import '../models/sound_item.dart';
import '../utils/app_constants.dart';

/// 文件服务 - 管理用户导入的文件
class FileService {
  static const _uuid = Uuid();

  // 支持的音频格式
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

  /// 验证文件是否为支持的音频格式
  static bool isValidAudioFormat(String filePath) {
    final extension = path
        .extension(filePath)
        .toLowerCase()
        .replaceFirst('.', '');
    return AppConstants.supportedAudioFormats.contains(extension);
  }

  /// 获取支持的音频格式描述
  static String getSupportedFormatsText() {
    return AppConstants.getSupportedFormatsText();
  }

  /// 获取应用私有存储目录
  Future<Directory> get _appDir async {
    final dir = await getApplicationDocumentsDirectory();
    final soundDir = Directory(
      path.join(dir.path, AppConstants.appDataDir, AppConstants.soundsDir),
    );
    if (!await soundDir.exists()) {
      await soundDir.create(recursive: true);
    }
    return soundDir;
  }

  /// 获取缩略图存储目录
  Future<Directory> get _thumbnailDir async {
    final dir = await getApplicationDocumentsDirectory();
    final thumbDir = Directory(
      path.join(dir.path, AppConstants.appDataDir, AppConstants.imagesDir),
    );
    if (!await thumbDir.exists()) {
      await thumbDir.create(recursive: true);
    }
    return thumbDir;
  }

  /// 从 assets 导入内置音效文件到应用私有目录
  Future<SoundItem> importBuiltInSound(SoundItem builtInSound) async {
    try {
      final appDir = await _appDir;
      final thumbDir = await _thumbnailDir;

      // 复制音频文件
      final audioAssetPath = 'assets/${builtInSound.soundPath}';
      final audioData = await rootBundle.load(audioAssetPath);
      final audioExtension = path.extension(builtInSound.soundPath);
      final newAudioPath = path.join(
        appDir.path,
        '${builtInSound.id}$audioExtension',
      );
      final audioFile = File(newAudioPath);
      await audioFile.writeAsBytes(audioData.buffer.asUint8List());

      // 复制图片文件（如果存在）
      String? newImagePath;
      if (builtInSound.imagePath != null) {
        try {
          final imageAssetPath = 'assets/${builtInSound.imagePath}';
          final imageData = await rootBundle.load(imageAssetPath);
          final imageExtension = path.extension(builtInSound.imagePath!);
          newImagePath = path.join(
            thumbDir.path,
            '${builtInSound.id}$imageExtension',
          );
          final imageFile = File(newImagePath);
          await imageFile.writeAsBytes(imageData.buffer.asUint8List());
        } catch (e) {
          debugPrint('复制内置音效图片失败: $e');
        }
      }

      // 返回修改后的音效对象（使用文件路径而不是 asset 路径）
      return builtInSound.copyWith(
        soundPath: newAudioPath,
        imagePath: newImagePath ?? builtInSound.imagePath,
        sourceType: SoundSourceType.file,
      );
    } catch (e) {
      debugPrint('导入内置音效失败: $e');
      rethrow;
    }
  }

  /// 选择并导入音频文件
  Future<SoundItem?> importSound({String? customName}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    if (file.path == null) return null;

    // 验证文件格式
    if (!isValidAudioFormat(file.path!)) {
      final supportedFormats = getSupportedFormatsText();
      throw Exception('不支持的音频格式。请使用以下格式之一：$supportedFormats');
    }

    final id = _uuid.v4();
    final appDir = await _appDir;
    final extension = path.extension(file.path!);
    final newSoundPath = path.join(appDir.path, '$id$extension');

    // 复制文件到应用私有目录
    await File(file.path!).copy(newSoundPath);

    final name = customName ?? path.basenameWithoutExtension(file.name);

    return SoundItem(
      id: id,
      name: name,
      soundPath: newSoundPath,
      sourceType: SoundSourceType.file,
      category: '导入',
    );
  }

  /// 从 Content-Type 获取音频格式
  static String? _getAudioFormatFromContentType(String contentType) {
    final lowerType = contentType.toLowerCase();

    // 支持的 Content-Type 映射
    final contentTypeMap = {
      'audio/mpeg': 'mp3',
      'audio/mp3': 'mp3',
      'audio/wav': 'wav',
      'audio/wave': 'wav',
      'audio/x-wav': 'wav',
      'audio/aac': 'aac',
      'audio/mp4': 'm4a',
      'audio/x-m4a': 'm4a',
      'audio/flac': 'flac',
      'audio/x-flac': 'flac',
      'audio/ogg': 'ogg',
      'audio/vorbis': 'ogg',
      'audio/x-vorbis': 'ogg',
      'audio/x-vorbis+ogg': 'ogg',
      'audio/x-ms-wma': 'wma',
      'audio/aiff': 'aiff',
      'audio/x-aiff': 'aiff',
    };

    // 直接匹配
    if (contentTypeMap.containsKey(lowerType)) {
      return contentTypeMap[lowerType];
    }

    // 模糊匹配（处理参数等）
    for (final entry in contentTypeMap.entries) {
      if (lowerType.startsWith(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }

  /// 从 URL 下载并缓存音频文件
  Future<String> downloadAndCacheAudio(String audioUrl) async {
    try {
      // 验证 URL 格式
      if (!audioUrl.startsWith('http://') && !audioUrl.startsWith('https://')) {
        throw Exception('无效的 URL：必须以 http:// 或 https:// 开头');
      }

      final appDir = await _appDir;
      final fileName = _uuid.v4();

      debugPrint('🔗 开始下载音频: $audioUrl');

      // 下载文件
      final response = await http
          .get(
            Uri.parse(audioUrl),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            },
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('下载超时：服务器响应时间过长（>30秒），请检查网络或 URL'),
          );

      if (response.statusCode != 200) {
        throw Exception('服务器返回错误：HTTP ${response.statusCode}');
      }

      if (response.bodyBytes.isEmpty) {
        throw Exception('下载的文件为空');
      }

      // 首先尝试从 Content-Type 获取格式
      String? extension;
      String? audioFormat;

      final contentType = response.headers['content-type'] ?? '';
      if (contentType.isNotEmpty) {
        audioFormat = _getAudioFormatFromContentType(contentType);
        if (audioFormat != null) {
          extension = '.$audioFormat';
        }
      }

      // 如果无法从 Content-Type 获取，尝试从 URL 获取扩展名
      if (extension == null) {
        try {
          final uri = Uri.parse(audioUrl);
          final pathSegments = uri.path.split('/');
          if (pathSegments.isNotEmpty) {
            final lastSegment = pathSegments.last;
            if (lastSegment.contains('.')) {
              final ext = lastSegment.split('.').last;
              if (ext.isNotEmpty && ext.length <= 5) {
                extension = '.' + ext.toLowerCase();
                audioFormat = ext.toLowerCase();
              }
            }
          }
        } catch (e) {
          debugPrint('无法从 URL 获取扩展名: $e');
        }
      }

      // 如果仍然无法确定格式，拒绝下载
      if (extension == null || audioFormat == null) {
        throw Exception(
          '无法识别音频格式。请确保您提供的是直接的音频文件链接（如：https://example.com/song.mp3），而不是网页链接',
        );
      }

      // 验证扩展名是否为支持的音频格式
      if (!supportedAudioFormats.contains(audioFormat)) {
        throw Exception(
          '不支持的音频格式：$extension。请使用以下格式之一：${getSupportedFormatsText()}',
        );
      }

      final localPath = path.join(appDir.path, '$fileName$extension');

      // 保存到本地
      final file = File(localPath);
      await file.writeAsBytes(response.bodyBytes);

      debugPrint('✅ 音频下载成功: $localPath');
      return localPath;
    } catch (e) {
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      debugPrint('❌ 下载音频失败: $errorMsg');
      rethrow; // 抛出异常而不是返回null，以便调用者能够处理
    }
  }

  /// 从 URL 下载并缓存图片文件
  Future<String?> downloadAndCacheImage(String imageUrl, String soundId) async {
    try {
      final thumbDir = await _thumbnailDir;

      // 尝试从 URL 获取文件扩展名
      String? extension;
      try {
        final uri = Uri.parse(imageUrl);
        final pathSegments = uri.path.split('/');
        if (pathSegments.isNotEmpty) {
          final lastSegment = pathSegments.last;
          if (lastSegment.contains('.')) {
            extension = '.' + lastSegment.split('.').last;
          }
        }
      } catch (e) {
        debugPrint('无法从 URL 获取扩展名: $e');
      }

      extension ??= '.jpg'; // 默认为 jpg

      final localPath = path.join(thumbDir.path, '$soundId$extension');

      // 下载文件
      final response = await http
          .get(
            Uri.parse(imageUrl),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            },
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception('下载超时：图片下载时间过长'),
          );

      if (response.statusCode != 200) {
        throw Exception('下载失败：HTTP ${response.statusCode}');
      }

      if (response.bodyBytes.isEmpty) {
        throw Exception('下载失败：图片为空');
      }

      // 保存到本地
      final file = File(localPath);
      await file.writeAsBytes(response.bodyBytes);

      debugPrint('图片下载成功: $localPath');
      return localPath;
    } catch (e) {
      debugPrint('下载图片失败: $e');
      return null;
    }
  }

  /// 选择并导入图片（作为音效封面）
  Future<String?> importImage(String soundId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    if (file.path == null) return null;

    final thumbDir = await _thumbnailDir;
    final extension = path.extension(file.path!);
    final newImagePath = path.join(thumbDir.path, '$soundId$extension');

    // 复制并可选压缩图片
    await File(file.path!).copy(newImagePath);

    return newImagePath;
  }

  /// 从图片提取主色调
  Future<Color?> extractDominantColor(
    String imagePath, {
    bool isAsset = false,
  }) async {
    try {
      ImageProvider imageProvider;

      if (isAsset) {
        imageProvider = AssetImage(imagePath);
      } else {
        imageProvider = FileImage(File(imagePath));
      }

      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        imageProvider,
        size: const Size(100, 100), // 使用小尺寸加快处理
        maximumColorCount: 5,
      );

      return paletteGenerator.dominantColor?.color ??
          paletteGenerator.vibrantColor?.color ??
          paletteGenerator.mutedColor?.color;
    } catch (e) {
      debugPrint('提取颜色失败: $e');
      return null;
    }
  }

  /// 导入 ZIP 包（包含 cover.jpg 和 sound.mp3）
  Future<SoundItem?> importZipPackage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return null;

    // TODO: 解压 ZIP 并提取文件
    // 这里需要添加 archive 包来处理 ZIP 文件

    return null;
  }

  /// 删除导入的文件
  Future<void> deleteImportedFile(SoundItem sound) async {
    try {
      final soundFile = File(sound.soundPath);
      if (await soundFile.exists()) {
        await soundFile.delete();
      }

      if (sound.imagePath != null) {
        final imageFile = File(sound.imagePath!);
        if (await imageFile.exists()) {
          await imageFile.delete();
        }
      }
    } catch (e) {
      debugPrint('删除文件失败: $e');
    }
  }

  /// 复制音频文件到应用私有目录
  Future<String?> copyAudioFile(String sourcePath, String newId) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        return null;
      }

      final appDir = await _appDir;
      final extension = path.extension(sourcePath);
      final newPath = path.join(appDir.path, '$newId$extension');

      // 只有当新路径与源路径不同时才复制
      if (newPath != sourcePath) {
        await sourceFile.copy(newPath);
        debugPrint('音频文件复制成功: $sourcePath -> $newPath');
        return newPath;
      }
      return sourcePath;
    } catch (e) {
      debugPrint('复制音频文件失败: $e');
      return null;
    }
  }

  /// 复制图片文件到应用缩略图目录
  Future<String?> copyImageFile(String sourcePath, String newId) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        return null;
      }

      final thumbDir = await _thumbnailDir;
      final extension = path.extension(sourcePath);
      final newPath = path.join(thumbDir.path, '$newId$extension');

      // 只有当新路径与源路径不同时才复制
      if (newPath != sourcePath) {
        await sourceFile.copy(newPath);
        debugPrint('图片文件复制成功: $sourcePath -> $newPath');
        return newPath;
      }
      return sourcePath;
    } catch (e) {
      debugPrint('复制图片文件失败: $e');
      return null;
    }
  }

  /// 检查文件是否存在
  Future<bool> fileExists(String filePath) async {
    return await File(filePath).exists();
  }

  /// 获取存储使用情况
  Future<int> getStorageUsage() async {
    final appDir = await _appDir;
    final thumbDir = await _thumbnailDir;

    int totalSize = 0;

    await for (final entity in appDir.list(recursive: true)) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }

    await for (final entity in thumbDir.list(recursive: true)) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }

    return totalSize;
  }

  /// 保存音频文件到用户选择的位置
  Future<String?> saveAudioToUserLocation(SoundItem sound) async {
    try {
      final sourcePath = sound.soundPath;
      final sourceFile = File(sourcePath);

      if (!await sourceFile.exists()) {
        debugPrint('源音频文件不存在: $sourcePath');
        return null;
      }

      // 获取原始文件扩展名
      final extension = path.extension(sourcePath);
      final suggestedName = '${sound.name}$extension';

      // 让用户选择保存位置
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: '保存音频文件',
        fileName: suggestedName,
        type: FileType.audio,
      );

      if (outputPath == null) return null;

      // 确保输出路径有正确的扩展名
      String finalPath = outputPath;
      if (!finalPath.toLowerCase().endsWith(extension.toLowerCase())) {
        finalPath = '$outputPath$extension';
      }

      // 复制文件
      await sourceFile.copy(finalPath);
      debugPrint('✅ 音频保存成功: $finalPath');
      return finalPath;
    } catch (e) {
      debugPrint('❌ 保存音频文件失败: $e');
      rethrow;
    }
  }

  /// 保存图片文件到用户选择的位置
  Future<String?> saveImageToUserLocation(SoundItem sound) async {
    try {
      if (sound.imagePath == null) {
        debugPrint('音效没有封面图片');
        return null;
      }

      final sourcePath = sound.imagePath!;
      final sourceFile = File(sourcePath);

      if (!await sourceFile.exists()) {
        debugPrint('源图片文件不存在: $sourcePath');
        return null;
      }

      // 获取原始文件扩展名
      final extension = path.extension(sourcePath);
      final suggestedName = '${sound.name}$extension';

      // 让用户选择保存位置
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: '保存封面图片',
        fileName: suggestedName,
        type: FileType.image,
      );

      if (outputPath == null) return null;

      // 确保输出路径有正确的扩展名
      String finalPath = outputPath;
      if (!finalPath.toLowerCase().endsWith(extension.toLowerCase())) {
        finalPath = '$outputPath$extension';
      }

      // 复制文件
      await sourceFile.copy(finalPath);
      debugPrint('✅ 图片保存成功: $finalPath');
      return finalPath;
    } catch (e) {
      debugPrint('❌ 保存图片文件失败: $e');
      rethrow;
    }
  }
}
