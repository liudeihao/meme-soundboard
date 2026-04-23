import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/settings_service.dart';
import '../services/database_service.dart';
import '../services/import_export_service.dart';
import '../utils/app_constants.dart';
import '../utils/category_l10n.dart';
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

  String _themeSubtitle(AppLocalizations l10n) {
    switch (_settings.themeMode) {
      case ThemeMode.system:
        return l10n.themeFollowSystem;
      case ThemeMode.light:
        return l10n.themeLight;
      case ThemeMode.dark:
        return l10n.themeDark;
    }
  }

  String _uiLocaleSubtitle(AppLocalizations l10n) {
    switch (_settings.uiLocale) {
      case SettingsService.uiLocaleZh:
        return l10n.languageZh;
      case SettingsService.uiLocaleEn:
        return l10n.languageEn;
      default:
        return l10n.languageSystem;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings), centerTitle: true),
      body: ListView(
        children: [
          _buildSectionHeader(context, l10n.sectionAppearance),
          _buildListTile(
            context,
            icon: Icons.palette_rounded,
            iconColor: Colors.purple,
            title: l10n.themeMode,
            subtitle: _themeSubtitle(l10n),
            onTap: () => _showThemeModeDialog(context),
          ),
          _buildListTile(
            context,
            icon: Icons.grid_view_rounded,
            iconColor: Colors.blue,
            title: l10n.gridColumns,
            subtitle: l10n.columnsCount(_settings.gridColumns),
            onTap: () => _showGridColumnsDialog(context),
          ),

          const Divider(height: 32),

          _buildSectionHeader(context, l10n.sectionLanguage),
          _buildListTile(
            context,
            icon: Icons.language_rounded,
            iconColor: Colors.indigo,
            title: l10n.language,
            subtitle: _uiLocaleSubtitle(l10n),
            onTap: () => _showUiLocaleDialog(context),
          ),

          const Divider(height: 32),

          _buildSectionHeader(context, l10n.sectionAudio),
          _buildSwitchTile(
            context,
            icon: Icons.vibration_rounded,
            iconColor: Colors.orange,
            title: l10n.hapticFeedback,
            subtitle: l10n.hapticFeedbackDesc,
            value: _settings.hapticFeedback,
            onChanged: (value) => _settings.setHapticFeedback(value),
          ),
          _buildSwitchTile(
            context,
            icon: Icons.multitrack_audio_rounded,
            iconColor: Colors.green,
            title: l10n.allowMultiPlay,
            subtitle: l10n.allowMultiPlayDesc,
            value: _settings.allowMultiPlay,
            onChanged: (value) => _settings.setAllowMultiPlay(value),
          ),

          const Divider(height: 32),

          _buildSectionHeader(context, l10n.sectionSounds),
          _buildListTile(
            context,
            icon: Icons.music_note_rounded,
            iconColor: Colors.blue,
            title: l10n.importSamplePack,
            subtitle: l10n.importSamplePackDesc,
            onTap: () => _showImportSamplesDialog(context),
          ),
          _buildListTile(
            context,
            icon: Icons.play_circle_outline_rounded,
            iconColor: Colors.green,
            title: l10n.startupCategory,
            subtitle: l10n.categoryLabelForStored(_settings.startupCategory),
            onTap: () => _showStartupCategoryDialog(context),
          ),

          const Divider(height: 32),

          _buildSectionHeader(context, l10n.sectionDataExport),
          _buildListTile(
            context,
            icon: Icons.folder_open_rounded,
            iconColor: Colors.amber,
            title: l10n.manageExportFiles,
            subtitle: l10n.manageExportFilesDesc,
            onTap: () => _openExportDirectory(context),
          ),

          const Divider(height: 32),

          _buildSectionHeader(context, l10n.sectionCategoryMgmt),
          _buildListTile(
            context,
            icon: Icons.folder_special_rounded,
            iconColor: Colors.teal,
            title: l10n.customCategories,
            subtitle: _settings.customCategories.isEmpty
                ? l10n.customCategoriesEmpty
                : l10n.customCategoriesCount(_settings.customCategories.length),
            onTap: () => _showCategoriesDialog(context),
          ),
          _buildListTile(
            context,
            icon: Icons.swap_vert_rounded,
            iconColor: Colors.deepOrange,
            title: l10n.categoryOrder,
            subtitle: l10n.categoryOrderDesc,
            onTap: () => _showCategoriesOrderDialog(context),
          ),

          const Divider(height: 32),

          _buildSectionHeader(context, l10n.about),
          _buildListTile(
            context,
            icon: Icons.info_rounded,
            iconColor: Colors.teal,
            title: l10n.version,
            subtitle: l10n.versionNumber,
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
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.selectThemeMode),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption(
              context,
              ThemeMode.system,
              l10n.themeFollowSystem,
              Icons.brightness_auto_rounded,
            ),
            _buildThemeOption(
              context,
              ThemeMode.light,
              l10n.themeLight,
              Icons.light_mode_rounded,
            ),
            _buildThemeOption(
              context,
              ThemeMode.dark,
              l10n.themeDark,
              Icons.dark_mode_rounded,
            ),
          ],
        ),
      ),
    );
  }

  void _showUiLocaleDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.selectLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildUiLocaleOption(
              dialogContext,
              SettingsService.uiLocaleSystem,
              l10n.languageSystem,
              Icons.language_rounded,
            ),
            _buildUiLocaleOption(
              dialogContext,
              SettingsService.uiLocaleZh,
              l10n.languageZh,
              Icons.translate_rounded,
            ),
            _buildUiLocaleOption(
              dialogContext,
              SettingsService.uiLocaleEn,
              l10n.languageEn,
              Icons.text_fields_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUiLocaleOption(
    BuildContext context,
    String code,
    String label,
    IconData icon,
  ) {
    final isSelected = _settings.uiLocale == code;
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
        _settings.setUiLocale(code);
        Navigator.pop(context);
      },
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
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.selectGridColumns),
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
                l10n.columnsCount(columns),
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
    final l10n = AppLocalizations.of(context)!;
    final categories = [
      AppConstants.categoryAll,
      AppConstants.categoryFavorites,
      ..._settings.customCategories,
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.startupCategory),
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
                  l10n.categoryLabelForStored(category),
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
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(l10n.manageCategories),
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
                          hintText: l10n.newCategoryHint,
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
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      l10n.customCategoriesEmpty,
                      style: const TextStyle(color: Colors.grey),
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
              child: Text(l10n.done),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示删除分类对话框
  Future<void> _showDeleteCategoryDialog(String category) async {
    final l10n = AppLocalizations.of(context)!;
    final soundsInCategory = await _databaseService.getSoundsByCategory(
      category,
    );

    if (!mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteCategoryTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.deleteCategoryConfirm(category)),
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
                      l10n.deleteCategoryHasSounds(soundsInCategory.length),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.deleteCategoryChooseAction,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              Text(
                l10n.deleteCategoryNoSounds,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          if (soundsInCategory.isNotEmpty) ...[
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _databaseService.migrateCategoryForSounds(
                  category,
                  AppConstants.categoryDefault,
                );
                await _settings.removeCategory(category);
                _onDataChanged?.call();
                if (!mounted) return;
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n.movedToDefaultSnack(soundsInCategory.length),
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Text(l10n.moveToDefaultCategory),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _databaseService.deleteSoundsByCategory(category);
                await _settings.removeCategory(category);
                _onDataChanged?.call();
                if (!mounted) return;
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n.deletedCategoryAndSoundsSnack(
                        soundsInCategory.length,
                      ),
                    ),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.red,
                  ),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(l10n.deleteCategoryAndSounds),
            ),
          ] else
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _settings.removeCategory(category);
                _onDataChanged?.call();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(l10n.delete),
            ),
        ],
      ),
    );
  }

  /// 显示导入示例音效对话框
  Future<void> _showImportSamplesDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.importSampleTitle),
        content: Text(l10n.importSampleBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
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
            content: Text(l10n.importFailedWith(e.toString())),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 显示分类顺序调整对话框
  void _showCategoriesOrderDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categories = List<String>.from(_settings.allCategories);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(l10n.reorderCategoriesTitle),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.reorderCategoriesHint,
                  style: const TextStyle(
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
                          title: Text(l10n.categoryLabelForStored(categories[i])),
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
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () async {
                await _settings.setCategoriesOrder(categories);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.categoryOrderSaved),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: Text(l10n.save),
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

