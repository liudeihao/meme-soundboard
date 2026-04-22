import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/database_service.dart';
import '../services/import_export_service.dart';
import '../utils/app_constants.dart';
import 'export_manager_screen.dart';

/// 设置页面
class SettingsScreen extends StatefulWidget {
  final VoidCallback? onDataChanged;

  const SettingsScreen({super.key, this.onDataChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settings = SettingsService.instance;
  final _databaseService = DatabaseService();
  late final ImportExportService _importExportService;

  VoidCallback? get _onDataChanged => widget.onDataChanged;

  @override
  void initState() {
    super.initState();
    _importExportService = ImportExportService(_databaseService);
    _settings.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置'), centerTitle: true),
      body: ListView(
        children: [
          // 外观设置
          _buildSectionHeader(context, '外观'),
          _buildListTile(
            context,
            icon: Icons.palette_rounded,
            iconColor: Colors.purple,
            title: '主题模式',
            subtitle: _settings.getThemeModeText(),
            onTap: () => _showThemeModeDialog(context),
          ),
          _buildListTile(
            context,
            icon: Icons.grid_view_rounded,
            iconColor: Colors.blue,
            title: '网格列数',
            subtitle: '${_settings.gridColumns} 列',
            onTap: () => _showGridColumnsDialog(context),
          ),

          const Divider(height: 32),

          // 音频设置
          _buildSectionHeader(context, '音频'),
          _buildSwitchTile(
            context,
            icon: Icons.vibration_rounded,
            iconColor: Colors.orange,
            title: '触觉反馈',
            subtitle: '点击按钮时震动',
            value: _settings.hapticFeedback,
            onChanged: (value) => _settings.setHapticFeedback(value),
          ),
          _buildSwitchTile(
            context,
            icon: Icons.multitrack_audio_rounded,
            iconColor: Colors.green,
            title: '同时播放',
            subtitle: '开启后点击新音效不会中断正在播放的音效',
            value: _settings.allowMultiPlay,
            onChanged: (value) => _settings.setAllowMultiPlay(value),
          ),

          const Divider(height: 32),

          // 分类管理
          _buildSectionHeader(context, '音效'),
          _buildListTile(
            context,
            icon: Icons.music_note_rounded,
            iconColor: Colors.blue,
            title: '导入示例音效包',
            subtitle: '导入精选示例音效',
            onTap: () => _showImportSamplesDialog(context),
          ),
          _buildListTile(
            context,
            icon: Icons.play_circle_outline_rounded,
            iconColor: Colors.green,
            title: '启动时显示的分类',
            subtitle: _settings.startupCategory,
            onTap: () => _showStartupCategoryDialog(context),
          ),

          const Divider(height: 32),

          // 数据导出
          _buildSectionHeader(context, '数据导出'),
          _buildListTile(
            context,
            icon: Icons.folder_open_rounded,
            iconColor: Colors.amber,
            title: '管理导出文件',
            subtitle: '查看、分享、导入导出的文件',
            onTap: () => _openExportDirectory(context),
          ),

          const Divider(height: 32),

          _buildSectionHeader(context, '分类管理'),
          _buildListTile(
            context,
            icon: Icons.folder_special_rounded,
            iconColor: Colors.teal,
            title: '自定义分类',
            subtitle: _settings.customCategories.isEmpty
                ? '暂无自定义分类'
                : '${_settings.customCategories.length} 个自定义分类',
            onTap: () => _showCategoriesDialog(context),
          ),
          _buildListTile(
            context,
            icon: Icons.swap_vert_rounded,
            iconColor: Colors.deepOrange,
            title: '分类显示顺序',
            subtitle: '调整主页分类的显示顺序',
            onTap: () => _showCategoriesOrderDialog(context),
          ),

          const Divider(height: 32),

          // 关于
          _buildSectionHeader(context, '关于'),
          _buildListTile(
            context,
            icon: Icons.info_rounded,
            iconColor: Colors.teal,
            title: '版本',
            subtitle: '1.0.0',
            onTap: () {},
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withAlpha(26),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withAlpha(26),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }

  void _showThemeModeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('选择主题模式'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption(
              context,
              ThemeMode.system,
              '跟随系统',
              Icons.brightness_auto_rounded,
            ),
            _buildThemeOption(
              context,
              ThemeMode.light,
              '浅色模式',
              Icons.light_mode_rounded,
            ),
            _buildThemeOption(
              context,
              ThemeMode.dark,
              '深色模式',
              Icons.dark_mode_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    ThemeMode mode,
    String label,
    IconData icon,
  ) {
    final isSelected = _settings.themeMode == mode;
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(icon, color: isSelected ? theme.primaryColor : Colors.grey),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? theme.primaryColor : null,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_rounded, color: theme.primaryColor)
          : null,
      onTap: () {
        _settings.setThemeMode(mode);
        Navigator.pop(context);
      },
    );
  }

  void _showGridColumnsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('选择网格列数'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [2, 3, 4, 5].map((columns) {
            final isSelected = _settings.gridColumns == columns;
            final theme = Theme.of(context);

            return ListTile(
              leading: Icon(
                Icons.grid_view_rounded,
                color: isSelected ? theme.primaryColor : Colors.grey,
              ),
              title: Text(
                '$columns 列',
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? theme.primaryColor : null,
                ),
              ),
              trailing: isSelected
                  ? Icon(Icons.check_rounded, color: theme.primaryColor)
                  : null,
              onTap: () {
                _settings.setGridColumns(columns);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showStartupCategoryDialog(BuildContext context) {
    // 获取所有可用的分类选项
    final categories = ['全部', '收藏', ..._settings.customCategories];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('启动时显示的分类'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = _settings.startupCategory == category;
              final theme = Theme.of(context);

              return ListTile(
                leading: Icon(
                  index == 0
                      ? Icons.all_inclusive_rounded
                      : index == 1
                      ? Icons.favorite_rounded
                      : Icons.folder_rounded,
                  color: isSelected ? theme.primaryColor : Colors.grey,
                ),
                title: Text(
                  category,
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isSelected ? theme.primaryColor : null,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_rounded, color: theme.primaryColor)
                    : null,
                onTap: () {
                  _settings.setStartupCategory(category);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showCategoriesDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('管理分类'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 添加新分类
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          hintText: '输入新分类名称',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () async {
                        if (controller.text.trim().isNotEmpty) {
                          await _settings.addCategory(controller.text.trim());
                          controller.clear();
                          setDialogState(() {});
                        }
                      },
                      icon: Icon(
                        Icons.add_circle_rounded,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 分类列表
                if (_settings.customCategories.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      '暂无自定义分类',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _settings.customCategories.length,
                      itemBuilder: (context, index) {
                        final category = _settings.customCategories[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.folder_rounded),
                          title: Text(category),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_rounded,
                              color: Colors.red,
                            ),
                            onPressed: () async {
                              // 显示删除分类的对话框
                              await _showDeleteCategoryDialog(category);
                              setDialogState(() {});
                            },
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
              onPressed: () => Navigator.pop(context),
              child: const Text('完成'),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示删除分类对话框
  Future<void> _showDeleteCategoryDialog(String category) async {
    final soundsInCategory = await _databaseService.getSoundsByCategory(
      category,
    );

    if (!mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除分类'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('确定要删除分类 "$category" 吗？'),
            const SizedBox(height: 12),
            if (soundsInCategory.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withAlpha(77)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '该分类下有 ${soundsInCategory.length} 个音效',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '请选择处理方式：',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              const Text(
                '该分类下没有音效，删除后无法恢复。',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          if (soundsInCategory.isNotEmpty) ...[
            // 移动到默认分类
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _databaseService.migrateCategoryForSounds(category, '默认');
                await _settings.removeCategory(category);
                _onDataChanged?.call();
                if (!mounted) return;
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      '已将 ${soundsInCategory.length} 个音效移至"默认"分类',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('移到默认分类'),
            ),
            // 删除分类和音效
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _databaseService.deleteSoundsByCategory(category);
                await _settings.removeCategory(category);
                _onDataChanged?.call();
                if (!mounted) return;
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('已删除分类及其下的 ${soundsInCategory.length} 个音效'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.red,
                  ),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('删除分类和音效'),
            ),
          ] else
            // 如果分类下没有音效，直接删除
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _settings.removeCategory(category);
                _onDataChanged?.call();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('删除'),
            ),
        ],
      ),
    );
  }

  /// 显示导入示例音效对话框
  Future<void> _showImportSamplesDialog(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('导入示例音效包'),
        content: const Text(
          '是否导入示例音效包？\n\n'
          '这是一套精心准备的精选音效，帮助您快速体验应用功能。\n\n'
          '您也可以在"导出文件管理"中找到此音效包并随时导入。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _importSamplePack();
            },
            child: const Text('导入'),
          ),
        ],
      ),
    );
  }

  /// 导入示例音效包（从预制的 .msb 文件导入）
  Future<void> _importSamplePack() async {
    try {
      // 使用 ImportExportService 从 asset 导入示例音效包
      final result = await _importExportService.importFromAsset(
        AppConstants.samplePackAssetPath,
      );

      // 触发主屏幕的刷新回调
      _onDataChanged?.call();

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
            content: Text('导入失败: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 显示分类顺序调整对话框
  void _showCategoriesOrderDialog(BuildContext context) {
    final categories = List<String>.from(_settings.allCategories);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('调整分类顺序'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '长按拖动以调整顺序',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ReorderableListView(
                    shrinkWrap: true,
                    onReorder: (oldIndex, newIndex) {
                      setDialogState(() {
                        if (newIndex > oldIndex) {
                          newIndex -= 1;
                        }
                        final item = categories.removeAt(oldIndex);
                        categories.insert(newIndex, item);
                      });
                    },
                    children: [
                      for (int i = 0; i < categories.length; i++)
                        ListTile(
                          key: ValueKey(categories[i]),
                          dense: true,
                          leading: Icon(
                            Icons.drag_handle_rounded,
                            color: Theme.of(context).primaryColor,
                          ),
                          title: Text(categories[i]),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withAlpha(26),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                await _settings.setCategoriesOrder(categories);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('分类顺序已保存'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  /// 打开导出目录
  Future<void> _openExportDirectory(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExportManagerScreen(
          onDataChanged: _onDataChanged,
        ),
      ),
    );
  }
}

