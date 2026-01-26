import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';
import '../services/import_export_service.dart';
import '../services/database_service.dart';
import '../services/settings_service.dart';
import '../utils/app_constants.dart';

/// 导出文件信息
class ExportFileInfo {
  final File file;
  final String name;
  final int size;
  final DateTime modifiedTime;
  final String type; // sound, category, multiple, full
  final int? soundCount;

  ExportFileInfo({
    required this.file,
    required this.name,
    required this.size,
    required this.modifiedTime,
    required this.type,
    this.soundCount,
  });

  String get typeText {
    switch (type) {
      case 'sound':
        return '单个音效';
      case 'category':
        return '分类';
      case 'multiple':
        return '多个音效';
      case 'full':
        return '完整备份';
      default:
        return '未知';
    }
  }

  String get sizeText {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}

/// 导出目录管理页面
class ExportManagerScreen extends StatefulWidget {
  final VoidCallback? onDataChanged;

  const ExportManagerScreen({super.key, this.onDataChanged});

  @override
  State<ExportManagerScreen> createState() => _ExportManagerScreenState();
}

class _ExportManagerScreenState extends State<ExportManagerScreen> {
  final _databaseService = DatabaseService();
  late final ImportExportService _importExportService;
  List<ExportFileInfo> _files = [];
  bool _isLoading = true;
  String? _exportDir;
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _lastSnackBar;

  @override
  void initState() {
    super.initState();
    _importExportService = ImportExportService(_databaseService);
    _loadFiles();
  }

  /// 显示 SnackBar 消息
  void _showSnackBar(
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 2),
  }) {
    if (!mounted) return;
    
    // 关闭之前的 SnackBar
    _lastSnackBar?.close();
    
    _lastSnackBar = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor,
        duration: duration,
      ),
    );
  }

  Future<void> _loadFiles() async {
    setState(() => _isLoading = true);

    try {
      final dirPath = await _importExportService.getDefaultExportDirectory();
      if (dirPath == null) {
        setState(() {
          _isLoading = false;
          _exportDir = null;
        });
        return;
      }

      _exportDir = dirPath;
      final dir = Directory(dirPath);

      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final files = <ExportFileInfo>[];
      await for (final entity in dir.list()) {
        if (entity is File && entity.path.endsWith(AppConstants.exportFileExtension)) {
          try {
            final stat = await entity.stat();
            final content = await entity.readAsString();
            final json = jsonDecode(content) as Map<String, dynamic>;
            
            final type = json['type'] as String? ?? 'unknown';
            int? soundCount;
            
            if (type == 'multiple' || type == 'full') {
              final sounds = json['sounds'] as List?;
              soundCount = sounds?.length;
            } else if (type == 'category') {
              final data = json['data'] as List?;
              soundCount = data?.length;
            }

            files.add(ExportFileInfo(
              file: entity,
              name: path.basenameWithoutExtension(entity.path),
              size: stat.size,
              modifiedTime: stat.modified,
              type: type,
              soundCount: soundCount,
            ));
          } catch (e) {
            debugPrint('解析文件失败: ${entity.path}, $e');
          }
        }
      }

      // 按修改时间排序，最新的在前
      files.sort((a, b) => b.modifiedTime.compareTo(a.modifiedTime));

      setState(() {
        _files = files;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('加载导出文件失败: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteFile(ExportFileInfo fileInfo) async {
    // 防止删除示例音效包
    if (fileInfo.name == '${AppConstants.samplePackName}.msb') {
      _showSnackBar('无法删除示例音效包', backgroundColor: Colors.orange);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 "${fileInfo.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await fileInfo.file.delete();
        await _loadFiles();
        _showSnackBar('已删除');
      } catch (e) {
        _showSnackBar('删除失败: $e', backgroundColor: Colors.red);
      }
    }
  }

  Future<void> _shareFile(ExportFileInfo fileInfo) async {
    try {
      await Share.shareXFiles(
        [XFile(fileInfo.file.path)],
        text: '分享音效文件: ${fileInfo.name}',
      );
    } catch (e) {
      _showSnackBar('分享失败: $e', backgroundColor: Colors.red);
    }
  }

  Future<void> _importFile(ExportFileInfo fileInfo) async {
    try {
      // 读取文件内容
      final content = await fileInfo.file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final fileType = json['type'] as String? ?? 'unknown';
      
      // 根据文件类型显示不同的对话框（与主界面菜单逻辑一致）
      if (!mounted) return;
      
      switch (fileType) {
        case 'sound':
        case 'multiple':
          // 单个音效或多个音效：选择导入分类
          await _showImportCategoryDialog(content, fileType, fileInfo.name, fileInfo);
          break;

        case 'category':
          // 有分类的多个音效：选择是否保持原分类或使用新分类
          await _showCategoryImportOptionsDialog(content, fileInfo.name);
          break;

        case 'full':
          // 完整备份：选择是否覆盖现有数据
          await _showFullBackupImportDialog(content, fileInfo.name);
          break;

        default:
          if (mounted) {
            _showSnackBar('未知的文件类型', backgroundColor: Colors.red);
          }
      }
    } catch (e) {
      _showSnackBar('读取文件失败: $e', backgroundColor: Colors.red);
    }
  }

  /// 显示导入分类选择对话框（用于单个和多个音效）
  Future<void> _showImportCategoryDialog(
    String fileContent,
    String fileType,
    String fileName,
    ExportFileInfo? fileInfo,
  ) async {
    // 这里需要访问 SettingsService 获取可用分类
    // 为了简化，直接导入到默认分类或显示预览然后导入
    await _showImportPreviewDialog(
      ExportFileInfo(
        file: fileInfo?.file ?? File(''),
        name: fileName,
        size: fileInfo?.size ?? 0,
        modifiedTime: fileInfo?.modifiedTime ?? DateTime.now(),
        type: fileType,
      ),
      jsonDecode(fileContent) as Map<String, dynamic>,
      isDirectImport: true,
    );
  }

  /// 显示分类导入选项对话框
  Future<void> _showCategoryImportOptionsDialog(
    String fileContent,
    String fileName,
  ) async {
    if (!mounted) return;

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
      await _performImport(fileContent);
    } else if (result == 'select') {
      // 选择新分类导入
      if (!mounted) return;
      await _showSelectCategoryDialog(fileContent);
    }
  }

  /// 显示选择或创建新分类对话框（用于导入时更改分类）
  Future<void> _showSelectCategoryDialog(String fileContent) async {
    if (!mounted) return;

    List<String> validCategories = [
      '默认',
      ...SettingsService.instance.customCategories,
    ];
    String? selectedCategory = validCategories.first;
    bool showNewCategoryInput = false;
    final newCategoryController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
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
                            onPressed: () async {
                              final newCategory = newCategoryController.text.trim();
                              if (newCategory.isNotEmpty) {
                                await SettingsService.instance.addCategory(newCategory);
                                if (mounted) {
                                  setDialogState(() {
                                    validCategories = [
                                      '默认',
                                      ...SettingsService.instance.customCategories,
                                    ];
                                    selectedCategory = newCategory;
                                    showNewCategoryInput = false;
                                    newCategoryController.clear();
                                  });
                                }
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
                onPressed: selectedCategory == null ? null : () async {
                  Navigator.pop(context);
                  // 导入时更改分类
                  final json = jsonDecode(fileContent) as Map<String, dynamic>;
                  final sounds = json['data'] as List?;
                  if (sounds != null) {
                    // 修改每个音效的分类为选中的分类
                    for (int i = 0; i < sounds.length; i++) {
                      if (sounds[i] is Map<String, dynamic>) {
                        (sounds[i] as Map<String, dynamic>)['category'] = selectedCategory;
                      }
                    }
                    json['data'] = sounds;
                    // 导入修改后的内容
                    await _performImport(jsonEncode(json));
                  }
                },
                child: const Text('确定'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 显示完整备份导入对话框
  Future<void> _showFullBackupImportDialog(
    String fileContent,
    String fileName,
  ) async {
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

      // 执行替换导入
      await _performImport(fileContent, clearFirst: true);
    } else {
      // 添加到现有数据
      await _performImport(fileContent);
    }
  }

  Future<void> _showImportPreviewDialog(ExportFileInfo fileInfo, Map<String, dynamic> json, {bool isDirectImport = false}) async {
    final type = json['type'] as String? ?? 'unknown';
    final exportedAt = json['exportedAt'] as String?;
    DateTime? exportDate;
    if (exportedAt != null) {
      try {
        exportDate = DateTime.parse(exportedAt);
      } catch (_) {}
    }

    List<String> soundNames = [];
    String? categoryName;

    if (type == 'sound') {
      final data = json['data'] as Map<String, dynamic>?;
      if (data != null) {
        soundNames.add(data['name'] as String? ?? '未知');
      }
    } else if (type == 'category') {
      categoryName = json['category'] as String?;
      final data = json['data'] as List?;
      if (data != null) {
        for (final item in data) {
          if (item is Map<String, dynamic>) {
            soundNames.add(item['name'] as String? ?? '未知');
          }
        }
      }
    } else if (type == 'multiple' || type == 'full') {
      final sounds = json['sounds'] as List?;
      if (sounds != null) {
        for (final item in sounds) {
          if (item is Map<String, dynamic>) {
            soundNames.add(item['name'] as String? ?? '未知');
          }
        }
      }
    }

    final content = jsonEncode(json);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getTypeIcon(type),
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
            const Text('导入预览'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPreviewRow('文件名', fileInfo.name),
              _buildPreviewRow('类型', fileInfo.typeText),
              _buildPreviewRow('大小', fileInfo.sizeText),
              if (exportDate != null)
                _buildPreviewRow(
                  '导出时间',
                  DateFormat('yyyy-MM-dd HH:mm').format(exportDate),
                ),
              if (categoryName != null)
                _buildPreviewRow('分类', categoryName),
              const SizedBox(height: 12),
              Text(
                '将导入的音效 (${soundNames.length}个):',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: soundNames.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.music_note, size: 18),
                      title: Text(
                        soundNames[index],
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('导入'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _performImport(content);
    }
  }

  Widget _buildPreviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'sound':
        return Icons.music_note_rounded;
      case 'category':
        return Icons.folder_rounded;
      case 'multiple':
        return Icons.library_music_rounded;
      case 'full':
        return Icons.backup_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Future<void> _performImport(String content, {bool clearFirst = false}) async {
    try {
      final result = await _importExportService.importFromContent(
        content,
        clearFirst: clearFirst,
      );
      
      widget.onDataChanged?.call();
      
      if (mounted) {
        _showSnackBar(
          result.message,
          backgroundColor: result.success ? null : Colors.red,
        );
      }
    } catch (e) {
      _showSnackBar('导入失败: $e', backgroundColor: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('管理导出文件'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFiles,
            tooltip: '刷新',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
              ? _buildEmptyState()
              : _buildFileList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open_rounded,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无导出文件',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _exportDir ?? '无法获取导出目录',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFileList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _files.length,
      itemBuilder: (context, index) {
        final file = _files[index];
        return _buildFileCard(file);
      },
    );
  }

  Widget _buildFileCard(ExportFileInfo fileInfo) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showFileOptions(fileInfo),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 图标
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getTypeIcon(fileInfo.type),
                  color: theme.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              // 信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileInfo.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              fileInfo.typeText,
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            fileInfo.sizeText,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (fileInfo.soundCount != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '${fileInfo.soundCount}个音效',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('yyyy-MM-dd HH:mm').format(fileInfo.modifiedTime),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              // 更多按钮
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _showFileOptions(fileInfo),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFileOptions(ExportFileInfo fileInfo) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.info_rounded, color: Colors.blue),
              title: const Text('文件详情'),
              subtitle: const Text('查看完整文件信息'),
              onTap: () {
                Navigator.pop(context);
                _showFileDetails(fileInfo);
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_download_rounded, color: Colors.blue),
              title: const Text('导入'),
              subtitle: const Text('将此文件导入到应用'),
              onTap: () {
                Navigator.pop(context);
                _importFile(fileInfo);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_rounded, color: Colors.green),
              title: const Text('分享'),
              subtitle: const Text('分享到微信、QQ等'),
              onTap: () {
                Navigator.pop(context);
                _shareFile(fileInfo);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: Colors.red),
              title: const Text('删除'),
              subtitle: const Text('删除此导出文件'),
              onTap: () {
                Navigator.pop(context);
                _deleteFile(fileInfo);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// 显示文件详情对话框
  void _showFileDetails(ExportFileInfo fileInfo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('文件详情'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('文件名', fileInfo.file.path.split(Platform.pathSeparator).last),
              _buildDetailRow('类型', fileInfo.typeText),
              _buildDetailRow('大小', fileInfo.sizeText),
              _buildDetailRow('修改时间', DateFormat('yyyy-MM-dd HH:mm:ss').format(fileInfo.modifiedTime)),
              if (fileInfo.soundCount != null)
                _buildDetailRow('音效数量', '${fileInfo.soundCount}个'),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }
}
