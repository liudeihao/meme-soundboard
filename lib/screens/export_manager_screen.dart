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
import '../widgets/msb_import_preview_dialog.dart';

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

  /// Bundled sample pack copy under export dir (basename has no extension).
  bool get isBundledSamplePack => name == AppConstants.samplePackName;
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
    if (fileInfo.isBundledSamplePack) {
      _showSnackBar('示例音效包不可删除', backgroundColor: Colors.orange);
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
      final content = await fileInfo.file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final fileType = json['type'] as String? ?? 'unknown';

      if (!mounted) return;

      final previewOk = await MsbImportPreviewDialog.show(
        context,
        displayName: fileInfo.name,
        json: json,
        sizeBytes: fileInfo.size,
        modifiedTime: fileInfo.modifiedTime,
      );
      if (!previewOk || !mounted) return;

      switch (fileType) {
        case 'sound':
        case 'multiple':
          await _performImport(content);
          break;

        case 'category':
          await _showCategoryImportOptionsDialog(content);
          break;

        case 'full':
          await _showFullBackupImportDialog(content);
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

  /// 显示分类导入选项对话框
  Future<void> _showCategoryImportOptionsDialog(
    String fileContent,
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
                  MsbImportPreviewDialog.typeIcon(fileInfo.type),
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
                    if (fileInfo.isBundledSamplePack) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 15,
                            color: Colors.amber.shade800,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '内置示例 · 不可删除',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.amber.shade900,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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
              enabled: !fileInfo.isBundledSamplePack,
              leading: Icon(
                Icons.delete_rounded,
                color: fileInfo.isBundledSamplePack
                    ? Colors.grey.shade400
                    : Colors.red,
              ),
              title: const Text('删除'),
              subtitle: Text(
                fileInfo.isBundledSamplePack
                    ? '示例音效包不可删除'
                    : '删除此导出文件',
              ),
              onTap: fileInfo.isBundledSamplePack
                  ? null
                  : () {
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

  /// 显示文件详情（与导入预览一致的包内容列表）
  Future<void> _showFileDetails(ExportFileInfo fileInfo) async {
    try {
      final text = await fileInfo.file.readAsString();
      final json = jsonDecode(text) as Map<String, dynamic>;
      if (!mounted) return;
      await MsbImportPreviewDialog.showPackDetails(
        context,
        displayName: fileInfo.name,
        json: json,
        sizeBytes: fileInfo.size,
        modifiedTime: fileInfo.modifiedTime,
      );
    } catch (e) {
      if (mounted) {
        _showSnackBar('无法读取文件详情: $e', backgroundColor: Colors.red);
      }
    }
  }
}
