import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/sound_item.dart';
import '../services/audio_service.dart';
import '../services/database_service.dart';
import '../services/file_service.dart';
import '../services/import_export_service.dart';
import '../services/settings_service.dart';
import '../utils/built_in_sounds.dart';
import '../widgets/sound_button.dart';
import '../widgets/category_selector.dart';
import '../widgets/search_bar.dart' as custom;
import '../widgets/add_sound_dialog.dart';
import '../widgets/sound_bottom_sheet.dart';
import 'settings_screen.dart';

/// 主屏幕 - Bento Grid 布局的音效板
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
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

  // 用于撤销删除
  SoundItem? _lastDeletedSound;

  late AnimationController _fabAnimationController;

  @override
  void initState() {
    super.initState();
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
        ),
      );
    }
  }

  @override
  void dispose() {
    _audioService.playError.removeListener(_onPlayError);
    _fabAnimationController.dispose();
    SettingsService.instance.removeListener(_onSettingsChanged);
    super.dispose();
  }

  /// 初始化音效列表
  Future<void> _initializeSounds() async {
    setState(() => _isLoading = true);

    try {
      debugPrint('========== 开始初始化音效 ==========');

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

      // 检查内置音效
      debugPrint('内置音效数量: ${BuiltInSounds.all.length}');
      for (final sound in BuiltInSounds.all) {
        debugPrint('内置音效: ${sound.name}, 路径: ${sound.soundPath}');
      }

      // 检查数据库中的音效是否需要迁移分类
      // 如果有分类为空的内置音效，需要迁移到"默认"分类
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
      // 如果所有内置音效都是 asset 类型，说明需要从 assets 复制到私有目录
      final allAreAssets = dbSounds.every((s) => s.isAsset);
      final needsReinitialization =
          dbSounds.isNotEmpty && allAreAssets && BuiltInSounds.all.isNotEmpty;

      if (needsReinitialization) {
        debugPrint('检测到旧的内置音效格式，清空数据库...');
        await _databaseService.clearAllSounds();
        dbSounds = [];
      }

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

    // 显示反馈
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(newFavorite ? '已添加到收藏' : '已取消收藏'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
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
          _exportSingleSound(sound);
        },
        onSaveAudio: () {
          _saveAudioFile(sound);
        },
        onSaveImage: sound.imagePath != null
            ? () {
                _saveImageFile(sound);
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
              _buildDetailRow('名称', sound.name),
              _buildDetailRow('分类', sound.category),
              _buildDetailRow('收藏', sound.isFavorite ? '是' : '否'),
              _buildDetailRow(
                '来源类型',
                sound.sourceType == SoundSourceType.asset
                    ? '内置资源'
                    : sound.sourceType == SoundSourceType.file
                    ? '本地文件'
                    : '网络链接',
              ),
              if (sound.soundPath.isNotEmpty)
                _buildDetailRow(
                  '音频路径',
                  sound.soundPath.length > 50
                      ? '...${sound.soundPath.substring(sound.soundPath.length - 50)}'
                      : sound.soundPath,
                  fullPath: sound.soundPath,
                ),
              if (sound.imagePath != null)
                _buildDetailRow(
                  '图片路径',
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
            child: const Text('关闭'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('已复制到剪切板'),
            ],
          ),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// 添加新音效
  Future<void> _addNewSound() async {
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
            ) async {
              // 预先生成新音效的 ID，用于关联音频和图片文件
              final newSoundId =
                  'user_${DateTime.now().millisecondsSinceEpoch}';

              var effectiveSoundPath = soundPath ?? tempSoundPath;
              if (effectiveSoundPath == null) {
                throw Exception('请先选择音频文件或输入链接');
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
                  throw Exception('下载音频失败:\n$errorMsg');
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('音效添加成功！'),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
            (name, category, _, imagePath, sourceType, advSettings) async {
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
    // 保存最后删除的音效用于撤销（注意：不立即删除文件）
    _lastDeletedSound = sound;

    // 先从数据库删除（用户可以在 SnackBar 显示期间撤销）
    await _databaseService.deleteSound(sound.id);

    setState(() {
      _allSounds.removeWhere((s) => s.id == sound.id);
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

    if (mounted) {
      final snackBar = ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('音效已删除'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: '撤销',
            onPressed: () async {
              await _undoDeleteSound();
            },
          ),
        ),
      );

      // 如果用户没有点击撤销，5秒后删除文件
      snackBar.closed.then((reason) {
        if (_lastDeletedSound?.id == sound.id && mounted) {
          // 用户没有点击撤销，删除文件
          _fileService.deleteImportedFile(sound);
          _lastDeletedSound = null;
        }
      });
    }
  }

  /// 撤销删除音效
  Future<void> _undoDeleteSound() async {
    if (_lastDeletedSound == null) return;

    try {
      // 恢复数据库记录
      await _databaseService.insertSound(_lastDeletedSound!);

      setState(() {
        _allSounds.insert(0, _lastDeletedSound!);
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

      _lastDeletedSound = null; // 清除保存的数据

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已恢复音效'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('撤销删除失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('撤销失败，请重试'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 顶部标题栏
            _buildAppBar(theme),

            // 搜索栏
            custom.SearchBar(
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
      bottomSheet: _isSelectionMode && _selectedSoundIds.isNotEmpty
          ? _buildSelectionBottomSheet(theme)
          : null,
    );
  }

  Widget _buildAppBar(ThemeData theme) {
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
                  '梗音盒',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  '${_allSounds.length} 个音效',
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
                tooltip: '停止所有音效',
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
              // 多选模式
              PopupMenuItem(
                value: 'selection_mode',
                child: ListTile(
                  leading: Icon(
                    _isSelectionMode
                        ? Icons.check_box_rounded
                        : Icons.select_all_rounded,
                  ),
                  title: Text(_isSelectionMode ? '退出多选' : '多选'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'import',
                child: ListTile(
                  leading: Icon(Icons.file_download_rounded),
                  title: Text('导入音效'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'export_all',
                child: ListTile(
                  leading: Icon(Icons.file_upload_rounded),
                  title: Text('导出全部'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'export_category',
                child: ListTile(
                  leading: Icon(Icons.file_upload_rounded),
                  title: Text('导出当前分类'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings_rounded),
                  title: Text('设置'),
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
        await _handleExportAll();
        break;
      case 'export_category':
        await _handleExportCategory();
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

  Future<void> _handleImport() async {
    // 第一步：选择文件
    final fileInfo = await _importExportService.pickFileAndGetType();
    if (fileInfo == null) {
      return; // 用户取消选择
    }

    final fileType = fileInfo.type;
    final fileContent = fileInfo.content;

    if (!mounted) return;

    // 第二步：根据文件类型显示不同的对话框
    switch (fileType) {
      case 'sound':
      case 'multiple':
        // 单个音效或多个音效：直接选择导入分类
        await _showImportCategoryDialog(fileContent, fileType);
        break;

      case 'category':
        // 有分类的多个音效：选择是否保持原分类或使用新分类
        await _showCategoryImportOptionsDialog(fileContent);
        break;

      case 'full':
        // 完整备份：选择是否覆盖现有数据
        await _showFullBackupImportDialog(fileContent);
        break;

      default:
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('未知的文件类型'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
    }
  }

  /// 显示导入分类选择对话框（用于单个和多个音效）
  Future<void> _showImportCategoryDialog(
    String fileContent,
    String fileType,
  ) async {
    final validCategories = [
      '默认',
      ...SettingsService.instance.customCategories,
    ];
    String selectedCategory = '默认';
    bool showNewCategoryInput = false;
    final newCategoryController = TextEditingController();

    if (!mounted) return;

    // 显示分类选择对话框
    final categoriesResult = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('选择导入分类'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!showNewCategoryInput) ...[
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      labelText: '选择分类',
                      prefixIcon: const Icon(Icons.folder_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: validCategories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
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
                    label: const Text('新建分类'),
                  ),
                ] else ...[
                  TextField(
                    controller: newCategoryController,
                    decoration: InputDecoration(
                      labelText: '新分类名称',
                      hintText: '输入新分类名称',
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
                            setDialogState(() => showNewCategoryInput = false);
                            newCategoryController.clear();
                          },
                          child: const Text('取消'),
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
                          child: const Text('确定'),
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
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, selectedCategory),
              child: const Text('继续'),
            ),
          ],
        ),
      ),
    );

    if (categoriesResult == null) return;

    // 确保分类存在
    if (categoriesResult != '默认' &&
        !validCategories.contains(categoriesResult)) {
      await SettingsService.instance.addCategory(categoriesResult);
    }

    // 执行导入
    final result = await _importExportService.importFromContent(
      fileContent,
      overrideCategory: categoriesResult,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (result.success) {
        await _initializeSounds();
      }
    }
  }

  /// 显示分类导入选项对话框
  Future<void> _showCategoryImportOptionsDialog(String fileContent) async {
    if (!mounted) return;

    final validCategories = [
      '默认',
      ...SettingsService.instance.customCategories,
    ];

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择导入方式'),
        content: const Text('如何导入此分类中的音效？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'keep'),
            child: const Text('保持原分类'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'select'),
            child: const Text('选择新分类'),
          ),
        ],
      ),
    );

    if (result == null) return;

    if (result == 'keep') {
      // 保持原分类导入
      final importResult = await _importExportService.importFromContent(
        fileContent,
        overrideCategory: null,
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
    } else {
      // 选择新分类导入
      String selectedCategory = '默认';
      bool showNewCategoryInput = false;
      final newCategoryController = TextEditingController();

      if (!mounted) return;

      final categoriesResult = await showDialog<String>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('选择导入分类'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!showNewCategoryInput) ...[
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: InputDecoration(
                        labelText: '选择分类',
                        prefixIcon: const Icon(Icons.folder_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: validCategories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
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
                      label: const Text('新建分类'),
                    ),
                  ] else ...[
                    TextField(
                      controller: newCategoryController,
                      decoration: InputDecoration(
                        labelText: '新分类名称',
                        hintText: '输入新分类名称',
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
                            child: const Text('取消'),
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
                            child: const Text('确定'),
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
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, selectedCategory),
                child: const Text('继续'),
              ),
            ],
          ),
        ),
      );

      if (categoriesResult == null) return;

      // 确保分类存在
      if (categoriesResult != '默认' &&
          !validCategories.contains(categoriesResult)) {
        await SettingsService.instance.addCategory(categoriesResult);
      }

      // 执行导入
      final importResult = await _importExportService.importFromContent(
        fileContent,
        overrideCategory: categoriesResult,
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
    }
  }

  /// 显示完整备份导入对话框
  Future<void> _showFullBackupImportDialog(String fileContent) async {
    if (!mounted) return;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导入完整备份'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('完整备份将导入所有音效和设置。'),
            SizedBox(height: 12),
            Text('请选择导入方式：'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'add'),
            child: const Text('添加到现有数据'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'replace'),
            child: const Text('替换所有数据'),
          ),
        ],
      ),
    );

    if (result == null) return;

    if (result == 'replace') {
      // 显示确认对话框
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('确认替换'),
          content: const Text('此操作将删除所有现有的音效和设置，并替换为备份数据。\n\n此操作无法撤销，请确认是否继续。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('确认替换'),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) return;

      // 二次确认
      if (!mounted) return;
      final finalConfirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('最终确认'),
          content: const Text('真的要替换所有数据吗？这是您最后的机会。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('确认，替换所有数据'),
            ),
          ],
        ),
      );

      if (finalConfirmed != true || !mounted) return;

      // 执行替换导入
      final importResult = await _importExportService.importFromContent(
        fileContent,
        clearFirst: true,
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
    } else {
      // 添加到现有数据
      final importResult = await _importExportService.importFromContent(
        fileContent,
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
    }
  }

  Future<void> _handleExportAll() async {
    if (_allSounds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('没有音效可导出'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final path = await _importExportService.exportAll(_allSounds);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(path != null ? '导出成功: $path' : '导出已取消'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导出失败: $e'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _handleExportCategory() async {
    if (_selectedCategory == '全部') {
      await _handleExportAll();
      return;
    }

    final categorySounds = _allSounds
        .where(
          (s) => _selectedCategory == '收藏'
              ? s.isFavorite
              : s.category == _selectedCategory,
        )
        .toList();

    if (categorySounds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('当前分类没有音效'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final path = await _importExportService.exportCategory(
        _selectedCategory,
        categorySounds,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(path != null ? '导出成功: $path' : '导出已取消'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导出失败: $e'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// 显示多选导出选项
  Future<void> _showExportOptions(List<SoundItem> sounds) async {
    if (sounds.isEmpty) return;

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
                title: const Text('导出为压缩包'),
                subtitle: Text('将 ${sounds.length} 个音效打包导出'),
                onTap: () async {
                  Navigator.pop(context);
                  await _exportMultipleSounds(sounds, asZip: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder_rounded),
                title: const Text('导出为单独文件'),
                subtitle: Text('分别导出 ${sounds.length} 个音效'),
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

  /// 显示示例音效导入对话框
  Future<void> _showImportSamplesDialog() async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('欢迎使用！'),
        content: const Text(
          '是否导入示例音效？\n\n'
          '我们提供了4个示例音效供您体验\n\n'
          '稍后您也可以通过菜单的"导入"选项导入',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('跳过'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _importSampleSounds();
            },
            child: const Text('导入'),
          ),
        ],
      ),
    );
  }

  /// 导入示例音效
  Future<void> _importSampleSounds() async {
    try {
      final importedSounds = <SoundItem>[];
      for (final builtInSound in BuiltInSounds.all) {
        debugPrint('导入示例音效: ${builtInSound.name}');
        // 从 assets 复制文件到应用私有目录
        final importedSound = await _fileService.importBuiltInSound(
          builtInSound,
        );
        importedSounds.add(importedSound);
        // 保存到数据库
        await _databaseService.insertSound(importedSound);
      }

      await _initializeSounds();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已导入 ${importedSounds.length} 个示例音效'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导入失败: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// 导出多个音效
  Future<void> _exportMultipleSounds(
    List<SoundItem> sounds, {
    required bool asZip,
  }) async {
    if (sounds.isEmpty) return;

    try {
      if (asZip) {
        // 导出为单个压缩包
        await _exportSoundsAsZip(sounds);
      } else {
        // 分别导出每个音效
        int successCount = 0;
        for (final sound in sounds) {
          final path = await _importExportService.exportSound(sound);
          if (path != null) {
            successCount++;
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                successCount > 0 ? '成功导出 $successCount 个音效' : '导出失败',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导出失败: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// 将多个音效导出为压缩包
  Future<void> _exportSoundsAsZip(List<SoundItem> sounds) async {
    try {
      // 创建一个包含所有音效的合并 .msb 文件
      // 导出合并的 .msb 文件（包含所有音效）
      final path = await _importExportService.exportMultipleSounds(sounds);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '成功导出 ${sounds.length} 个音效到：${path.split(Platform.pathSeparator).last}',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// 导出单个音效为 .msb 文件
  Future<void> _exportSingleSound(SoundItem sound) async {
    try {
      final path = await _importExportService.exportSound(sound);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(path != null ? '导出成功: ${sound.name}' : '导出取消'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导出失败: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// 保存音频文件到用户选择的位置
  Future<void> _saveAudioFile(SoundItem sound) async {
    try {
      final path = await _fileService.saveAudioToUserLocation(sound);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(path != null ? '音频保存成功' : '保存取消'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// 保存封面图片到用户选择的位置
  Future<void> _saveImageFile(SoundItem sound) async {
    if (sound.imagePath == null) return;
    try {
      final path = await _fileService.saveImageToUserLocation(sound);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(path != null ? '图片保存成功' : '保存取消'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
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
                  // 复选框
                  Positioned(
                    top: 8,
                    right: 8,
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
                      width: 24,
                      height: 24,
                      child: isSelected
                          ? const Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: Colors.white,
                            )
                          : null,
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _selectedCategory == '收藏'
                ? Icons.favorite_border_rounded
                : Icons.music_off_rounded,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            _selectedCategory == '收藏'
                ? '还没有收藏的音效'
                : _searchQuery.isNotEmpty
                ? '没有找到匹配的音效'
                : '这个分类还没有音效',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 8),
          if (_selectedCategory != '收藏')
            TextButton.icon(
              onPressed: _addNewSound,
              icon: const Icon(Icons.add_rounded),
              label: const Text('添加音效'),
            ),
        ],
      ),
    );
  }

  /// 构建多选模式的底部操作栏
  Widget _buildSelectionBottomSheet(ThemeData theme) {
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
            // 选中数量
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '已选中 $selectedCount 个',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (selectedCount < _filteredSounds.length)
                    GestureDetector(
                      onTap: () => setState(() {
                        _selectedSoundIds.clear();
                        for (final sound in _filteredSounds) {
                          _selectedSoundIds.add(sound.id);
                        }
                      }),
                      child: Text(
                        '全选',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // 导出按钮
            FilledButton.icon(
              onPressed: selectedSounds.isEmpty
                  ? null
                  : () => _showExportOptions(selectedSounds),
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('导出'),
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
              label: const Text('移动'),
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
              label: const Text('删除'),
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
    showDialog(
      context: context,
      builder: (context) {
        // 在对话框内部获取分类，每次都是最新的
        List<String> validCategories = [
          '默认',
          ...SettingsService.instance.customCategories,
        ];
        String? currentSelected = validCategories.first; // 默认选中"默认"分类
        bool showNewCategoryInput = false;
        final newCategoryController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setDialogState) {
            // 在 setDialogState 后重新构建时，validCategories 会被重新初始化
            return AlertDialog(
              title: const Text('移动到分类'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!showNewCategoryInput) ...[
                      // 分类选择
                      DropdownButtonFormField<String>(
                        value: currentSelected,
                        decoration: InputDecoration(
                          labelText: '选择分类',
                          prefixIcon: const Icon(Icons.folder_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: validCategories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
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
                        label: const Text('新建分类'),
                      ),
                    ] else ...[
                      // 新建分类输入框
                      TextField(
                        controller: newCategoryController,
                        decoration: InputDecoration(
                          labelText: '新分类名称',
                          hintText: '输入新分类名称',
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
                              child: const Text('取消'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                final newCategory = newCategoryController.text
                                    .trim();
                                if (newCategory.isNotEmpty) {
                                  // 立即添加到SettingsService并移动音效
                                  setDialogState(() async {
                                    await SettingsService.instance.addCategory(
                                      newCategory,
                                    );
                                    validCategories = [
                                      '默认',
                                      ...SettingsService
                                          .instance
                                          .customCategories,
                                    ];
                                    currentSelected = newCategory;
                                    showNewCategoryInput = false;
                                  });
                                }
                              },
                              child: const Text('确定'),
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
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: currentSelected == null || currentSelected!.isEmpty
                      ? null
                      : () async {
                          final targetCategory = currentSelected!;

                          // 如果是新建分类，添加到SettingsService
                          if (!validCategories.contains(targetCategory)) {
                            await SettingsService.instance.addCategory(
                              targetCategory,
                            );
                          }

                          // 移动音效
                          for (final sound in sounds) {
                            final updated = sound.copyWith(
                              category: targetCategory,
                            );
                            await _databaseService.updateSound(updated);
                          }

                          setState(() {
                            _selectedSoundIds.clear();
                            _isSelectionMode = false;
                          });
                          await _initializeSounds();

                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '已将 ${sounds.length} 个音效移动到 $targetCategory',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                  child: const Text('确认'),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 ${sounds.length} 个音效吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              for (final sound in sounds) {
                await _databaseService.deleteSound(sound.id);
              }

              // 检查删除后是否还有音效
              final remainingSounds = await _databaseService.getAllSounds();
              if (remainingSounds.isEmpty) {
                // 如果所有音效都被删除，重置默认音效导入标志
                await SettingsService.instance.resetDefaultsImported();
              }

              setState(() {
                _selectedSoundIds.clear();
                _isSelectionMode = false;
              });
              await _initializeSounds();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('已删除 ${sounds.length} 个音效'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB(ThemeData theme) {
    return FloatingActionButton.extended(
      onPressed: _addNewSound,
      backgroundColor: theme.primaryColor,
      icon: const Icon(Icons.add_rounded),
      label: const Text('添加', style: TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}
