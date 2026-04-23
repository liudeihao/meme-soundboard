import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../models/sound_item.dart';
import '../services/audio_service.dart';
import '../services/audio_trim_service.dart';
import '../services/database_service.dart';
import '../services/file_service.dart';
import '../services/external_import_bridge.dart';
import '../services/import_export_service.dart';
import '../services/settings_service.dart';
import '../utils/app_constants.dart';
import '../utils/category_l10n.dart';
import '../l10n/app_localizations.dart';
import '../widgets/sound_button.dart';
import '../widgets/category_selector.dart';
import '../widgets/search_bar.dart' as custom;
import '../widgets/add_sound_dialog.dart';
import '../widgets/msb_import_preview_dialog.dart';
import '../widgets/sound_bottom_sheet.dart';
import 'settings_screen.dart';
import 'export_manager_screen.dart';

/// 主屏幕 - Bento Grid 布局的音效板
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final AudioService _audioService = AudioService();
  final DatabaseService _databaseService = DatabaseService();
  final FileService _fileService = FileService();
  late final ImportExportService _importExportService;

  List<SoundItem> _allSounds = [];
  List<SoundItem> _filteredSounds = [];
  String _selectedCategory = '全部';
  String _searchQuery = '';
  bool _isLoading = true;

  // 多选模式
  bool _isSelectionMode = false;
  Set<String> _selectedSoundIds = {}; // 使用音效ID跟踪选中项

  // 用于双击返回退出应用
  DateTime? _lastBackPressTime;

  late AnimationController _fabAnimationController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ExternalImportBridge.listenAndroidPush(_onAndroidImportPathPushed);
    _importExportService = ImportExportService(_databaseService);
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // 从设置中获取启动时显示的分类
    _selectedCategory = SettingsService.instance.startupCategory;

    _initializeSounds();

    // 监听播放错误
    _audioService.playError.addListener(_onPlayError);

    // 监听设置变化（例如网格列数变化）
    SettingsService.instance.addListener(_onSettingsChanged);
  }

  void _onSettingsChanged() {
    debugPrint('⚙️ 设置已更改: gridColumns=${SettingsService.instance.gridColumns}');
    setState(() {
      // 设置变化时重新构建 UI
    });
  }

  /// 切换排序模式
  void _onPlayError() {
    final error = _audioService.playError.value;
    if (error != null && mounted) {
      final bottomSheetHeight = _isSelectionMode && _selectedSoundIds.isNotEmpty ? 80.0 : 0.0;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.link_off_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(error)),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(16, 0, 16, bottomSheetHeight + 16),
        ),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ExternalImportBridge.clearAndroidPush();
    _audioService.playError.removeListener(_onPlayError);
    _fabAnimationController.dispose();
    SettingsService.instance.removeListener(_onSettingsChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_tryConsumeAndroidExternalImportOnResume());
    }
  }

  void _onAndroidImportPathPushed(String path) {
    unawaited(_importExternalAndRefresh(path));
  }

  /// Cold start / resume: consume intent stored before Flutter was ready.
  Future<void> _tryConsumeAndroidExternalImportOnResume() async {
    final path = await ExternalImportBridge.consumePendingAndroidPath();
    if (path != null && path.isNotEmpty && mounted) {
      await _importExternalAndRefresh(path);
    }
  }

  /// Import opened file; caller is responsible for DB list refresh when embedded in init.
  Future<bool> _tryConsumeAndroidExternalImport({
    bool showSnackOnFailure = true,
  }) async {
    final path = await ExternalImportBridge.consumePendingAndroidPath();
    if (path == null || path.isEmpty) return false;
    return _importExternalPack(path, showSnackOnFailure: showSnackOnFailure);
  }

  Future<void> _importExternalAndRefresh(String path) async {
    final ok = await _importExternalPack(path, showSnackOnFailure: true);
    if (ok && mounted) {
      await _initializeSounds();
    }
  }

  /// Returns true if import succeeded (same steps as menu「导入音效」).
  Future<bool> _importExternalPack(
    String path, {
    required bool showSnackOnFailure,
  }) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        if (showSnackOnFailure && mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.importFileMissing),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            ),
          );
        }
        return false;
      }

      final content = await file.readAsString(encoding: utf8);
      final Map<String, dynamic> data;
      try {
        data = jsonDecode(content) as Map<String, dynamic>;
      } catch (_) {
        if (showSnackOnFailure && mounted) {
          _showSnackBar(
            AppLocalizations.of(context)!.notValidPackFile,
            backgroundColor: Colors.red,
          );
        }
        return false;
      }

      final type = data['type'] as String? ?? 'unknown';
      final version = data['version'] as String?;
      if (version == null || type == 'unknown') {
        if (showSnackOnFailure && mounted) {
          _showSnackBar(
            AppLocalizations.of(context)!.invalidImportFormat,
            backgroundColor: Colors.red,
          );
        }
        return false;
      }

      final stat = await file.stat();
      if (!mounted) return false;

      final confirmed = await MsbImportPreviewDialog.show(
        context,
        displayName: p.basenameWithoutExtension(path),
        json: data,
        sizeBytes: stat.size,
        modifiedTime: stat.modified,
      );
      if (!confirmed || !mounted) return false;

      return _continueMsbImportFlow(content, type);
    } catch (e) {
      if (showSnackOnFailure && mounted) {
        final l10n = AppLocalizations.of(context)!;
        _showSnackBar(l10n.importFailed(e.toString()), backgroundColor: Colors.red);
      }
      return false;
    }
  }

  /// After preview: category / backup dialogs and import (returns whether DB import succeeded).
  Future<bool> _continueMsbImportFlow(String fileContent, String fileType) async {
    switch (fileType) {
      case 'sound':
      case 'multiple':
        return _showImportCategoryDialog(fileContent, fileType);
      case 'category':
        return _showCategoryImportOptionsDialog(fileContent);
      case 'full':
        return _showFullBackupImportDialog(fileContent);
      default:
        if (mounted) {
          _showSnackBar(
            AppLocalizations.of(context)!.unknownFileType,
            backgroundColor: Colors.red,
          );
        }
        return false;
    }
  }

  /// 初始化音效列表
  Future<void> _initializeSounds() async {
    setState(() => _isLoading = true);

    try {
      debugPrint('========== 开始初始化音效 ==========');

      // 确保示例音效包已复制到导出目录（静默执行，不影响启动）
      _importExportService.copySamplePackToExportDir().then((success) {
        if (success) {
          debugPrint('示例音效包已准备就绪');
        }
      }).catchError((e) {
        debugPrint('复制示例音效包失败（非致命错误）: $e');
      });

      // 加载数据库中的音效
      var dbSounds = await _databaseService.getAllSounds();
      debugPrint('数据库中的音效数量: ${dbSounds.length}');

      // 检查是否有旧的资源路径（包含 'assets/' 前缀）
      final hasOldAssetPaths = dbSounds.any(
        (s) => s.isAsset && s.soundPath.startsWith('assets/'),
      );

      if (hasOldAssetPaths) {
        debugPrint('检测到旧的资源路径格式，清空数据库重新初始化...');
        await _databaseService.clearAllSounds();
        dbSounds = [];
      }

      // 检查数据库中的音效是否需要迁移分类
      // 如果有分类为空的音效，需要迁移到"默认"分类
      final hasEmptyCategories = dbSounds.any((s) => s.category.isEmpty);
      if (hasEmptyCategories) {
        debugPrint('检测到旧的分类格式，正在迁移...');
        for (final sound in dbSounds) {
          if (sound.category.isEmpty) {
            final migratedSound = sound.copyWith(category: '默认');
            await _databaseService.updateSound(migratedSound);
            final index = dbSounds.indexWhere((s) => s.id == sound.id);
            if (index != -1) {
              dbSounds[index] = migratedSound;
            }
          }
        }
        debugPrint('分类迁移完成');
      }

      // 检查数据库中的音效是否需要重新初始化
      // 如果所有音效都是 asset 类型，说明是旧版本数据，需要清空
      final allAreAssets = dbSounds.every((s) => s.isAsset);
      if (dbSounds.isNotEmpty && allAreAssets) {
        debugPrint('检测到旧的内置音效格式，清空数据库...');
        await _databaseService.clearAllSounds();
        dbSounds = [];
      }

      // Other apps (e.g. QQ) open .msb via VIEW / SEND before first frame
      await _tryConsumeAndroidExternalImport(showSnackOnFailure: true);
      dbSounds = await _databaseService.getAllSounds();

      _allSounds = dbSounds;
      debugPrint('使用数据库中的音效');

      // 首次启动时显示示例音效导入对话框
      if (_allSounds.isEmpty &&
          !SettingsService.instance.hasImportedDefaults &&
          mounted) {
        debugPrint('首次启动，显示示例音效导入对话框...');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showImportSamplesDialog();
        });
        await SettingsService.instance.markDefaultsImported();
      }

      debugPrint('当前音效总数: ${_allSounds.length}');

      // 验证启动分类是否有效
      _validateSelectedCategory();

      // 预加载内置音效 (仅当有内置资源时)
      final assetSounds = _allSounds.where((s) => s.isAsset).toList();
      debugPrint('Asset 音效数量: ${assetSounds.length}');

      debugPrint('过滤后的音效数量: ${_filteredSounds.length}');
      debugPrint('========== 初始化完成 ==========');
    } catch (e, stackTrace) {
      debugPrint('初始化音效失败: $e');
      debugPrint('堆栈跟踪: $stackTrace');
      // 回退到空列表
      _allSounds = [];
    } finally {
      setState(() {
        _isLoading = false;
        // 更新过滤后的列表
        _filteredSounds = _allSounds.where((sound) {
          // 分类过滤
          bool categoryMatch = true;
          if (_selectedCategory == '收藏') {
            categoryMatch = sound.isFavorite;
          } else if (_selectedCategory != '全部') {
            categoryMatch = sound.category == _selectedCategory;
          }

          // 搜索过滤
          bool searchMatch = true;
          if (_searchQuery.isNotEmpty) {
            searchMatch = sound.name.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
          }

          return categoryMatch && searchMatch;
        }).toList();
      });
    }
  }

  /// 验证当前选择的分类是否有效
  void _validateSelectedCategory() {
    final allCategories = SettingsService.instance.allCategories;
    if (!allCategories.contains(_selectedCategory)) {
      // 如果当前分类不存在（例如用户删除了分类），回退到"全部"
      _selectedCategory = '全部';
      debugPrint('启动分类无效，回退到"全部"');
    }
  }

  /// 播放音效
  Future<void> _playSound(SoundItem sound) async {
    await _audioService.play(sound);
  }

  /// 切换收藏状态
  Future<void> _toggleFavorite(SoundItem sound) async {
    final newFavorite = !sound.isFavorite;
    await _databaseService.toggleFavorite(sound.id, newFavorite);

    setState(() {
      final index = _allSounds.indexWhere((s) => s.id == sound.id);
      if (index != -1) {
        _allSounds[index] = _allSounds[index].copyWith(isFavorite: newFavorite);
      }
      // 更新过滤后的列表
      _filteredSounds = _allSounds.where((sound) {
        // 分类过滤
        bool categoryMatch = true;
        if (_selectedCategory == '收藏') {
          categoryMatch = sound.isFavorite;
        } else if (_selectedCategory != '全部') {
          categoryMatch = sound.category == _selectedCategory;
        }

        // 搜索过滤
        bool searchMatch = true;
        if (_searchQuery.isNotEmpty) {
          searchMatch = sound.name.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
        }

        return categoryMatch && searchMatch;
      }).toList();
    });

    final l10n = AppLocalizations.of(context)!;
    _showSnackBar(
      newFavorite ? l10n.toastFavoriteAdded : l10n.toastFavoriteRemoved,
      duration: const Duration(seconds: 1),
    );
  }

  /// 显示音效详情底部弹窗
  void _showSoundOptions(SoundItem sound) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SoundBottomSheet(
        sound: sound,
        onPlay: () => _playSound(sound),
        onToggleFavorite: () => _toggleFavorite(sound),
        onEdit: () => _editSound(sound),
        onDelete: () => _deleteSound(sound),
        onExport: () {
          // Navigator.pop 已在 SoundBottomSheet 内部处理
          _showExportSingleDialog(sound);
        },
        onSaveAudio: () {
          // Navigator.pop 已在 SoundBottomSheet 内部处理
          _showSaveAudioDialog(sound);
        },
        onSaveImage: sound.imagePath != null
            ? () {
                // Navigator.pop 已在 SoundBottomSheet 内部处理
                _showSaveImageDialog(sound);
              }
            : null,
        onShowDetails: () {
          _showSoundDetails(sound);
        },
      ),
    );
  }

  /// 显示音效详情
  void _showSoundDetails(SoundItem sound) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(102),
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Colors.blueGrey),
            const SizedBox(width: 8),
            Expanded(child: Text(sound.name, overflow: TextOverflow.ellipsis)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(l10n.detailName, sound.name),
              _buildDetailRow(
                l10n.detailCategory,
                l10n.categoryLabelForStored(sound.category),
              ),
              _buildDetailRow(
                l10n.detailFavorite,
                sound.isFavorite ? l10n.favoriteYes : l10n.favoriteNo,
              ),
              _buildDetailRow(
                l10n.detailSourceType,
                sound.sourceType == SoundSourceType.asset
                    ? l10n.sourceTypeBuiltin
                    : sound.sourceType == SoundSourceType.file
                    ? l10n.sourceTypeLocalFile
                    : l10n.sourceTypeNetwork,
              ),
              if (sound.soundPath.isNotEmpty)
                _buildDetailRow(
                  l10n.detailSoundPath,
                  sound.soundPath.length > 50
                      ? '...${sound.soundPath.substring(sound.soundPath.length - 50)}'
                      : sound.soundPath,
                  fullPath: sound.soundPath,
                ),
              if (sound.imagePath != null)
                _buildDetailRow(
                  l10n.detailImagePath,
                  sound.imagePath!.length > 50
                      ? '...${sound.imagePath!.substring(sound.imagePath!.length - 50)}'
                      : sound.imagePath!,
                  fullPath: sound.imagePath!,
                ),
              _buildDetailRow('ID', sound.id),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {String? fullPath}) {
    final isClickable = fullPath != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: isClickable ? () => _copyToClipboard(fullPath) : null,
              child: Text(
                value,
                style: TextStyle(
                  height: 1.3,
                  color: isClickable ? Colors.blue : null,
                  decoration: isClickable ? TextDecoration.underline : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 复制到剪切板
  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      _showSnackBarWithIcon(
        AppLocalizations.of(context)!.clipboardCopied,
        Icons.check_rounded,
      );
    }
  }

  /// 添加新音效
  Future<void> _addNewSound() async {
    final l10n = AppLocalizations.of(context)!;
    String? tempSoundPath;
    String? tempImagePath;
    Color? dominantColor;

    // 显示添加对话框
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddSoundDialog(
        onSelectAudio: () async {
          try {
            final sound = await _fileService.importSound();
            if (sound != null) {
              // 返回一个对象，包含显示用的文件名和真实的音频路径
              return {'displayName': sound.name, 'soundPath': sound.soundPath};
            }
            return null;
          } catch (e) {
            throw Exception(e.toString());
          }
        },
        onSelectImage: () async {
          final path = await _fileService.importImage(
            'temp_${DateTime.now().millisecondsSinceEpoch}',
          );
          if (path != null) {
            tempImagePath = path;
            dominantColor = await _fileService.extractDominantColor(path);
            return path;
          }
          return null;
        },
        onConfirm:
            (
              name,
              category,
              soundPath,
              imagePath,
              sourceType,
              advSettings,
              trimRange,
            ) async {
              // 预先生成新音效的 ID，用于关联音频和图片文件
              final newSoundId =
                  'user_${DateTime.now().millisecondsSinceEpoch}';

              var effectiveSoundPath = soundPath ?? tempSoundPath;
              if (effectiveSoundPath == null) {
                throw Exception(l10n.exceptionPickAudioFirst);
              }

              // 如果是 URL 音效，先下载并保存到本地
              if (sourceType == SoundSourceType.url) {
                try {
                  final downloaded = await _fileService.downloadAndCacheAudio(
                    effectiveSoundPath,
                  );
                  effectiveSoundPath = downloaded;
                } catch (e) {
                  final errorMsg = e.toString().replaceFirst('Exception: ', '');
                  throw Exception(l10n.downloadAudioFailed(errorMsg));
                }
              }

              if (trimRange != null && trimRange.isValid) {
                final total =
                    await AudioTrimService.probeDuration(effectiveSoundPath);
                if (total != null &&
                    total > Duration.zero &&
                    !trimRange.isEffectivelyFull(total)) {
                  final dir = await _fileService.getUserSoundsDirectoryPath();
                  final outPath = p.join(dir, '${Uuid().v4()}.m4a');
                  var start = trimRange.start;
                  var end = trimRange.end;
                  if (start < Duration.zero) start = Duration.zero;
                  if (end > total) end = total;
                  if (end - start >= const Duration(milliseconds: 200)) {
                    try {
                      await AudioTrimService.trimToFile(
                        inputPath: effectiveSoundPath,
                        outputPath: outPath,
                        start: start,
                        end: end,
                      );
                      try {
                        final f = File(effectiveSoundPath);
                        if (await f.exists() && f.path != outPath) {
                          await f.delete();
                        }
                      } catch (_) {}
                      effectiveSoundPath = outPath;
                    } catch (e) {
                      final msg =
                          e.toString().replaceFirst('Exception: ', '');
                      throw Exception(l10n.audioTrimFailed(msg));
                    }
                  }
                }
              }

              var effectiveImagePath = imagePath ?? tempImagePath;

              // 如果是 URL 图片，先下载并保存到本地
              if (effectiveImagePath != null &&
                  (effectiveImagePath.startsWith('http://') ||
                      effectiveImagePath.startsWith('https://'))) {
                try {
                  final downloaded = await _fileService.downloadAndCacheImage(
                    effectiveImagePath,
                    newSoundId,
                  );
                  if (downloaded != null) {
                    effectiveImagePath = downloaded;
                    dominantColor = await _fileService.extractDominantColor(
                      effectiveImagePath,
                    );
                  }
                  // 图片下载失败时不报错，继续使用 null
                } catch (e) {
                  debugPrint('下载图片失败: $e');
                  effectiveImagePath = null;
                }
              }

              final newSound = SoundItem(
                id: newSoundId,
                name: name,
                soundPath: effectiveSoundPath,
                imagePath: effectiveImagePath,
                sourceType: sourceType == SoundSourceType.url
                    ? SoundSourceType.file
                    : sourceType,
                category: category,
                dominantColor: dominantColor,
                advancedSettings: advSettings,
              );

              await _databaseService.insertSound(newSound);

              setState(() {
                _allSounds.insert(0, newSound);
                // 更新过滤后的列表
                _filteredSounds = _allSounds.where((sound) {
                  // 分类过滤
                  bool categoryMatch = true;
                  if (_selectedCategory == '收藏') {
                    categoryMatch = sound.isFavorite;
                  } else if (_selectedCategory != '全部') {
                    categoryMatch = sound.category == _selectedCategory;
                  }

                  // 搜索过滤
                  bool searchMatch = true;
                  if (_searchQuery.isNotEmpty) {
                    searchMatch = sound.name.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    );
                  }

                  return categoryMatch && searchMatch;
                }).toList();
              });
            },
      ),
    );

    if (result == true && mounted) {
      _showSnackBar(AppLocalizations.of(context)!.soundAddedSuccess);
    }
  }

  /// 编辑音效
  Future<void> _editSound(SoundItem sound) async {
    String? newImagePath;
    Color? newDominantColor;

    await showDialog<bool>(
      context: context,
      builder: (context) => AddSoundDialog(
        existingSound: sound,
        onSelectImage: () async {
          final path = await _fileService.importImage(sound.id);
          if (path != null) {
            newImagePath = path;
            newDominantColor = await _fileService.extractDominantColor(path);
            return path;
          }
          return null;
        },
        onConfirm:
            (name, category, _, imagePath, sourceType, advSettings, _) async {
              var effectiveImagePath =
                  imagePath ?? newImagePath ?? sound.imagePath;

              // 如果图片是 URL，下载并保存到本地
              if (effectiveImagePath != null &&
                  (effectiveImagePath.startsWith('http://') ||
                      effectiveImagePath.startsWith('https://'))) {
                try {
                  final downloaded = await _fileService.downloadAndCacheImage(
                    effectiveImagePath,
                    sound.id,
                  );
                  if (downloaded != null) {
                    effectiveImagePath = downloaded;
                    newDominantColor = await _fileService.extractDominantColor(
                      effectiveImagePath,
                    );
                  }
                  // 图片下载失败时不报错，继续使用原值
                } catch (e) {
                  debugPrint('下载图片失败: $e');
                }
              }

              final updatedSound = sound.copyWith(
                name: name,
                category: category,
                imagePath: effectiveImagePath,
                dominantColor: newDominantColor ?? sound.dominantColor,
                advancedSettings: advSettings,
              );

              await _databaseService.updateSound(updatedSound);

              setState(() {
                final index = _allSounds.indexWhere((s) => s.id == sound.id);
                if (index != -1) {
                  _allSounds[index] = updatedSound;
                }
                // 更新过滤后的列表
                _filteredSounds = _allSounds.where((sound) {
                  // 分类过滤
                  bool categoryMatch = true;
                  if (_selectedCategory == '收藏') {
                    categoryMatch = sound.isFavorite;
                  } else if (_selectedCategory != '全部') {
                    categoryMatch = sound.category == _selectedCategory;
                  }

                  // 搜索过滤
                  bool searchMatch = true;
                  if (_searchQuery.isNotEmpty) {
                    searchMatch = sound.name.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    );
                  }

                  return categoryMatch && searchMatch;
                }).toList();
              });
            },
      ),
    );
  }

  /// 删除音效
  Future<void> _deleteSound(SoundItem sound) async {
    // 从数据库删除
    await _databaseService.deleteSound(sound.id);
    
    // 删除文件
    await _fileService.deleteImportedFile(sound);

    setState(() {
      _allSounds.removeWhere((s) => s.id == sound.id);
      // 更新过滤后的列表
      _filteredSounds = _allSounds.where((s) {
        // 分类过滤
        bool categoryMatch = true;
        if (_selectedCategory == '收藏') {
          categoryMatch = s.isFavorite;
        } else if (_selectedCategory != '全部') {
          categoryMatch = s.category == _selectedCategory;
        }

        // 搜索过滤
        bool searchMatch = true;
        if (_searchQuery.isNotEmpty) {
          searchMatch = s.name.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
        }

        return categoryMatch && searchMatch;
      }).toList();
    });

    if (mounted) {
      _showSnackBar(AppLocalizations.of(context)!.soundDeleted);
    }
  }

  /// 处理返回键按下事件
  void _handleBackPressed() {
    // 如果在多选模式，先退出多选
    if (_isSelectionMode) {
      setState(() {
        _isSelectionMode = false;
        _selectedSoundIds.clear();
      });
      return;
    }

    // 否则处理双击返回退出应用
    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      
      if (mounted) {
        _showSnackBar(
          AppLocalizations.of(context)!.pressAgainToExit,
          duration: const Duration(seconds: 2),
        );
      }
    } else {
      // 两次按下时间间隔小于2秒，退出应用
      exit(0);
    }
  }

  /// 显示SnackBar提示信息，确保不被遮挡
  void _showSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 2),
    Color? backgroundColor,
    SnackBarAction? action,
  }) {
    if (!mounted) return;

    // 清除所有之前的 SnackBar
    ScaffoldMessenger.of(context).clearSnackBars();

    // 计算bottomSheet的高度
    final bottomSheetHeight = _isSelectionMode && _selectedSoundIds.isNotEmpty ? 80.0 : 0.0;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(16, 0, 16, bottomSheetHeight + 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: backgroundColor,
        action: action,
        dismissDirection: DismissDirection.down,
      ),
    );
  }

  /// 显示带图标的SnackBar（用于复制等操作）
  void _showSnackBarWithIcon(
    String message,
    IconData icon, {
    Duration duration = const Duration(seconds: 1),
    Color? backgroundColor,
  }) {
    if (!mounted) return;

    // 清除所有之前的 SnackBar
    ScaffoldMessenger.of(context).clearSnackBars();

    final bottomSheetHeight = _isSelectionMode && _selectedSoundIds.isNotEmpty ? 80.0 : 0.0;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(16, 0, 16, bottomSheetHeight + 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: backgroundColor,
        dismissDirection: DismissDirection.down,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _handleBackPressed();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // 顶部标题栏
              _buildAppBar(theme, l10n),

              // 搜索栏
              custom.SearchBar(
                hintText: l10n.searchHint,
                onSearch: (query) {
                  setState(() {
                    _searchQuery = query;
                    // 更新过滤后的列表
                    _filteredSounds = _allSounds.where((sound) {
                      // 分类过滤
                      bool categoryMatch = true;
                      if (_selectedCategory == '收藏') {
                        categoryMatch = sound.isFavorite;
                      } else if (_selectedCategory != '全部') {
                        categoryMatch = sound.category == _selectedCategory;
                      }

                      // 搜索过滤
                      bool searchMatch = true;
                      if (_searchQuery.isNotEmpty) {
                        searchMatch = sound.name.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        );
                      }

                      return categoryMatch && searchMatch;
                    }).toList();
                  });
                },
              onClear: () {
                setState(() {
                  _searchQuery = '';
                  // 更新过滤后的列表
                  _filteredSounds = _allSounds.where((sound) {
                    // 分类过滤
                    bool categoryMatch = true;
                    if (_selectedCategory == '收藏') {
                      categoryMatch = sound.isFavorite;
                    } else if (_selectedCategory != '全部') {
                      categoryMatch = sound.category == _selectedCategory;
                    }

                    // 搜索过滤
                    bool searchMatch = true;
                    if (_searchQuery.isNotEmpty) {
                      searchMatch = sound.name.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      );
                    }

                    return categoryMatch && searchMatch;
                  }).toList();
                });
              },
            ),

            // 分类选择器
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 12),
              child: CategorySelector(
                selectedCategory: _selectedCategory,
                onCategorySelected: (category) {
                  setState(() {
                    _selectedCategory = category;
                    _filteredSounds = _allSounds.where((sound) {
                      // 分类过滤
                      bool categoryMatch = true;
                      if (_selectedCategory == '收藏') {
                        categoryMatch = sound.isFavorite;
                      } else if (_selectedCategory != '全部') {
                        categoryMatch = sound.category == _selectedCategory;
                      }

                      // 搜索过滤
                      bool searchMatch = true;
                      if (_searchQuery.isNotEmpty) {
                        searchMatch = sound.name.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        );
                      }

                      return categoryMatch && searchMatch;
                    }).toList();
                  });
                },
              ),
            ),

            // 音效网格
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredSounds.isEmpty
                  ? _buildEmptyState()
                  : _buildSoundGridWithRefresh(),
            ),
          ],
        ),
        ),
        floatingActionButton: _buildFAB(theme),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomSheet: _isSelectionMode && _selectedSoundIds.isNotEmpty
            ? _buildSelectionBottomSheet(theme)
            : null,
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
      child: Row(
        children: [
          // Logo/标题
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.primaryColor, theme.primaryColor.withAlpha(179)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withAlpha(77),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.music_note_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.appTitle,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  l10n.soundCount(_allSounds.length),
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withAlpha(153),
                  ),
                ),
              ],
            ),
          ),
          // 停止所有播放按钮
          ValueListenableBuilder<String?>(
            valueListenable: _audioService.currentlyPlaying,
            builder: (context, currentlyPlaying, child) {
              if (currentlyPlaying == null) return const SizedBox.shrink();

              return IconButton(
                onPressed: () {
                  _audioService.stopAll();
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(26),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.stop_rounded, color: Colors.red),
                ),
                tooltip: l10n.stopAllSounds,
              );
            },
          ),
          // 导入导出菜单
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              color: theme.colorScheme.onSurface.withAlpha(179),
            ),
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'selection_mode',
                child: ListTile(
                  leading: Icon(
                    _isSelectionMode
                        ? Icons.check_box_rounded
                        : Icons.select_all_rounded,
                  ),
                  title: Text(
                    _isSelectionMode ? l10n.exitMultiSelect : l10n.multiSelect,
                  ),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'import',
                child: ListTile(
                  leading: const Icon(Icons.file_download_rounded),
                  title: Text(l10n.importSounds),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              PopupMenuItem(
                value: 'export_all',
                child: ListTile(
                  leading: const Icon(Icons.file_upload_rounded),
                  title: Text(l10n.exportAll),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              PopupMenuItem(
                value: 'export_category',
                child: ListTile(
                  leading: const Icon(Icons.file_upload_rounded),
                  title: Text(l10n.exportCurrentCategory),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'export_manager',
                child: ListTile(
                  leading: const Icon(Icons.folder_open_rounded),
                  title: Text(l10n.exportManagerTitle),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: const Icon(Icons.settings_rounded),
                  title: Text(l10n.settings),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleMenuAction(String action) async {
    switch (action) {
      case 'selection_mode':
        setState(() {
          _isSelectionMode = !_isSelectionMode;
          if (!_isSelectionMode) {
            _selectedSoundIds.clear();
          }
        });
        break;
      case 'import':
        await _handleImport();
        break;
      case 'export_all':
        await _showExportAllDialog();
        break;
      case 'export_category':
        await _showExportCategoryDialog();
        break;
      case 'export_manager':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExportManagerScreen(
              onDataChanged: _initializeSounds,
            ),
          ),
        );
        break;
      case 'settings':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                SettingsScreen(onDataChanged: _initializeSounds),
          ),
        );
        break;
    }
  }

  /// 通用分类选择对话框 - 复用于多个导入流程
  Future<String?> _showSelectCategoryDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final validCategories = [
      AppConstants.categoryDefault,
      ...SettingsService.instance.customCategories,
    ];
    String selectedCategory = AppConstants.categoryDefault;
    bool showNewCategoryInput = false;
    final newCategoryController = TextEditingController();

    if (!mounted) return null;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.selectImportCategory),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!showNewCategoryInput) ...[
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      labelText: l10n.pickCategory,
                      prefixIcon: const Icon(Icons.folder_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: validCategories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(l10n.categoryLabelForStored(category)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedCategory = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      setDialogState(() => showNewCategoryInput = true);
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l10n.newCategory),
                  ),
                ] else ...[
                  TextField(
                    controller: newCategoryController,
                    decoration: InputDecoration(
                      labelText: l10n.newCategoryName,
                      hintText: l10n.newCategoryHint,
                      prefixIcon: const Icon(Icons.create_new_folder_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setDialogState(
                              () => showNewCategoryInput = false,
                            );
                            newCategoryController.clear();
                          },
                          child: Text(l10n.cancel),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            final newCategory = newCategoryController.text
                                .trim();
                            if (newCategory.isNotEmpty) {
                              Navigator.pop(context, newCategory);
                            }
                          },
                          child: Text(l10n.confirm),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, selectedCategory),
              child: Text(l10n.continueLabel),
            ),
          ],
        ),
      ),
    );

    return result;
  }

  Future<void> _handleImport() async {
    final l10n = AppLocalizations.of(context)!;
    final fileInfo = await _importExportService.pickFileAndGetType(l10n: l10n);
    if (fileInfo == null) {
      return;
    }

    if (!mounted) return;

    final json = jsonDecode(fileInfo.content) as Map<String, dynamic>;
    final confirmed = await MsbImportPreviewDialog.show(
      context,
      displayName: fileInfo.displayName,
      json: json,
      sizeBytes: fileInfo.size,
      modifiedTime: fileInfo.modifiedTime,
    );
    if (!confirmed || !mounted) return;

    await _continueMsbImportFlow(fileInfo.content, fileInfo.type);
  }

  /// 显示导入分类选择对话框（用于单个和多个音效）
  Future<bool> _showImportCategoryDialog(
    String fileContent,
    String fileType,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final validCategories = [
      AppConstants.categoryDefault,
      ...SettingsService.instance.customCategories,
    ];

    if (!mounted) return false;

    final selectedCategory = await _showSelectCategoryDialog();
    if (selectedCategory == null) return false;

    if (selectedCategory != AppConstants.categoryDefault &&
        !validCategories.contains(selectedCategory)) {
      await SettingsService.instance.addCategory(selectedCategory);
    }

    final result = await _importExportService.importFromContent(
      fileContent,
      overrideCategory: selectedCategory,
      l10n: l10n,
    );

    if (mounted) {
      _showSnackBar(
        result.message,
        backgroundColor: result.success ? Colors.green : Colors.red,
      );
      if (result.success) {
        await _initializeSounds();
      }
    }
    return result.success;
  }

  /// 显示分类导入选项对话框
  Future<bool> _showCategoryImportOptionsDialog(String fileContent) async {
    if (!mounted) return false;

    final l10n = AppLocalizations.of(context)!;
    final validCategories = [
      AppConstants.categoryDefault,
      ...SettingsService.instance.customCategories,
    ];

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.chooseImportMethod),
        content: Text(l10n.howImportCategory),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'keep'),
            child: Text(l10n.keepOriginalCategory),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'select'),
            child: Text(l10n.pickNewCategory),
          ),
        ],
      ),
    );

    if (result == null) return false;

    if (result == 'keep') {
      final importResult = await _importExportService.importFromContent(
        fileContent,
        overrideCategory: null,
        l10n: l10n,
      );
      if (mounted) {
        _showSnackBar(
          importResult.message,
          backgroundColor: importResult.success ? Colors.green : Colors.red,
        );
        if (importResult.success) {
          await _initializeSounds();
        }
      }
      return importResult.success;
    }

    final selectedCategory = await _showSelectCategoryDialog();
    if (selectedCategory == null) return false;

    if (selectedCategory != AppConstants.categoryDefault &&
        !validCategories.contains(selectedCategory)) {
      await SettingsService.instance.addCategory(selectedCategory);
    }

    final importResult = await _importExportService.importFromContent(
      fileContent,
      overrideCategory: selectedCategory,
      l10n: l10n,
    );

    if (mounted) {
      _showSnackBar(
        importResult.message,
        backgroundColor: importResult.success ? Colors.green : Colors.red,
      );
      if (importResult.success) {
        await _initializeSounds();
      }
    }
    return importResult.success;
  }

  /// 显示完整备份导入对话框
  Future<bool> _showFullBackupImportDialog(String fileContent) async {
    if (!mounted) return false;

    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.importFullBackupTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.importFullBackupBody),
            const SizedBox(height: 12),
            Text(l10n.importFullBackupChoose),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'add'),
            child: Text(l10n.mergeIntoExisting),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'replace'),
            child: Text(l10n.replaceAllData),
          ),
        ],
      ),
    );

    if (result == null) return false;

    if (result == 'replace') {
      if (!mounted) return false;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.confirmReplaceTitle),
          content: Text(l10n.confirmReplaceBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.confirmReplace),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) return false;

      if (!mounted) return false;
      final finalConfirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.finalConfirmTitle),
          content: Text(l10n.finalConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: Text(l10n.confirmReplaceAll),
            ),
          ],
        ),
      );

      if (finalConfirmed != true || !mounted) return false;

      final importResult = await _importExportService.importFromContent(
        fileContent,
        clearFirst: true,
        l10n: l10n,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(importResult.message),
            backgroundColor: importResult.success ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        if (importResult.success) {
          await _initializeSounds();
        }
      }
      return importResult.success;
    }

    final importResult = await _importExportService.importFromContent(
      fileContent,
      l10n: l10n,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(importResult.message),
          backgroundColor: importResult.success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (importResult.success) {
        await _initializeSounds();
      }
    }
    return importResult.success;
  }

  /// 显示全部导出名称对话框
  /// 通用导出名称输入对话框
  Future<String?> _showExportNameDialog({String defaultName = ''}) async {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: defaultName);
    
    if (!mounted) return null;

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.exportNameTitle),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: l10n.exportNameHint,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                Navigator.pop(context, nameController.text);
              }
            },
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  Future<void> _showExportAllDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final exportName =
        await _showExportNameDialog(defaultName: l10n.defaultExportBackupName);
    if (exportName != null) {
      await _handleExportAll(customName: exportName);
    }
  }

  Future<void> _handleExportAll({String? customName}) async {
    final l10n = AppLocalizations.of(context)!;
    if (_allSounds.isEmpty) {
      _showSnackBar(l10n.noSoundsToExport);
      return;
    }

    try {
      final path = await _importExportService.exportAll(
        _allSounds,
        customName: customName,
        l10n: l10n,
      );
      if (mounted) {
        _showSnackBar(
          path != null ? l10n.exportSuccessFullBackup : l10n.exportCancelled,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          l10n.exportFailedWith(e.toString()),
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  /// 显示分类导出名称对话框
  Future<void> _showExportCategoryDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final exportName = await _showExportNameDialog(
      defaultName: l10n.categoryLabelForStored(_selectedCategory),
    );
    if (exportName != null) {
      await _handleExportCategory(customName: exportName);
    }
  }

  Future<void> _handleExportCategory({String? customName}) async {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedCategory == AppConstants.categoryAll) {
      if (customName != null) {
        await _handleExportAll(customName: customName);
      } else {
        await _showExportAllDialog();
      }
      return;
    }

    final categorySounds = _allSounds
        .where(
          (s) => _selectedCategory == AppConstants.categoryFavorites
              ? s.isFavorite
              : s.category == _selectedCategory,
        )
        .toList();

    if (categorySounds.isEmpty) {
      _showSnackBar(l10n.currentCategoryEmpty);
      return;
    }

    try {
      final path = await _importExportService.exportCategory(
        _selectedCategory,
        categorySounds,
        customName: customName,
        l10n: l10n,
      );
      if (mounted) {
        _showSnackBar(
          path != null ? l10n.exportSuccessCategory : l10n.exportCancelled,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          l10n.exportFailedWith(e.toString()),
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  /// 显示多选导出选项
  Future<void> _showExportOptions(List<SoundItem> sounds) async {
    if (sounds.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.archive_rounded),
                title: Text(l10n.pickExportZip),
                subtitle: Text(l10n.pickExportZipSubtitle(sounds.length)),
                onTap: () async {
                  Navigator.pop(context);
                  await _showMultiSelectExportNameDialog(sounds, asZip: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder_rounded),
                title: Text(l10n.pickExportSeparate),
                subtitle: Text(l10n.pickExportSeparateSubtitle(sounds.length)),
                onTap: () async {
                  Navigator.pop(context);
                  await _exportMultipleSounds(sounds, asZip: false);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 显示多选导出名称输入对话框
  Future<void> _showMultiSelectExportNameDialog(List<SoundItem> sounds, {required bool asZip}) async {
    final exportName = await _showExportNameDialog();
    if (exportName != null) {
      await _exportMultipleSounds(sounds, asZip: asZip, customName: exportName);
    }
  }

  /// 显示示例音效导入对话框
  Future<void> _showImportSamplesDialog() async {
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.onboardingTitle),
        content: Text(l10n.onboardingSampleBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.skip),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _importSamplePack();
            },
            child: Text(l10n.import),
          ),
        ],
      ),
    );
  }

  /// 导入示例音效包（从预制的 .msb 文件导入）
  Future<void> _importSamplePack() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final result = await _importExportService.importFromAsset(
        AppConstants.samplePackAssetPath,
        l10n: l10n,
      );

      await _initializeSounds();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? null : Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.importFailedWith(e.toString())),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 导出多个音效
  Future<void> _exportMultipleSounds(
    List<SoundItem> sounds, {
    required bool asZip,
    String? customName,
  }) async {
    if (sounds.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
    try {
      if (asZip) {
        await _exportSoundsAsZip(sounds, customName: customName);
      } else {
        List<String> successPaths = [];
        for (final sound in sounds) {
          final path = await _importExportService.exportSound(
            sound,
            l10n: l10n,
          );
          if (path != null) {
            successPaths.add(path);
          }
        }

        if (mounted && successPaths.isNotEmpty) {
          _showSnackBar(
            l10n.exportSuccessMultiple(successPaths.length),
            duration: const Duration(seconds: 2),
          );
        } else if (mounted) {
          _showSnackBar(l10n.exportFailed);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          l10n.exportFailedWith(e.toString()),
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  /// 将多个音效导出为压缩包
  Future<void> _exportSoundsAsZip(List<SoundItem> sounds, {String? customName}) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await _importExportService.exportMultipleSounds(
        sounds,
        customName: customName,
        l10n: l10n,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.exportSuccessMultiple(sounds.length)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 导出单个音效为 .msb 文件
  Future<void> _showExportSingleDialog(SoundItem sound) async {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: sound.name);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.exportNameTitle),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: l10n.exportNameHint,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              if (nameController.text.isNotEmpty) {
                await _exportSingleSound(sound, customName: nameController.text);
              }
            },
            child: Text(l10n.export),
          ),
        ],
      ),
    );
  }

  Future<void> _exportSingleSound(SoundItem sound, {String? customName}) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final path = await _importExportService.exportSound(
        sound,
        customName: customName,
        l10n: l10n,
      );
      if (mounted) {
        _showSnackBar(
          path != null ? l10n.exportSuccessSingle : l10n.exportSingleCancelled,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(l10n.exportFailedWith(e.toString()));
      }
    }
  }

  /// 显示保存音频对话框
  Future<void> _showSaveAudioDialog(SoundItem sound) async {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: sound.name);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.saveAudioFileTitle),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: l10n.saveAudioFileHint,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              if (nameController.text.isNotEmpty) {
                await _saveAudioFile(sound, customName: nameController.text);
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  /// 保存封面图片到应用文件夹（自动保存，无需用户自定义名称）
  Future<void> _showSaveImageDialog(SoundItem sound) async {
    await _saveImageFile(sound);
  }

  /// 保存音频文件到用户选择的位置
  Future<void> _saveAudioFile(SoundItem sound, {String? customName}) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final path = await _fileService.saveAudioToUserLocation(sound, customName: customName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              path != null ? l10n.audioSaveSuccess : l10n.saveCancelledGeneric,
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.saveFailedWith(e.toString())),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// 保存封面图片到应用文件夹（自动保存）
  Future<void> _saveImageFile(SoundItem sound) async {
    if (sound.imagePath == null) return;
    final l10n = AppLocalizations.of(context)!;
    try {
      final path = await _fileService.saveImageToUserLocation(sound);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              path != null ? l10n.imageSaveSuccess : l10n.saveCancelledGeneric,
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.saveFailedWith(e.toString())),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildSoundGridWithRefresh() {
    return RefreshIndicator(
      onRefresh: () async {
        await _initializeSounds();
      },
      child: _buildSoundGrid(),
    );
  }

  Widget _buildSoundGrid() {
    // 获取当前网格列数
    final gridColumns = SettingsService.instance.gridColumns;

    return ValueListenableBuilder<String?>(
      valueListenable: _audioService.currentlyPlaying,
      builder: (context, currentlyPlaying, child) {
        return GridView.builder(
          // 使用网格列数作为 Key 的一部分，强制重建
          key: ValueKey('sound_grid_$gridColumns'),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: gridColumns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: _filteredSounds.length,
          itemBuilder: (context, index) {
            final sound = _filteredSounds[index];
            final isSelected = _selectedSoundIds.contains(sound.id);

            if (_isSelectionMode) {
              // 选择模式下显示带复选框的音效
              return Stack(
                children: [
                  GestureDetector(
                    onTap: () => setState(() {
                      if (isSelected) {
                        _selectedSoundIds.remove(sound.id);
                      } else {
                        _selectedSoundIds.add(sound.id);
                      }
                    }),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: isSelected
                            ? Border.all(
                                color: Theme.of(context).primaryColor,
                                width: 3,
                              )
                            : null,
                        color: isSelected
                            ? Theme.of(context).primaryColor.withAlpha(26)
                            : null,
                      ),
                      child: SoundButton(
                        sound: sound,
                        isPlaying: currentlyPlaying == sound.id,
                        onTap: () => setState(() {
                          if (isSelected) {
                            _selectedSoundIds.remove(sound.id);
                          } else {
                            _selectedSoundIds.add(sound.id);
                          }
                        }),
                        onLongPress: () {},
                        onDoubleTap: () {},
                      ),
                    ),
                  ),
                  // 复选框（可点击区域）
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        if (isSelected) {
                          _selectedSoundIds.remove(sound.id);
                        } else {
                          _selectedSoundIds.add(sound.id);
                        }
                      }),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).primaryColor,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(26),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          width: 28,
                          height: 28,
                          child: isSelected
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            } else {
              // 正常模式
              return SoundButton(
                sound: sound,
                isPlaying: currentlyPlaying == sound.id,
                onTap: () => _playSound(sound),
                onLongPress: () => _showSoundOptions(sound),
                onDoubleTap: () => _toggleFavorite(sound),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _selectedCategory == AppConstants.categoryFavorites
                ? Icons.favorite_border_rounded
                : Icons.music_off_rounded,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            _selectedCategory == AppConstants.categoryFavorites
                ? l10n.emptyFavorites
                : _searchQuery.isNotEmpty
                ? l10n.emptySearch
                : l10n.emptyCategory,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 8),
          if (_selectedCategory != AppConstants.categoryFavorites)
            TextButton.icon(
              onPressed: _addNewSound,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.addSoundButton),
            ),
        ],
      ),
    );
  }

  /// 构建多选模式的底部操作栏
  Widget _buildSelectionBottomSheet(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    final selectedCount = _selectedSoundIds.length;
    final selectedSounds = _filteredSounds
        .where((sound) => _selectedSoundIds.contains(sound.id))
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // 选中数量和全选
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      l10n.selectedCount(selectedCount),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (selectedCount < _filteredSounds.length) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => setState(() {
                        _selectedSoundIds.clear();
                        for (final sound in _filteredSounds) {
                          _selectedSoundIds.add(sound.id);
                        }
                      }),
                      child: Text(
                        l10n.selectAll,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // 导出按钮
            FilledButton.icon(
              onPressed: selectedSounds.isEmpty
                  ? null
                  : () => _showExportOptions(selectedSounds),
              icon: const Icon(Icons.download_rounded, size: 18),
              label: Text(l10n.export),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 移动到分类按钮
            FilledButton.icon(
              onPressed: selectedSounds.isEmpty
                  ? null
                  : () => _showMoveToCategory(selectedSounds),
              icon: const Icon(Icons.folder_open_rounded, size: 18),
              label: Text(l10n.move),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 删除按钮
            FilledButton.icon(
              onPressed: selectedSounds.isEmpty
                  ? null
                  : () => _showDeleteConfirmation(selectedSounds),
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: Text(l10n.delete),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示移动到分类的对话框
  void _showMoveToCategory(List<SoundItem> sounds) {
    final l10n = AppLocalizations.of(context)!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) {
        List<String> validCategories = [
          AppConstants.categoryDefault,
          ...SettingsService.instance.customCategories,
        ];
        String? currentSelected = validCategories.first;
        bool showNewCategoryInput = false;
        final newCategoryController = TextEditingController();

        return StatefulBuilder(
          builder: (statefulContext, setDialogState) {
            // 在 setDialogState 后重新构建时，validCategories 会被重新初始化
            return AlertDialog(
              title: Text(l10n.moveToCategoryTitle),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!showNewCategoryInput) ...[
                      DropdownButtonFormField<String>(
                        value: currentSelected,
                        decoration: InputDecoration(
                          labelText: l10n.pickCategory,
                          prefixIcon: const Icon(Icons.folder_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: validCategories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(l10n.categoryLabelForStored(category)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => currentSelected = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      // 新建分类按钮
                      OutlinedButton.icon(
                        onPressed: () {
                          setDialogState(() => showNewCategoryInput = true);
                        },
                        icon: const Icon(Icons.add_rounded),
                        label: Text(l10n.newCategory),
                      ),
                    ] else ...[
                      TextField(
                        controller: newCategoryController,
                        decoration: InputDecoration(
                          labelText: l10n.newCategoryName,
                          hintText: l10n.newCategoryHint,
                          prefixIcon: const Icon(
                            Icons.create_new_folder_rounded,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setDialogState(
                                  () => showNewCategoryInput = false,
                                );
                                newCategoryController.clear();
                              },
                              child: Text(l10n.cancel),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton(
                              onPressed: () async {
                                final newCategory = newCategoryController.text
                                    .trim();
                                if (newCategory.isNotEmpty) {
                                  await SettingsService.instance.addCategory(
                                    newCategory,
                                  );
                                  setDialogState(() {
                                    validCategories = [
                                      AppConstants.categoryDefault,
                                      ...SettingsService
                                          .instance
                                          .customCategories,
                                    ];
                                    currentSelected = newCategory;
                                    showNewCategoryInput = false;
                                    newCategoryController.clear();
                                  });
                                }
                              },
                              child: Text(l10n.confirm),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(statefulContext),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: currentSelected == null || currentSelected!.isEmpty
                      ? null
                      : () async {
                          final targetCategory = currentSelected!;

                          if (!validCategories.contains(targetCategory)) {
                            await SettingsService.instance.addCategory(
                              targetCategory,
                            );
                          }

                          for (final sound in sounds) {
                            final updated = sound.copyWith(
                              category: targetCategory,
                            );
                            await _databaseService.updateSound(updated);
                          }

                          setState(() {
                            for (final sound in sounds) {
                              final index = _allSounds.indexWhere((s) => s.id == sound.id);
                              if (index != -1) {
                                _allSounds[index] = sound.copyWith(category: targetCategory);
                              }
                            }
                            
                            _filteredSounds = _allSounds.where((sound) {
                              bool categoryMatch = true;
                              if (_selectedCategory == AppConstants.categoryFavorites) {
                                categoryMatch = sound.isFavorite;
                              } else if (_selectedCategory != AppConstants.categoryAll) {
                                categoryMatch = sound.category == _selectedCategory;
                              }

                              bool searchMatch = true;
                              if (_searchQuery.isNotEmpty) {
                                searchMatch = sound.name.toLowerCase().contains(
                                  _searchQuery.toLowerCase(),
                                );
                              }

                              return categoryMatch && searchMatch;
                            }).toList();
                            
                            _selectedSoundIds.clear();
                            _isSelectionMode = false;
                          });

                          if (!mounted) return;
                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext);
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                l10n.movedSoundsToCategory(
                                  sounds.length,
                                  l10n.categoryLabelForStored(targetCategory),
                                ),
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                  child: Text(l10n.confirm),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 显示删除确认对话框
  void _showDeleteConfirmation(List<SoundItem> sounds) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDeleteSoundsTitle),
        content: Text(l10n.confirmDeleteSoundsBody(sounds.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              for (final sound in sounds) {
                await _databaseService.deleteSound(sound.id);
              }

              final remainingSounds = await _databaseService.getAllSounds();
              if (remainingSounds.isEmpty) {
                await SettingsService.instance.resetDefaultsImported();
              }

              setState(() {
                _selectedSoundIds.clear();
                _isSelectionMode = false;
              });
              await _initializeSounds();
              if (mounted) {
                _showSnackBar(l10n.deletedSoundsCount(sounds.length));
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB(ThemeData theme) {
    // 在多选模式下，将FAB向上调整，避免被底部操作栏遮挡
    final fabMarginBottom = _isSelectionMode && _selectedSoundIds.isNotEmpty ? 100.0 : 16.0;
    
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(bottom: fabMarginBottom - 16.0),
      child: FloatingActionButton.extended(
        onPressed: _addNewSound,
        backgroundColor: theme.primaryColor,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          l10n.fabAdd,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
