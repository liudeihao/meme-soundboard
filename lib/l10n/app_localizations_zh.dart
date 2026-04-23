// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '梗音效';

  @override
  String soundCount(int count) {
    return '$count 个音效';
  }

  @override
  String get categoryAll => '全部';

  @override
  String get categoryFavorites => '收藏';

  @override
  String get categoryDefault => '默认';

  @override
  String get cancel => '取消';

  @override
  String get close => '关闭';

  @override
  String get save => '保存';

  @override
  String get done => '完成';

  @override
  String get delete => '删除';

  @override
  String get continueLabel => '继续';

  @override
  String get import => '导入';

  @override
  String get unknown => '未知';

  @override
  String get settings => '设置';

  @override
  String get sectionAppearance => '外观';

  @override
  String get themeMode => '主题模式';

  @override
  String get selectThemeMode => '选择主题模式';

  @override
  String get themeFollowSystem => '跟随系统';

  @override
  String get themeLight => '浅色模式';

  @override
  String get themeDark => '深色模式';

  @override
  String get gridColumns => '网格列数';

  @override
  String get selectGridColumns => '选择网格列数';

  @override
  String columnsCount(int n) {
    return '$n 列';
  }

  @override
  String get sectionAudio => '音频';

  @override
  String get hapticFeedback => '触觉反馈';

  @override
  String get hapticFeedbackDesc => '点击按钮时震动';

  @override
  String get allowMultiPlay => '同时播放';

  @override
  String get allowMultiPlayDesc => '开启后点击新音效不会中断正在播放的音效';

  @override
  String get sectionSounds => '音效';

  @override
  String get importSamplePack => '导入示例音效包';

  @override
  String get importSamplePackDesc => '导入精选示例音效';

  @override
  String get startupCategory => '启动时显示的分类';

  @override
  String get sectionDataExport => '数据导出';

  @override
  String get manageExportFiles => '管理导出文件';

  @override
  String get manageExportFilesDesc => '查看、分享、导入导出的文件';

  @override
  String get sectionCategoryMgmt => '分类管理';

  @override
  String get customCategories => '自定义分类';

  @override
  String get customCategoriesEmpty => '暂无自定义分类';

  @override
  String customCategoriesCount(int n) {
    return '$n 个自定义分类';
  }

  @override
  String get categoryOrder => '分类显示顺序';

  @override
  String get categoryOrderDesc => '调整主页分类的显示顺序';

  @override
  String get about => '关于';

  @override
  String get version => '版本';

  @override
  String get versionNumber => '1.0.0';

  @override
  String get sectionLanguage => '语言';

  @override
  String get language => '界面语言';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get languageZh => '简体中文';

  @override
  String get languageEn => 'English';

  @override
  String get selectLanguage => '选择界面语言';

  @override
  String get selectImportCategory => '选择导入分类';

  @override
  String get pickCategory => '选择分类';

  @override
  String get newCategory => '新建分类';

  @override
  String get newCategoryName => '新分类名称';

  @override
  String get newCategoryHint => '输入新分类名称';

  @override
  String get manageCategories => '管理分类';

  @override
  String get deleteCategoryTitle => '删除分类';

  @override
  String deleteCategoryConfirm(String name) {
    return '确定要删除分类 \"$name\" 吗？';
  }

  @override
  String deleteCategoryHasSounds(int count) {
    return '该分类下有 $count 个音效';
  }

  @override
  String get deleteCategoryChooseAction => '请选择处理方式：';

  @override
  String get deleteCategoryNoSounds => '该分类下没有音效，删除后无法恢复。';

  @override
  String get moveToDefaultCategory => '移到默认分类';

  @override
  String get deleteCategoryAndSounds => '删除分类和音效';

  @override
  String movedToDefaultSnack(int count) {
    return '已将 $count 个音效移至「默认」分类';
  }

  @override
  String deletedCategoryAndSoundsSnack(int count) {
    return '已删除分类及其下的 $count 个音效';
  }

  @override
  String get importSampleTitle => '导入示例音效包';

  @override
  String get importSampleBody =>
      '是否导入示例音效包？\n\n这是一套精心准备的精选音效，帮助您快速体验应用功能。\n\n您也可以在「导出文件管理」中找到此音效包并随时导入。';

  @override
  String importFailedWith(String error) {
    return '导入失败: $error';
  }

  @override
  String get reorderCategoriesTitle => '调整分类顺序';

  @override
  String get reorderCategoriesHint => '长按拖动以调整顺序';

  @override
  String get categoryOrderSaved => '分类顺序已保存';

  @override
  String get stopAllSounds => '停止所有音效';

  @override
  String get exitMultiSelect => '退出多选';

  @override
  String get multiSelect => '多选';

  @override
  String get importSounds => '导入音效';

  @override
  String get exportAll => '导出全部';

  @override
  String get exportCurrentCategory => '导出当前分类';

  @override
  String get soundAddedSuccess => '音效添加成功！';

  @override
  String get soundDeleted => '已删除';

  @override
  String get pressAgainToExit => '再按一次返回键退出应用';

  @override
  String get searchHint => '搜索音效…';

  @override
  String get noSoundsToExport => '没有音效可导出';

  @override
  String get exportSuccessFullBackup => '导出成功（完整备份）';

  @override
  String get exportCancelled => '导出已取消';

  @override
  String exportFailedWith(String error) {
    return '导出失败: $error';
  }

  @override
  String get currentCategoryEmpty => '当前分类没有音效';

  @override
  String get exportSuccessCategory => '导出成功（分类）';

  @override
  String exportSuccessMultiple(int count) {
    return '导出成功（$count 个音效）';
  }

  @override
  String get exportFailed => '导出失败';

  @override
  String get exportSuccessSingle => '导出成功（单个音效）';

  @override
  String get exportSingleCancelled => '导出取消';

  @override
  String deletedSoundsCount(int count) {
    return '已删除 $count 个音效';
  }

  @override
  String get importPreviewTitle => '导入预览';

  @override
  String get fileDetailsTitle => '文件详情';

  @override
  String get labelFileName => '文件名';

  @override
  String get labelType => '类型';

  @override
  String get labelSize => '大小';

  @override
  String get labelFileTime => '文件时间';

  @override
  String get labelExportTime => '导出时间';

  @override
  String get labelCategory => '分类';

  @override
  String soundsContained(int count) {
    return '包含的音效 ($count 个):';
  }

  @override
  String soundsToImport(int count) {
    return '将导入的音效 ($count 个):';
  }

  @override
  String get typeSoundSingle => '单个音效';

  @override
  String get typeSoundCategory => '分类';

  @override
  String get typeSoundMultiple => '多个音效';

  @override
  String get typeSoundFull => '完整备份';

  @override
  String get typeUnknown => '未知';

  @override
  String get exportManagerTitle => '管理导出文件';

  @override
  String get refresh => '刷新';

  @override
  String get exportDirEmpty => '暂无导出文件';

  @override
  String get exportDirEmptyHint => '在主页导出音效后，文件将显示在这里';

  @override
  String get fileOptions => '文件选项';

  @override
  String get fileDetails => '文件详情';

  @override
  String get fileDetailsSubtitle => '查看包类型与音效列表';

  @override
  String get importThisFile => '导入';

  @override
  String get importThisFileSubtitle => '将此文件导入到应用';

  @override
  String get share => '分享';

  @override
  String get shareSubtitle => '分享到微信、QQ 等';

  @override
  String get deleteFile => '删除';

  @override
  String get deleteFileSubtitle => '删除此导出文件';

  @override
  String get samplePackNoDeleteSubtitle => '示例音效包不可删除';

  @override
  String shareSoundFile(String name) {
    return '分享音效文件: $name';
  }

  @override
  String get cannotDeleteSamplePack => '无法删除示例音效包';

  @override
  String get samplePackNoDelete => '示例音效包不可删除';

  @override
  String get confirmDelete => '确认删除';

  @override
  String confirmDeleteFile(String name) {
    return '确定要删除 \"$name\" 吗？';
  }

  @override
  String get deletedOk => '已删除';

  @override
  String deleteFailedWith(String error) {
    return '删除失败: $error';
  }

  @override
  String readFileFailed(String error) {
    return '读取文件失败: $error';
  }

  @override
  String get unknownFileType => '未知的文件类型';

  @override
  String importReadError(String error) {
    return '读取文件失败: $error';
  }

  @override
  String fileDetailsReadError(String error) {
    return '无法读取文件详情: $error';
  }

  @override
  String importFailed(String error) {
    return '导入失败: $error';
  }

  @override
  String get builtInSampleNoDelete => '内置示例 · 不可删除';

  @override
  String get chooseImportMethod => '选择导入方式';

  @override
  String get howImportCategory => '如何导入此分类中的音效？';

  @override
  String get keepOriginalCategory => '保持原分类';

  @override
  String get pickNewCategory => '选择新分类';

  @override
  String get importFullBackupTitle => '导入完整备份';

  @override
  String get importFullBackupBody => '完整备份将导入所有音效和设置。';

  @override
  String get importFullBackupChoose => '请选择导入方式：';

  @override
  String get mergeIntoExisting => '添加到现有数据';

  @override
  String get replaceAllData => '替换所有数据';

  @override
  String get confirmReplaceTitle => '确认替换';

  @override
  String get confirmReplaceBody =>
      '此操作将删除所有现有的音效和设置，并替换为备份数据。\n\n此操作无法撤销，请确认是否继续。';

  @override
  String get confirmReplace => '确认替换';

  @override
  String get finalConfirmTitle => '最终确认';

  @override
  String get finalConfirmBody => '真的要替换所有数据吗？这是您最后的机会。';

  @override
  String get confirmReplaceAll => '确认，替换所有数据';

  @override
  String get exportNameTitle => '指定导出名称';

  @override
  String get exportNameHint => '请输入导出文件名';

  @override
  String get confirm => '确定';

  @override
  String get pickExportZip => '导出为压缩包';

  @override
  String pickExportZipSubtitle(int count) {
    return '将 $count 个音效打包导出';
  }

  @override
  String get pickExportSeparate => '导出为单独文件';

  @override
  String pickExportSeparateSubtitle(int count) {
    return '分别导出 $count 个音效';
  }

  @override
  String get export => '导出';

  @override
  String get notValidPackFile => '不是有效的音效包文件';

  @override
  String get invalidImportFormat => '无效的导入文件格式';

  @override
  String importErrorGeneric(String error) {
    return '导入失败: $error';
  }

  @override
  String get importNoFile => '未选择文件';

  @override
  String get importFileMissing => '文件不存在';

  @override
  String importSampleFailed(String error) {
    return '导入示例音效包失败: $error';
  }

  @override
  String importParseFailed(String error) {
    return '解析失败: $error';
  }

  @override
  String importUnknownType(String type) {
    return '未知的导入类型: $type';
  }

  @override
  String importJsonFailed(String error) {
    return 'JSON解析失败: $error';
  }

  @override
  String importSoundFailedWith(String detail) {
    return '导入音效失败: $detail';
  }

  @override
  String get cannotParseSoundData => '无法解析文件数据';

  @override
  String importSoundSuccessNamed(String name) {
    return '成功导入音效: $name';
  }

  @override
  String importCategoryFailedWith(String error) {
    return '导入分类失败: $error';
  }

  @override
  String importBackupFailedWith(String error) {
    return '导入备份失败: $error';
  }

  @override
  String successImportCategoryCount(String category, int count) {
    return '成功导入分类「$category」中的 $count 个音效';
  }

  @override
  String successImportCount(int count) {
    return '成功导入 $count 个音效';
  }

  @override
  String importFailuresLine(int failed, String detail) {
    return '\n失败 $failed 个: $detail';
  }

  @override
  String get unknownError => '未知错误';

  @override
  String audioTrimFailed(String msg) {
    return '音频截取失败:\n$msg';
  }

  @override
  String get addSoundTitle => '添加音效';

  @override
  String get editSoundTitle => '编辑音效';

  @override
  String get audioSource => '音频来源';

  @override
  String get sourceFile => '文件';

  @override
  String get sourceUrl => '链接';

  @override
  String get audioUrlHint => '输入音频链接 (http:// 或 https://)';

  @override
  String get pickAudioFile => '选择音频文件 *';

  @override
  String pickedAudio(String name) {
    return '已选择: $name';
  }

  @override
  String get clearLink => '清空链接';

  @override
  String get loading => '加载中...';

  @override
  String get preview => '预览';

  @override
  String get stopPlayback => '停止播放';

  @override
  String get coverImage => '封面图片';

  @override
  String get imageUrlHint => '输入图片链接 (可选)';

  @override
  String get pickCoverOptional => '选择封面图片 (可选)';

  @override
  String get coverSelected => '已选择封面图片';

  @override
  String get removeCover => '删除封面图片';

  @override
  String get soundName => '音效名称';

  @override
  String get soundNameHint => '输入音效名称';

  @override
  String get categoryLabel => '分类';

  @override
  String get soundSettings => '音效设置';

  @override
  String get previewAudioFirst => '请先预览音频';

  @override
  String get addSoundButton => '添加音效';

  @override
  String get saveChanges => '保存更改';

  @override
  String get pickAudioFirst => '请先选择音频文件或输入链接';

  @override
  String get needSoundName => '请输入音效名称';

  @override
  String get urlMustHttp => '音频链接必须以 http:// 或 https:// 开头';

  @override
  String get fileNotExist => '音频文件不存在或已被删除';

  @override
  String playbackFailed(String error) {
    return '播放失败: $error';
  }

  @override
  String get trimSectionTitle => '截取片段';

  @override
  String get trimCannotReadDuration => '无法读取时长，将保存完整音频。';

  @override
  String trimPreviewFailed(String error) {
    return '片段预览失败: $error';
  }

  @override
  String get trimPreviewPlay => '试听片段';

  @override
  String get trimPreviewStop => '停止片段';

  @override
  String get trimHint => '添加时将仅保留所选区间（导出为 M4A）。Windows / Linux 需已安装 ffmpeg。';

  @override
  String get needDownloadFirst => '请先预览以下载音频';

  @override
  String get clipboardCopied => '已复制到剪切板';

  @override
  String get onboardingTitle => '欢迎使用！';

  @override
  String get onboardingSampleBody =>
      '是否导入示例音效包？\n\n我们精心准备了一套精选音效供您体验\n\n稍后您也可以通过「导出文件管理」中找到示例音效包并导入';

  @override
  String get skip => '跳过';

  @override
  String get toastFavoriteAdded => '已添加到收藏';

  @override
  String get toastFavoriteRemoved => '已取消收藏';

  @override
  String get detailName => '名称';

  @override
  String get detailCategory => '分类';

  @override
  String get detailFavorite => '收藏';

  @override
  String get favoriteYes => '是';

  @override
  String get favoriteNo => '否';

  @override
  String get detailSourceType => '来源类型';

  @override
  String get sourceTypeBuiltin => '内置资源';

  @override
  String get sourceTypeLocalFile => '本地文件';

  @override
  String get sourceTypeNetwork => '网络链接';

  @override
  String get detailSoundPath => '音频路径';

  @override
  String get detailImagePath => '图片路径';

  @override
  String get moveToCategoryTitle => '移动到分类';

  @override
  String get confirmDeleteSoundsTitle => '确认删除';

  @override
  String confirmDeleteSoundsBody(int count) {
    return '确定要删除 $count 个音效吗？此操作无法撤销。';
  }

  @override
  String confirmDeleteSingleSoundBody(String name) {
    return '确定要删除「$name」吗？此操作不可恢复。';
  }

  @override
  String selectedCount(int count) {
    return '已选 $count';
  }

  @override
  String get selectAll => '全选';

  @override
  String get move => '移动';

  @override
  String get fabAdd => '添加';

  @override
  String get emptyFavorites => '还没有收藏的音效';

  @override
  String get emptySearch => '没有找到匹配的音效';

  @override
  String get emptyCategory => '这个分类还没有音效';

  @override
  String movedSoundsToCategory(int count, String category) {
    return '已将 $count 个音效移动到 $category';
  }

  @override
  String get saveAudioFileTitle => '保存音频文件';

  @override
  String get saveAudioFileHint => '请输入文件名';

  @override
  String get audioSaveSuccess => '音频保存成功';

  @override
  String get imageSaveSuccess => '图片保存成功';

  @override
  String get saveCancelledGeneric => '保存取消';

  @override
  String saveFailedWith(String error) {
    return '保存失败: $error';
  }

  @override
  String shareFailedWith(String error) {
    return '分享失败: $error';
  }

  @override
  String get exportDirUnavailable => '无法获取导出目录';

  @override
  String get dialogSaveExportLocation => '选择导出位置';

  @override
  String get dialogPickImportFile => '选择导入文件';

  @override
  String soundTileCount(int count) {
    return '$count 个音效';
  }

  @override
  String get unfavorite => '取消收藏';

  @override
  String get favoriteAdd => '添加到收藏';

  @override
  String get exportAsMsb => '导出为 .msb 文件';

  @override
  String get saveAudioFileAction => '保存音频文件';

  @override
  String get saveCoverImageAction => '保存封面图片';

  @override
  String get viewDetails => '查看详情';

  @override
  String get edit => '编辑';

  @override
  String get previewName => '预览';

  @override
  String downloadAudioFailed(String msg) {
    return '下载音频失败:\n$msg';
  }

  @override
  String get exceptionPickAudioFirst => '请先选择音频文件或输入链接';

  @override
  String get exportCancelledException => '导出取消';

  @override
  String get defaultExportBackupName => '梗音效备份';

  @override
  String get defaultExportMultiName => '音效合集';
}
