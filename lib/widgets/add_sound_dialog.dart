import 'dart:io';
import 'package:flutter/material.dart';
import '../models/sound_item.dart';
import '../services/settings_service.dart';
import '../services/audio_service.dart';
import '../services/file_service.dart';

/// 添加/编辑音效对话框
class AddSoundDialog extends StatefulWidget {
  final SoundItem? existingSound;
  final Future<void> Function(
    String name,
    String category,
    String? soundPath,
    String? imagePath,
    SoundSourceType sourceType,
    SoundAdvancedSettings advancedSettings,
  )
  onConfirm;
  final Future<dynamic> Function()? onSelectAudio; // 返回 Map 或 null
  final Future<String?> Function()? onSelectImage;

  const AddSoundDialog({
    super.key,
    this.existingSound,
    required this.onConfirm,
    this.onSelectAudio,
    this.onSelectImage,
  });

  @override
  State<AddSoundDialog> createState() => _AddSoundDialogState();
}

class _AddSoundDialogState extends State<AddSoundDialog> {
  late TextEditingController _nameController;
  late TextEditingController _newCategoryController;
  late TextEditingController _audioUrlController;
  late TextEditingController _imageUrlController;

  late String _selectedCategory;
  bool _isLoading = false;
  String? _selectedAudioPath; // 用于显示已选择的文件名
  String? _tempSoundPath; // 用于保存临时音频文件的真实路径
  String? _selectedImagePath;
  bool _showNewCategoryInput = false;
  String? _errorMessage;

  // 输入类型：文件 或 链接
  bool _useAudioUrl = false;
  bool _useImageUrl = false;

  // 音频预览相关
  late AudioService _previewAudioService;
  bool _isPreviewPlaying = false;
  String? _previewValidationError;
  bool _hasPreviewedAudio = false; // 追踪用户是否已成功预览

  // 高级设置
  double _volumeLevel = 1.0;

  @override
  void initState() {
    super.initState();
    _previewAudioService = AudioService();
    _nameController = TextEditingController(
      text: widget.existingSound?.name ?? '',
    );
    _newCategoryController = TextEditingController();
    _audioUrlController = TextEditingController();
    _imageUrlController = TextEditingController();

    // 监听 URL 输入变化，重置预览标记
    _audioUrlController.addListener(() {
      setState(() {
        _hasPreviewedAudio = false;
        _previewValidationError = null;
        if (_isPreviewPlaying) {
          _previewAudioService.stopCurrent();
          _isPreviewPlaying = false;
        }
      });
    });

    // 设置默认分类为"默认"
    _selectedCategory = '默认';

    if (widget.existingSound != null) {
      final sound = widget.existingSound!;
      _selectedCategory = sound.category;
      _selectedImagePath = sound.imagePath;

      // 如果是URL来源
      if (sound.isUrl) {
        _useAudioUrl = true;
        _audioUrlController.text = sound.soundPath;
      }
      if (sound.isImageUrl) {
        _useImageUrl = true;
        _imageUrlController.text = sound.imagePath ?? '';
      }

      // 高级设置
      _volumeLevel = sound.advancedSettings.volumeLevel;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _newCategoryController.dispose();
    _audioUrlController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  List<String> get _availableCategories {
    return ['默认', ...SettingsService.instance.customCategories];
  }

  Future<void> _handleSelectAudio() async {
    if (widget.onSelectAudio != null) {
      try {
        final result = await widget.onSelectAudio!();
        if (result != null) {
          // result 现在是一个 Map，包含 displayName 和 soundPath
          final displayName = result is Map
              ? result['displayName'] as String
              : result.toString();
          final soundPath = result is Map
              ? result['soundPath'] as String
              : result.toString();

          setState(() {
            // 选择新文件时停止当前预览
            if (_isPreviewPlaying) {
              _previewAudioService.stopCurrent();
            }

            _selectedAudioPath = displayName; // 用户友好的文件名用于显示
            _tempSoundPath = soundPath; // 真实的音频路径用于保存
            _useAudioUrl = false;
            _audioUrlController.clear();
            // 选择新文件时重置预览标记
            _hasPreviewedAudio = false;
            _previewValidationError = null;
            _isPreviewPlaying = false;
            if (_nameController.text.isEmpty) {
              // displayName 已经是干净的文件名，直接去除扩展名
              final nameWithoutExt = displayName.contains('.')
                  ? displayName.substring(0, displayName.lastIndexOf('.'))
                  : displayName;
              _nameController.text = nameWithoutExt;
            }
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _handleSelectImage() async {
    if (widget.onSelectImage != null) {
      final path = await widget.onSelectImage!();
      if (path != null) {
        setState(() {
          _selectedImagePath = path;
          _useImageUrl = false;
          _imageUrlController.clear();
        });
      }
    }
  }

  String? get _effectiveAudioPath {
    if (_useAudioUrl && _audioUrlController.text.trim().isNotEmpty) {
      return _audioUrlController.text.trim();
    }
    // 优先使用真实的音频路径（从文件选择得到），如果没有则使用显示的路径
    return _tempSoundPath ?? _selectedAudioPath;
  }

  String? get _effectiveImagePath {
    if (_useImageUrl && _imageUrlController.text.trim().isNotEmpty) {
      return _imageUrlController.text.trim();
    }
    return _selectedImagePath;
  }

  SoundSourceType get _sourceType {
    if (_useAudioUrl) return SoundSourceType.url;
    if (widget.existingSound?.isAsset == true) return SoundSourceType.asset;
    return SoundSourceType.file;
  }

  /// 预览播放音频
  Future<void> _previewAudio() async {
    final audioPath = _effectiveAudioPath;

    if (audioPath == null) {
      setState(() => _previewValidationError = '请先选择音频文件或输入链接');
      return;
    }

    if (_isPreviewPlaying) {
      // 停止播放
      await _previewAudioService.stopCurrent();
      setState(() {
        _isPreviewPlaying = false;
        _previewValidationError = null;
      });
      return;
    }

    // 清除之前的错误
    setState(() => _previewValidationError = null);

    try {
      setState(() => _isLoading = true);

      // 如果是URL，需要先下载
      String effectivePath = audioPath;
      if (_useAudioUrl) {
        final fileService = FileService();
        final downloaded = await fileService.downloadAndCacheAudio(audioPath);
        effectivePath = downloaded;
      } else {
        // 验证本地文件是否存在
        final file = File(audioPath);
        if (!await file.exists()) {
          setState(() {
            _previewValidationError = '音频文件不存在或已被删除';
            _isLoading = false;
          });
          return;
        }
      }

      // 创建临时 SoundItem 用于播放
      // 重要：已下载的 URL 音频应该作为本地文件播放，而不是 URL
      final tempSound = SoundItem(
        id: 'preview_${DateTime.now().millisecondsSinceEpoch}',
        name: '预览',
        soundPath: effectivePath,
        category: '',
        imagePath: null,
        isFavorite: false,
        sourceType: SoundSourceType.file, // 总是作为文件播放（已下载的内容）
        advancedSettings: SoundAdvancedSettings(),
      );

      await _previewAudioService.play(tempSound);
      setState(() {
        _isPreviewPlaying = true;
        _isLoading = false;
        _previewValidationError = null; // 预览成功，清除错误
        _hasPreviewedAudio = true; // 标记已成功预览
      });
    } catch (e) {
      setState(() {
        _previewValidationError =
            '播放失败: ${e.toString().replaceFirst('Exception: ', '')}';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleConfirm() async {
    final audioPath = _effectiveAudioPath;

    // 验证：新增时必须有音频
    if (widget.existingSound == null && audioPath == null) {
      setState(() => _errorMessage = '请选择音频文件或输入音频链接');
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      setState(() => _errorMessage = '请输入音效名称');
      return;
    }

    // URL 格式验证
    if (_useAudioUrl && audioPath != null) {
      if (!audioPath.startsWith('http://') &&
          !audioPath.startsWith('https://')) {
        setState(() => _errorMessage = '音频链接必须以 http:// 或 https:// 开头');
        return;
      }
    }

    String category = _selectedCategory;
    if (_showNewCategoryInput &&
        _newCategoryController.text.trim().isNotEmpty) {
      category = _newCategoryController.text.trim();
      await SettingsService.instance.addCategory(category);
    }

    setState(() => _isLoading = true);
    _errorMessage = null;

    try {
      final advSettings = SoundAdvancedSettings(volumeLevel: _volumeLevel);

      await widget.onConfirm(
        _nameController.text.trim(),
        category,
        audioPath,
        _effectiveImagePath,
        _sourceType,
        advSettings,
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.existingSound != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 错误提示 - 始终显示在最上面，不被滚动隐藏
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withAlpha(128)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.close, size: 18),
                        color: Colors.red,
                        onPressed: () => setState(() => _errorMessage = null),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 可滚动的主要内容
          Flexible(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  _errorMessage == null ? 20 : 0,
                  20,
                  20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 标题
                    _buildHeader(theme, isEditing),

                    const SizedBox(height: 20),

                    // 音频来源选择（仅新增时显示）
                    if (!isEditing) ...[
                      _buildSourceToggle(
                        label: '音频来源',
                        useUrl: _useAudioUrl,
                        onChanged: (val) => setState(() {
                          // 切换音频来源时停止当前预览
                          if (_isPreviewPlaying) {
                            _previewAudioService.stopCurrent();
                          }

                          _useAudioUrl = val;
                          if (!val)
                            _audioUrlController.clear();
                          else {
                            _selectedAudioPath = null;
                            _tempSoundPath = null;
                          }
                          // 改变音频来源时重置预览标记
                          _hasPreviewedAudio = false;
                          _previewValidationError = null;
                          _isPreviewPlaying = false;
                        }),
                      ),
                      const SizedBox(height: 8),
                      if (_useAudioUrl)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildUrlInput(
                                    controller: _audioUrlController,
                                    hint: '输入音频链接 (http:// 或 https://)',
                                    icon: Icons.link_rounded,
                                  ),
                                ),
                                if (_audioUrlController.text.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: IconButton(
                                      icon: const Icon(Icons.close_rounded),
                                      onPressed: () => setState(() {
                                        // 清除链接时停止预览
                                        if (_isPreviewPlaying) {
                                          _previewAudioService.stopCurrent();
                                          _isPreviewPlaying = false;
                                        }
                                        _audioUrlController.clear();
                                        _previewValidationError = null;
                                        _hasPreviewedAudio = false;
                                      }),
                                      tooltip: '清空链接',
                                    ),
                                  ),
                              ],
                            ),
                            // 预览错误消息
                            if (_previewValidationError != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withAlpha(26),
                                    border: Border.all(
                                      color: Colors.red.withAlpha(102),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _previewValidationError!,
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            // 预览按钮
                            if (_effectiveAudioPath != null &&
                                _audioUrlController.text.trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: FilledButton.icon(
                                  onPressed: _isLoading ? null : _previewAudio,
                                  icon: Icon(
                                    _isPreviewPlaying
                                        ? Icons.stop_rounded
                                        : Icons.play_arrow_rounded,
                                  ),
                                  label: Text(
                                    _isLoading
                                        ? '加载中...'
                                        : (_isPreviewPlaying ? '停止播放' : '预览'),
                                  ),
                                ),
                              ),
                          ],
                        )
                      else if (widget.onSelectAudio != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildFileSelector(
                              icon: Icons.audiotrack_rounded,
                              label: _selectedAudioPath != null
                                  ? '已选择: ${_selectedAudioPath!}'
                                  : '选择音频文件 *',
                              isSelected: _selectedAudioPath != null,
                              onTap: _handleSelectAudio,
                              isRequired: true,
                            ),
                            // 预览错误消息
                            if (_previewValidationError != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withAlpha(26),
                                    border: Border.all(
                                      color: Colors.red.withAlpha(102),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _previewValidationError!,
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            // 预览按钮
                            if (_effectiveAudioPath != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: FilledButton.icon(
                                  onPressed: _isLoading ? null : _previewAudio,
                                  icon: Icon(
                                    _isPreviewPlaying
                                        ? Icons.stop_rounded
                                        : Icons.play_arrow_rounded,
                                  ),
                                  label: Text(
                                    _isLoading
                                        ? '加载中...'
                                        : (_isPreviewPlaying ? '停止播放' : '预览'),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      const SizedBox(height: 16),
                    ],

                    // 图片来源选择
                    _buildSourceToggle(
                      label: '封面图片',
                      useUrl: _useImageUrl,
                      onChanged: (val) => setState(() {
                        _useImageUrl = val;
                        if (!val)
                          _imageUrlController.clear();
                        else
                          _selectedImagePath = null;
                      }),
                    ),
                    const SizedBox(height: 8),
                    if (_useImageUrl)
                      Row(
                        children: [
                          Expanded(
                            child: _buildUrlInput(
                              controller: _imageUrlController,
                              hint: '输入图片链接 (可选)',
                              icon: Icons.image_rounded,
                            ),
                          ),
                          if (_imageUrlController.text.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: IconButton(
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () => setState(() {
                                  _imageUrlController.clear();
                                }),
                                tooltip: '清空链接',
                              ),
                            ),
                        ],
                      )
                    else if (widget.onSelectImage != null)
                      Stack(
                        children: [
                          _buildFileSelector(
                            icon: Icons.image_rounded,
                            label: _effectiveImagePath != null
                                ? '已选择封面图片'
                                : '选择封面图片 (可选)',
                            isSelected: _effectiveImagePath != null,
                            onTap: _handleSelectImage,
                            previewImage: _selectedImagePath,
                            isAssetImage:
                                widget.existingSound?.isAsset ?? false,
                          ),
                          if (_effectiveImagePath != null)
                            Positioned(
                              right: 8,
                              top: 12,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(26),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.close_rounded),
                                  iconSize: 20,
                                  onPressed: () => setState(() {
                                    _selectedImagePath = null;
                                    _imageUrlController.clear();
                                  }),
                                  tooltip: '删除封面图片',
                                ),
                              ),
                            ),
                        ],
                      ),

                    const SizedBox(height: 16),

                    // 名称输入框
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: '音效名称',
                        hintText: '输入音效名称',
                        prefixIcon: const Icon(Icons.label_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),

                    const SizedBox(height: 16),

                    // 分类选择
                    _buildCategorySelector(theme),

                    const SizedBox(height: 16),

                    // 高级设置折叠面板
                    _buildAdvancedSettingsPanel(theme),

                    const SizedBox(height: 24),

                    // 确认按钮
                    _buildConfirmButton(isEditing),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isEditing) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.primaryColor.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isEditing ? Icons.edit_rounded : Icons.add_rounded,
            color: theme.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            isEditing ? '编辑音效' : '添加音效',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildSourceToggle({
    required String label,
    required bool useUrl,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const Spacer(),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: false,
              label: Text('文件'),
              icon: Icon(Icons.folder_rounded, size: 16),
            ),
            ButtonSegment(
              value: true,
              label: Text('链接'),
              icon: Icon(Icons.link_rounded, size: 16),
            ),
          ],
          selected: {useUrl},
          onSelectionChanged: (set) => onChanged(set.first),
          style: const ButtonStyle(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  Widget _buildUrlInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
      keyboardType: TextInputType.url,
    );
  }

  Widget _buildCategorySelector(ThemeData theme) {
    if (_showNewCategoryInput) {
      return Row(
        children: [
          Expanded(
            child: TextField(
              controller: _newCategoryController,
              decoration: InputDecoration(
                labelText: '新分类名称',
                hintText: '输入新分类名称',
                prefixIcon: const Icon(Icons.create_new_folder_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => setState(() {
              _showNewCategoryInput = false;
              _newCategoryController.clear();
            }),
            icon: const Icon(Icons.close_rounded),
            tooltip: '取消',
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _availableCategories.contains(_selectedCategory)
                ? _selectedCategory
                : _availableCategories.first,
            decoration: InputDecoration(
              labelText: '分类',
              prefixIcon: const Icon(Icons.folder_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
            ),
            items: _availableCategories.map((category) {
              return DropdownMenuItem(value: category, child: Text(category));
            }).toList(),
            onChanged: (value) {
              if (value != null) setState(() => _selectedCategory = value);
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => setState(() => _showNewCategoryInput = true),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.primaryColor.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.add_rounded, color: theme.primaryColor),
          ),
          tooltip: '新建分类',
        ),
      ],
    );
  }

  Widget _buildAdvancedSettingsPanel(ThemeData theme) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Row(
        children: [
          const Icon(Icons.tune_rounded, size: 20),
          const SizedBox(width: 8),
          const Text('音效设置'),
        ],
      ),
      children: [
        const SizedBox(height: 8),

        // 音量控制
        Row(
          children: [
            const Icon(Icons.volume_down_rounded),
            Expanded(
              child: Slider(
                value: _volumeLevel,
                min: 0.0,
                max: 1.0,
                divisions: 20,
                label: '${(_volumeLevel * 100).round()}%',
                onChanged: (val) => setState(() => _volumeLevel = val),
              ),
            ),
            const Icon(Icons.volume_up_rounded),
            const SizedBox(width: 8),
            Text('${(_volumeLevel * 100).round()}%'),
          ],
        ),
      ],
    );
  }

  Widget _buildConfirmButton(bool isEditing) {
    // 新增音效时，必须先预览才能添加
    final canConfirm = isEditing || _hasPreviewedAudio;

    return ElevatedButton(
      onPressed: (_isLoading || !canConfirm) ? null : _handleConfirm,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              isEditing ? '保存更改' : (!canConfirm ? '请先预览音频' : '添加音效'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
    );
  }

  Widget _buildFileSelector({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    String? previewImage,
    bool isAssetImage = false,
    bool isRequired = false,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? theme.primaryColor
                : (isRequired ? Colors.orange : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? theme.primaryColor.withAlpha(13) : null,
        ),
        child: Row(
          children: [
            if (previewImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: isAssetImage
                    ? Image.asset(
                        previewImage,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildIconContainer(icon, isSelected, theme),
                      )
                    : Image.file(
                        File(previewImage),
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildIconContainer(icon, isSelected, theme),
                      ),
              )
            else
              _buildIconContainer(icon, isSelected, theme),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? theme.primaryColor : null,
                  fontWeight: isSelected ? FontWeight.w500 : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.add_circle_outline_rounded,
              color: isSelected ? theme.primaryColor : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconContainer(IconData icon, bool isSelected, ThemeData theme) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isSelected
            ? theme.primaryColor.withAlpha(26)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: isSelected ? theme.primaryColor : Colors.grey),
    );
  }
}
