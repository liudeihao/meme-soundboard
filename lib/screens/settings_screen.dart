import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/database_service.dart';
import '../services/file_service.dart';
import '../utils/built_in_sounds.dart';

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
  late final FileService _fileService;

  VoidCallback? get _onDataChanged => widget.onDataChanged;

  @override
  void initState() {
    super.initState();
    _fileService = FileService();
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
            subtitle: '允许多个音效同时播放',
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
            title: '导入示例音效',
            subtitle: '导入4个示例音效',
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          if (soundsInCategory.isNotEmpty) ...[
            // 移动到默认分类
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _databaseService.migrateCategoryForSounds(category, '默认');
                await _settings.removeCategory(category);
                _onDataChanged?.call();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '已将 ${soundsInCategory.length} 个音效移至"默认"分类',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('移到默认分类'),
            ),
            // 删除分类和音效
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _databaseService.deleteSoundsByCategory(category);
                await _settings.removeCategory(category);
                _onDataChanged?.call();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('已删除分类及其下的 ${soundsInCategory.length} 个音效'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('删除分类和音效'),
            ),
          ] else
            // 如果分类下没有音效，直接删除
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
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
        title: const Text('导入示例音效'),
        content: const Text(
          '是否导入1个示例音效？\n\n'
          '这将导入Bruh猫',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
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
      final importedSounds = <String>[];
      for (final builtInSound in BuiltInSounds.all) {
        // 从 assets 复制文件到应用私有目录
        final importedSound = await _fileService.importBuiltInSound(
          builtInSound,
        );
        importedSounds.add(importedSound.name);
        // 保存到数据库
        await _databaseService.insertSound(importedSound);
      }

      // 触发主屏幕的刷新回调
      _onDataChanged?.call();

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
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
