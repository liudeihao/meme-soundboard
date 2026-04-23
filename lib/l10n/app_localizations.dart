import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In zh, this message translates to:
  /// **'梗音效'**
  String get appTitle;

  /// No description provided for @soundCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个音效'**
  String soundCount(int count);

  /// No description provided for @categoryAll.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get categoryAll;

  /// No description provided for @categoryFavorites.
  ///
  /// In zh, this message translates to:
  /// **'收藏'**
  String get categoryFavorites;

  /// No description provided for @categoryDefault.
  ///
  /// In zh, this message translates to:
  /// **'默认'**
  String get categoryDefault;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get close;

  /// No description provided for @save.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @done.
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get done;

  /// No description provided for @delete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get delete;

  /// No description provided for @continueLabel.
  ///
  /// In zh, this message translates to:
  /// **'继续'**
  String get continueLabel;

  /// No description provided for @import.
  ///
  /// In zh, this message translates to:
  /// **'导入'**
  String get import;

  /// No description provided for @unknown.
  ///
  /// In zh, this message translates to:
  /// **'未知'**
  String get unknown;

  /// No description provided for @settings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settings;

  /// No description provided for @sectionAppearance.
  ///
  /// In zh, this message translates to:
  /// **'外观'**
  String get sectionAppearance;

  /// No description provided for @themeMode.
  ///
  /// In zh, this message translates to:
  /// **'主题模式'**
  String get themeMode;

  /// No description provided for @selectThemeMode.
  ///
  /// In zh, this message translates to:
  /// **'选择主题模式'**
  String get selectThemeMode;

  /// No description provided for @themeFollowSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get themeFollowSystem;

  /// No description provided for @themeLight.
  ///
  /// In zh, this message translates to:
  /// **'浅色模式'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In zh, this message translates to:
  /// **'深色模式'**
  String get themeDark;

  /// No description provided for @gridColumns.
  ///
  /// In zh, this message translates to:
  /// **'网格列数'**
  String get gridColumns;

  /// No description provided for @selectGridColumns.
  ///
  /// In zh, this message translates to:
  /// **'选择网格列数'**
  String get selectGridColumns;

  /// No description provided for @columnsCount.
  ///
  /// In zh, this message translates to:
  /// **'{n} 列'**
  String columnsCount(int n);

  /// No description provided for @sectionAudio.
  ///
  /// In zh, this message translates to:
  /// **'音频'**
  String get sectionAudio;

  /// No description provided for @hapticFeedback.
  ///
  /// In zh, this message translates to:
  /// **'触觉反馈'**
  String get hapticFeedback;

  /// No description provided for @hapticFeedbackDesc.
  ///
  /// In zh, this message translates to:
  /// **'点击按钮时震动'**
  String get hapticFeedbackDesc;

  /// No description provided for @allowMultiPlay.
  ///
  /// In zh, this message translates to:
  /// **'同时播放'**
  String get allowMultiPlay;

  /// No description provided for @allowMultiPlayDesc.
  ///
  /// In zh, this message translates to:
  /// **'开启后点击新音效不会中断正在播放的音效'**
  String get allowMultiPlayDesc;

  /// No description provided for @sectionSounds.
  ///
  /// In zh, this message translates to:
  /// **'音效'**
  String get sectionSounds;

  /// No description provided for @importSamplePack.
  ///
  /// In zh, this message translates to:
  /// **'导入示例音效包'**
  String get importSamplePack;

  /// No description provided for @importSamplePackDesc.
  ///
  /// In zh, this message translates to:
  /// **'导入精选示例音效'**
  String get importSamplePackDesc;

  /// No description provided for @startupCategory.
  ///
  /// In zh, this message translates to:
  /// **'启动时显示的分类'**
  String get startupCategory;

  /// No description provided for @sectionDataExport.
  ///
  /// In zh, this message translates to:
  /// **'数据导出'**
  String get sectionDataExport;

  /// No description provided for @manageExportFiles.
  ///
  /// In zh, this message translates to:
  /// **'管理导出文件'**
  String get manageExportFiles;

  /// No description provided for @manageExportFilesDesc.
  ///
  /// In zh, this message translates to:
  /// **'查看、分享、导入导出的文件'**
  String get manageExportFilesDesc;

  /// No description provided for @sectionCategoryMgmt.
  ///
  /// In zh, this message translates to:
  /// **'分类管理'**
  String get sectionCategoryMgmt;

  /// No description provided for @customCategories.
  ///
  /// In zh, this message translates to:
  /// **'自定义分类'**
  String get customCategories;

  /// No description provided for @customCategoriesEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无自定义分类'**
  String get customCategoriesEmpty;

  /// No description provided for @customCategoriesCount.
  ///
  /// In zh, this message translates to:
  /// **'{n} 个自定义分类'**
  String customCategoriesCount(int n);

  /// No description provided for @categoryOrder.
  ///
  /// In zh, this message translates to:
  /// **'分类显示顺序'**
  String get categoryOrder;

  /// No description provided for @categoryOrderDesc.
  ///
  /// In zh, this message translates to:
  /// **'调整主页分类的显示顺序'**
  String get categoryOrderDesc;

  /// No description provided for @about.
  ///
  /// In zh, this message translates to:
  /// **'关于'**
  String get about;

  /// No description provided for @version.
  ///
  /// In zh, this message translates to:
  /// **'版本'**
  String get version;

  /// No description provided for @versionNumber.
  ///
  /// In zh, this message translates to:
  /// **'1.0.0'**
  String get versionNumber;

  /// No description provided for @sectionLanguage.
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get sectionLanguage;

  /// No description provided for @language.
  ///
  /// In zh, this message translates to:
  /// **'界面语言'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get languageSystem;

  /// No description provided for @languageZh.
  ///
  /// In zh, this message translates to:
  /// **'简体中文'**
  String get languageZh;

  /// No description provided for @languageEn.
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @selectLanguage.
  ///
  /// In zh, this message translates to:
  /// **'选择界面语言'**
  String get selectLanguage;

  /// No description provided for @selectImportCategory.
  ///
  /// In zh, this message translates to:
  /// **'选择导入分类'**
  String get selectImportCategory;

  /// No description provided for @pickCategory.
  ///
  /// In zh, this message translates to:
  /// **'选择分类'**
  String get pickCategory;

  /// No description provided for @newCategory.
  ///
  /// In zh, this message translates to:
  /// **'新建分类'**
  String get newCategory;

  /// No description provided for @newCategoryName.
  ///
  /// In zh, this message translates to:
  /// **'新分类名称'**
  String get newCategoryName;

  /// No description provided for @newCategoryHint.
  ///
  /// In zh, this message translates to:
  /// **'输入新分类名称'**
  String get newCategoryHint;

  /// No description provided for @manageCategories.
  ///
  /// In zh, this message translates to:
  /// **'管理分类'**
  String get manageCategories;

  /// No description provided for @deleteCategoryTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除分类'**
  String get deleteCategoryTitle;

  /// No description provided for @deleteCategoryConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除分类 \"{name}\" 吗？'**
  String deleteCategoryConfirm(String name);

  /// No description provided for @deleteCategoryHasSounds.
  ///
  /// In zh, this message translates to:
  /// **'该分类下有 {count} 个音效'**
  String deleteCategoryHasSounds(int count);

  /// No description provided for @deleteCategoryChooseAction.
  ///
  /// In zh, this message translates to:
  /// **'请选择处理方式：'**
  String get deleteCategoryChooseAction;

  /// No description provided for @deleteCategoryNoSounds.
  ///
  /// In zh, this message translates to:
  /// **'该分类下没有音效，删除后无法恢复。'**
  String get deleteCategoryNoSounds;

  /// No description provided for @moveToDefaultCategory.
  ///
  /// In zh, this message translates to:
  /// **'移到默认分类'**
  String get moveToDefaultCategory;

  /// No description provided for @deleteCategoryAndSounds.
  ///
  /// In zh, this message translates to:
  /// **'删除分类和音效'**
  String get deleteCategoryAndSounds;

  /// No description provided for @movedToDefaultSnack.
  ///
  /// In zh, this message translates to:
  /// **'已将 {count} 个音效移至「默认」分类'**
  String movedToDefaultSnack(int count);

  /// No description provided for @deletedCategoryAndSoundsSnack.
  ///
  /// In zh, this message translates to:
  /// **'已删除分类及其下的 {count} 个音效'**
  String deletedCategoryAndSoundsSnack(int count);

  /// No description provided for @importSampleTitle.
  ///
  /// In zh, this message translates to:
  /// **'导入示例音效包'**
  String get importSampleTitle;

  /// No description provided for @importSampleBody.
  ///
  /// In zh, this message translates to:
  /// **'是否导入示例音效包？\n\n这是一套精心准备的精选音效，帮助您快速体验应用功能。\n\n您也可以在「导出文件管理」中找到此音效包并随时导入。'**
  String get importSampleBody;

  /// No description provided for @importFailedWith.
  ///
  /// In zh, this message translates to:
  /// **'导入失败: {error}'**
  String importFailedWith(String error);

  /// No description provided for @reorderCategoriesTitle.
  ///
  /// In zh, this message translates to:
  /// **'调整分类顺序'**
  String get reorderCategoriesTitle;

  /// No description provided for @reorderCategoriesHint.
  ///
  /// In zh, this message translates to:
  /// **'长按拖动以调整顺序'**
  String get reorderCategoriesHint;

  /// No description provided for @categoryOrderSaved.
  ///
  /// In zh, this message translates to:
  /// **'分类顺序已保存'**
  String get categoryOrderSaved;

  /// No description provided for @stopAllSounds.
  ///
  /// In zh, this message translates to:
  /// **'停止所有音效'**
  String get stopAllSounds;

  /// No description provided for @exitMultiSelect.
  ///
  /// In zh, this message translates to:
  /// **'退出多选'**
  String get exitMultiSelect;

  /// No description provided for @multiSelect.
  ///
  /// In zh, this message translates to:
  /// **'多选'**
  String get multiSelect;

  /// No description provided for @importSounds.
  ///
  /// In zh, this message translates to:
  /// **'导入音效'**
  String get importSounds;

  /// No description provided for @exportAll.
  ///
  /// In zh, this message translates to:
  /// **'导出全部'**
  String get exportAll;

  /// No description provided for @exportCurrentCategory.
  ///
  /// In zh, this message translates to:
  /// **'导出当前分类'**
  String get exportCurrentCategory;

  /// No description provided for @soundAddedSuccess.
  ///
  /// In zh, this message translates to:
  /// **'音效添加成功！'**
  String get soundAddedSuccess;

  /// No description provided for @soundDeleted.
  ///
  /// In zh, this message translates to:
  /// **'已删除'**
  String get soundDeleted;

  /// No description provided for @pressAgainToExit.
  ///
  /// In zh, this message translates to:
  /// **'再按一次返回键退出应用'**
  String get pressAgainToExit;

  /// No description provided for @searchHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索音效…'**
  String get searchHint;

  /// No description provided for @noSoundsToExport.
  ///
  /// In zh, this message translates to:
  /// **'没有音效可导出'**
  String get noSoundsToExport;

  /// No description provided for @exportSuccessFullBackup.
  ///
  /// In zh, this message translates to:
  /// **'导出成功（完整备份）'**
  String get exportSuccessFullBackup;

  /// No description provided for @exportCancelled.
  ///
  /// In zh, this message translates to:
  /// **'导出已取消'**
  String get exportCancelled;

  /// No description provided for @exportFailedWith.
  ///
  /// In zh, this message translates to:
  /// **'导出失败: {error}'**
  String exportFailedWith(String error);

  /// No description provided for @currentCategoryEmpty.
  ///
  /// In zh, this message translates to:
  /// **'当前分类没有音效'**
  String get currentCategoryEmpty;

  /// No description provided for @exportSuccessCategory.
  ///
  /// In zh, this message translates to:
  /// **'导出成功（分类）'**
  String get exportSuccessCategory;

  /// No description provided for @exportSuccessMultiple.
  ///
  /// In zh, this message translates to:
  /// **'导出成功（{count} 个音效）'**
  String exportSuccessMultiple(int count);

  /// No description provided for @exportFailed.
  ///
  /// In zh, this message translates to:
  /// **'导出失败'**
  String get exportFailed;

  /// No description provided for @exportSuccessSingle.
  ///
  /// In zh, this message translates to:
  /// **'导出成功（单个音效）'**
  String get exportSuccessSingle;

  /// No description provided for @exportSingleCancelled.
  ///
  /// In zh, this message translates to:
  /// **'导出取消'**
  String get exportSingleCancelled;

  /// No description provided for @deletedSoundsCount.
  ///
  /// In zh, this message translates to:
  /// **'已删除 {count} 个音效'**
  String deletedSoundsCount(int count);

  /// No description provided for @importPreviewTitle.
  ///
  /// In zh, this message translates to:
  /// **'导入预览'**
  String get importPreviewTitle;

  /// No description provided for @fileDetailsTitle.
  ///
  /// In zh, this message translates to:
  /// **'文件详情'**
  String get fileDetailsTitle;

  /// No description provided for @labelFileName.
  ///
  /// In zh, this message translates to:
  /// **'文件名'**
  String get labelFileName;

  /// No description provided for @labelType.
  ///
  /// In zh, this message translates to:
  /// **'类型'**
  String get labelType;

  /// No description provided for @labelSize.
  ///
  /// In zh, this message translates to:
  /// **'大小'**
  String get labelSize;

  /// No description provided for @labelFileTime.
  ///
  /// In zh, this message translates to:
  /// **'文件时间'**
  String get labelFileTime;

  /// No description provided for @labelExportTime.
  ///
  /// In zh, this message translates to:
  /// **'导出时间'**
  String get labelExportTime;

  /// No description provided for @labelCategory.
  ///
  /// In zh, this message translates to:
  /// **'分类'**
  String get labelCategory;

  /// No description provided for @soundsContained.
  ///
  /// In zh, this message translates to:
  /// **'包含的音效 ({count} 个):'**
  String soundsContained(int count);

  /// No description provided for @soundsToImport.
  ///
  /// In zh, this message translates to:
  /// **'将导入的音效 ({count} 个):'**
  String soundsToImport(int count);

  /// No description provided for @typeSoundSingle.
  ///
  /// In zh, this message translates to:
  /// **'单个音效'**
  String get typeSoundSingle;

  /// No description provided for @typeSoundCategory.
  ///
  /// In zh, this message translates to:
  /// **'分类'**
  String get typeSoundCategory;

  /// No description provided for @typeSoundMultiple.
  ///
  /// In zh, this message translates to:
  /// **'多个音效'**
  String get typeSoundMultiple;

  /// No description provided for @typeSoundFull.
  ///
  /// In zh, this message translates to:
  /// **'完整备份'**
  String get typeSoundFull;

  /// No description provided for @typeUnknown.
  ///
  /// In zh, this message translates to:
  /// **'未知'**
  String get typeUnknown;

  /// No description provided for @exportManagerTitle.
  ///
  /// In zh, this message translates to:
  /// **'管理导出文件'**
  String get exportManagerTitle;

  /// No description provided for @refresh.
  ///
  /// In zh, this message translates to:
  /// **'刷新'**
  String get refresh;

  /// No description provided for @exportDirEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无导出文件'**
  String get exportDirEmpty;

  /// No description provided for @exportDirEmptyHint.
  ///
  /// In zh, this message translates to:
  /// **'在主页导出音效后，文件将显示在这里'**
  String get exportDirEmptyHint;

  /// No description provided for @fileOptions.
  ///
  /// In zh, this message translates to:
  /// **'文件选项'**
  String get fileOptions;

  /// No description provided for @fileDetails.
  ///
  /// In zh, this message translates to:
  /// **'文件详情'**
  String get fileDetails;

  /// No description provided for @fileDetailsSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'查看包类型与音效列表'**
  String get fileDetailsSubtitle;

  /// No description provided for @importThisFile.
  ///
  /// In zh, this message translates to:
  /// **'导入'**
  String get importThisFile;

  /// No description provided for @importThisFileSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'将此文件导入到应用'**
  String get importThisFileSubtitle;

  /// No description provided for @share.
  ///
  /// In zh, this message translates to:
  /// **'分享'**
  String get share;

  /// No description provided for @shareSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'分享到微信、QQ 等'**
  String get shareSubtitle;

  /// No description provided for @deleteFile.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get deleteFile;

  /// No description provided for @deleteFileSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'删除此导出文件'**
  String get deleteFileSubtitle;

  /// No description provided for @samplePackNoDeleteSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'示例音效包不可删除'**
  String get samplePackNoDeleteSubtitle;

  /// No description provided for @shareSoundFile.
  ///
  /// In zh, this message translates to:
  /// **'分享音效文件: {name}'**
  String shareSoundFile(String name);

  /// No description provided for @cannotDeleteSamplePack.
  ///
  /// In zh, this message translates to:
  /// **'无法删除示例音效包'**
  String get cannotDeleteSamplePack;

  /// No description provided for @samplePackNoDelete.
  ///
  /// In zh, this message translates to:
  /// **'示例音效包不可删除'**
  String get samplePackNoDelete;

  /// No description provided for @confirmDelete.
  ///
  /// In zh, this message translates to:
  /// **'确认删除'**
  String get confirmDelete;

  /// No description provided for @confirmDeleteFile.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除 \"{name}\" 吗？'**
  String confirmDeleteFile(String name);

  /// No description provided for @deletedOk.
  ///
  /// In zh, this message translates to:
  /// **'已删除'**
  String get deletedOk;

  /// No description provided for @deleteFailedWith.
  ///
  /// In zh, this message translates to:
  /// **'删除失败: {error}'**
  String deleteFailedWith(String error);

  /// No description provided for @readFileFailed.
  ///
  /// In zh, this message translates to:
  /// **'读取文件失败: {error}'**
  String readFileFailed(String error);

  /// No description provided for @unknownFileType.
  ///
  /// In zh, this message translates to:
  /// **'未知的文件类型'**
  String get unknownFileType;

  /// No description provided for @importReadError.
  ///
  /// In zh, this message translates to:
  /// **'读取文件失败: {error}'**
  String importReadError(String error);

  /// No description provided for @fileDetailsReadError.
  ///
  /// In zh, this message translates to:
  /// **'无法读取文件详情: {error}'**
  String fileDetailsReadError(String error);

  /// No description provided for @importFailed.
  ///
  /// In zh, this message translates to:
  /// **'导入失败: {error}'**
  String importFailed(String error);

  /// No description provided for @builtInSampleNoDelete.
  ///
  /// In zh, this message translates to:
  /// **'内置示例 · 不可删除'**
  String get builtInSampleNoDelete;

  /// No description provided for @chooseImportMethod.
  ///
  /// In zh, this message translates to:
  /// **'选择导入方式'**
  String get chooseImportMethod;

  /// No description provided for @howImportCategory.
  ///
  /// In zh, this message translates to:
  /// **'如何导入此分类中的音效？'**
  String get howImportCategory;

  /// No description provided for @keepOriginalCategory.
  ///
  /// In zh, this message translates to:
  /// **'保持原分类'**
  String get keepOriginalCategory;

  /// No description provided for @pickNewCategory.
  ///
  /// In zh, this message translates to:
  /// **'选择新分类'**
  String get pickNewCategory;

  /// No description provided for @importFullBackupTitle.
  ///
  /// In zh, this message translates to:
  /// **'导入完整备份'**
  String get importFullBackupTitle;

  /// No description provided for @importFullBackupBody.
  ///
  /// In zh, this message translates to:
  /// **'完整备份将导入所有音效和设置。'**
  String get importFullBackupBody;

  /// No description provided for @importFullBackupChoose.
  ///
  /// In zh, this message translates to:
  /// **'请选择导入方式：'**
  String get importFullBackupChoose;

  /// No description provided for @mergeIntoExisting.
  ///
  /// In zh, this message translates to:
  /// **'添加到现有数据'**
  String get mergeIntoExisting;

  /// No description provided for @replaceAllData.
  ///
  /// In zh, this message translates to:
  /// **'替换所有数据'**
  String get replaceAllData;

  /// No description provided for @confirmReplaceTitle.
  ///
  /// In zh, this message translates to:
  /// **'确认替换'**
  String get confirmReplaceTitle;

  /// No description provided for @confirmReplaceBody.
  ///
  /// In zh, this message translates to:
  /// **'此操作将删除所有现有的音效和设置，并替换为备份数据。\n\n此操作无法撤销，请确认是否继续。'**
  String get confirmReplaceBody;

  /// No description provided for @confirmReplace.
  ///
  /// In zh, this message translates to:
  /// **'确认替换'**
  String get confirmReplace;

  /// No description provided for @finalConfirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'最终确认'**
  String get finalConfirmTitle;

  /// No description provided for @finalConfirmBody.
  ///
  /// In zh, this message translates to:
  /// **'真的要替换所有数据吗？这是您最后的机会。'**
  String get finalConfirmBody;

  /// No description provided for @confirmReplaceAll.
  ///
  /// In zh, this message translates to:
  /// **'确认，替换所有数据'**
  String get confirmReplaceAll;

  /// No description provided for @exportNameTitle.
  ///
  /// In zh, this message translates to:
  /// **'指定导出名称'**
  String get exportNameTitle;

  /// No description provided for @exportNameHint.
  ///
  /// In zh, this message translates to:
  /// **'请输入导出文件名'**
  String get exportNameHint;

  /// No description provided for @confirm.
  ///
  /// In zh, this message translates to:
  /// **'确定'**
  String get confirm;

  /// No description provided for @pickExportZip.
  ///
  /// In zh, this message translates to:
  /// **'导出为压缩包'**
  String get pickExportZip;

  /// No description provided for @pickExportZipSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'将 {count} 个音效打包导出'**
  String pickExportZipSubtitle(int count);

  /// No description provided for @pickExportSeparate.
  ///
  /// In zh, this message translates to:
  /// **'导出为单独文件'**
  String get pickExportSeparate;

  /// No description provided for @pickExportSeparateSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'分别导出 {count} 个音效'**
  String pickExportSeparateSubtitle(int count);

  /// No description provided for @export.
  ///
  /// In zh, this message translates to:
  /// **'导出'**
  String get export;

  /// No description provided for @notValidPackFile.
  ///
  /// In zh, this message translates to:
  /// **'不是有效的音效包文件'**
  String get notValidPackFile;

  /// No description provided for @invalidImportFormat.
  ///
  /// In zh, this message translates to:
  /// **'无效的导入文件格式'**
  String get invalidImportFormat;

  /// No description provided for @importErrorGeneric.
  ///
  /// In zh, this message translates to:
  /// **'导入失败: {error}'**
  String importErrorGeneric(String error);

  /// No description provided for @importNoFile.
  ///
  /// In zh, this message translates to:
  /// **'未选择文件'**
  String get importNoFile;

  /// No description provided for @importFileMissing.
  ///
  /// In zh, this message translates to:
  /// **'文件不存在'**
  String get importFileMissing;

  /// No description provided for @importSampleFailed.
  ///
  /// In zh, this message translates to:
  /// **'导入示例音效包失败: {error}'**
  String importSampleFailed(String error);

  /// No description provided for @importParseFailed.
  ///
  /// In zh, this message translates to:
  /// **'解析失败: {error}'**
  String importParseFailed(String error);

  /// No description provided for @importUnknownType.
  ///
  /// In zh, this message translates to:
  /// **'未知的导入类型: {type}'**
  String importUnknownType(String type);

  /// No description provided for @importJsonFailed.
  ///
  /// In zh, this message translates to:
  /// **'JSON解析失败: {error}'**
  String importJsonFailed(String error);

  /// No description provided for @importSoundFailedWith.
  ///
  /// In zh, this message translates to:
  /// **'导入音效失败: {detail}'**
  String importSoundFailedWith(String detail);

  /// No description provided for @cannotParseSoundData.
  ///
  /// In zh, this message translates to:
  /// **'无法解析文件数据'**
  String get cannotParseSoundData;

  /// No description provided for @importSoundSuccessNamed.
  ///
  /// In zh, this message translates to:
  /// **'成功导入音效: {name}'**
  String importSoundSuccessNamed(String name);

  /// No description provided for @importCategoryFailedWith.
  ///
  /// In zh, this message translates to:
  /// **'导入分类失败: {error}'**
  String importCategoryFailedWith(String error);

  /// No description provided for @importBackupFailedWith.
  ///
  /// In zh, this message translates to:
  /// **'导入备份失败: {error}'**
  String importBackupFailedWith(String error);

  /// No description provided for @successImportCategoryCount.
  ///
  /// In zh, this message translates to:
  /// **'成功导入分类「{category}」中的 {count} 个音效'**
  String successImportCategoryCount(String category, int count);

  /// No description provided for @successImportCount.
  ///
  /// In zh, this message translates to:
  /// **'成功导入 {count} 个音效'**
  String successImportCount(int count);

  /// No description provided for @importFailuresLine.
  ///
  /// In zh, this message translates to:
  /// **'\n失败 {failed} 个: {detail}'**
  String importFailuresLine(int failed, String detail);

  /// No description provided for @unknownError.
  ///
  /// In zh, this message translates to:
  /// **'未知错误'**
  String get unknownError;

  /// No description provided for @audioTrimFailed.
  ///
  /// In zh, this message translates to:
  /// **'音频截取失败:\n{msg}'**
  String audioTrimFailed(String msg);

  /// No description provided for @addSoundTitle.
  ///
  /// In zh, this message translates to:
  /// **'添加音效'**
  String get addSoundTitle;

  /// No description provided for @editSoundTitle.
  ///
  /// In zh, this message translates to:
  /// **'编辑音效'**
  String get editSoundTitle;

  /// No description provided for @audioSource.
  ///
  /// In zh, this message translates to:
  /// **'音频来源'**
  String get audioSource;

  /// No description provided for @sourceFile.
  ///
  /// In zh, this message translates to:
  /// **'文件'**
  String get sourceFile;

  /// No description provided for @sourceUrl.
  ///
  /// In zh, this message translates to:
  /// **'链接'**
  String get sourceUrl;

  /// No description provided for @audioUrlHint.
  ///
  /// In zh, this message translates to:
  /// **'输入音频链接 (http:// 或 https://)'**
  String get audioUrlHint;

  /// No description provided for @pickAudioFile.
  ///
  /// In zh, this message translates to:
  /// **'选择音频文件 *'**
  String get pickAudioFile;

  /// No description provided for @pickedAudio.
  ///
  /// In zh, this message translates to:
  /// **'已选择: {name}'**
  String pickedAudio(String name);

  /// No description provided for @clearLink.
  ///
  /// In zh, this message translates to:
  /// **'清空链接'**
  String get clearLink;

  /// No description provided for @loading.
  ///
  /// In zh, this message translates to:
  /// **'加载中...'**
  String get loading;

  /// No description provided for @preview.
  ///
  /// In zh, this message translates to:
  /// **'预览'**
  String get preview;

  /// No description provided for @stopPlayback.
  ///
  /// In zh, this message translates to:
  /// **'停止播放'**
  String get stopPlayback;

  /// No description provided for @coverImage.
  ///
  /// In zh, this message translates to:
  /// **'封面图片'**
  String get coverImage;

  /// No description provided for @imageUrlHint.
  ///
  /// In zh, this message translates to:
  /// **'输入图片链接 (可选)'**
  String get imageUrlHint;

  /// No description provided for @pickCoverOptional.
  ///
  /// In zh, this message translates to:
  /// **'选择封面图片 (可选)'**
  String get pickCoverOptional;

  /// No description provided for @coverSelected.
  ///
  /// In zh, this message translates to:
  /// **'已选择封面图片'**
  String get coverSelected;

  /// No description provided for @removeCover.
  ///
  /// In zh, this message translates to:
  /// **'删除封面图片'**
  String get removeCover;

  /// No description provided for @soundName.
  ///
  /// In zh, this message translates to:
  /// **'音效名称'**
  String get soundName;

  /// No description provided for @soundNameHint.
  ///
  /// In zh, this message translates to:
  /// **'输入音效名称'**
  String get soundNameHint;

  /// No description provided for @categoryLabel.
  ///
  /// In zh, this message translates to:
  /// **'分类'**
  String get categoryLabel;

  /// No description provided for @soundSettings.
  ///
  /// In zh, this message translates to:
  /// **'音效设置'**
  String get soundSettings;

  /// No description provided for @previewAudioFirst.
  ///
  /// In zh, this message translates to:
  /// **'请先预览音频'**
  String get previewAudioFirst;

  /// No description provided for @addSoundButton.
  ///
  /// In zh, this message translates to:
  /// **'添加音效'**
  String get addSoundButton;

  /// No description provided for @saveChanges.
  ///
  /// In zh, this message translates to:
  /// **'保存更改'**
  String get saveChanges;

  /// No description provided for @pickAudioFirst.
  ///
  /// In zh, this message translates to:
  /// **'请先选择音频文件或输入链接'**
  String get pickAudioFirst;

  /// No description provided for @needSoundName.
  ///
  /// In zh, this message translates to:
  /// **'请输入音效名称'**
  String get needSoundName;

  /// No description provided for @urlMustHttp.
  ///
  /// In zh, this message translates to:
  /// **'音频链接必须以 http:// 或 https:// 开头'**
  String get urlMustHttp;

  /// No description provided for @fileNotExist.
  ///
  /// In zh, this message translates to:
  /// **'音频文件不存在或已被删除'**
  String get fileNotExist;

  /// No description provided for @playbackFailed.
  ///
  /// In zh, this message translates to:
  /// **'播放失败: {error}'**
  String playbackFailed(String error);

  /// No description provided for @trimSectionTitle.
  ///
  /// In zh, this message translates to:
  /// **'截取片段'**
  String get trimSectionTitle;

  /// No description provided for @trimCannotReadDuration.
  ///
  /// In zh, this message translates to:
  /// **'无法读取时长，将保存完整音频。'**
  String get trimCannotReadDuration;

  /// No description provided for @trimPreviewFailed.
  ///
  /// In zh, this message translates to:
  /// **'片段预览失败: {error}'**
  String trimPreviewFailed(String error);

  /// No description provided for @trimPreviewPlay.
  ///
  /// In zh, this message translates to:
  /// **'试听片段'**
  String get trimPreviewPlay;

  /// No description provided for @trimPreviewStop.
  ///
  /// In zh, this message translates to:
  /// **'停止片段'**
  String get trimPreviewStop;

  /// No description provided for @trimHint.
  ///
  /// In zh, this message translates to:
  /// **'添加时将仅保留所选区间（导出为 M4A）。Windows / Linux 需已安装 ffmpeg。'**
  String get trimHint;

  /// No description provided for @needDownloadFirst.
  ///
  /// In zh, this message translates to:
  /// **'请先预览以下载音频'**
  String get needDownloadFirst;

  /// No description provided for @clipboardCopied.
  ///
  /// In zh, this message translates to:
  /// **'已复制到剪切板'**
  String get clipboardCopied;

  /// No description provided for @onboardingTitle.
  ///
  /// In zh, this message translates to:
  /// **'欢迎使用！'**
  String get onboardingTitle;

  /// No description provided for @onboardingSampleBody.
  ///
  /// In zh, this message translates to:
  /// **'是否导入示例音效包？\n\n我们精心准备了一套精选音效供您体验\n\n稍后您也可以通过「导出文件管理」中找到示例音效包并导入'**
  String get onboardingSampleBody;

  /// No description provided for @skip.
  ///
  /// In zh, this message translates to:
  /// **'跳过'**
  String get skip;

  /// No description provided for @toastFavoriteAdded.
  ///
  /// In zh, this message translates to:
  /// **'已添加到收藏'**
  String get toastFavoriteAdded;

  /// No description provided for @toastFavoriteRemoved.
  ///
  /// In zh, this message translates to:
  /// **'已取消收藏'**
  String get toastFavoriteRemoved;

  /// No description provided for @detailName.
  ///
  /// In zh, this message translates to:
  /// **'名称'**
  String get detailName;

  /// No description provided for @detailCategory.
  ///
  /// In zh, this message translates to:
  /// **'分类'**
  String get detailCategory;

  /// No description provided for @detailFavorite.
  ///
  /// In zh, this message translates to:
  /// **'收藏'**
  String get detailFavorite;

  /// No description provided for @favoriteYes.
  ///
  /// In zh, this message translates to:
  /// **'是'**
  String get favoriteYes;

  /// No description provided for @favoriteNo.
  ///
  /// In zh, this message translates to:
  /// **'否'**
  String get favoriteNo;

  /// No description provided for @detailSourceType.
  ///
  /// In zh, this message translates to:
  /// **'来源类型'**
  String get detailSourceType;

  /// No description provided for @sourceTypeBuiltin.
  ///
  /// In zh, this message translates to:
  /// **'内置资源'**
  String get sourceTypeBuiltin;

  /// No description provided for @sourceTypeLocalFile.
  ///
  /// In zh, this message translates to:
  /// **'本地文件'**
  String get sourceTypeLocalFile;

  /// No description provided for @sourceTypeNetwork.
  ///
  /// In zh, this message translates to:
  /// **'网络链接'**
  String get sourceTypeNetwork;

  /// No description provided for @detailSoundPath.
  ///
  /// In zh, this message translates to:
  /// **'音频路径'**
  String get detailSoundPath;

  /// No description provided for @detailImagePath.
  ///
  /// In zh, this message translates to:
  /// **'图片路径'**
  String get detailImagePath;

  /// No description provided for @moveToCategoryTitle.
  ///
  /// In zh, this message translates to:
  /// **'移动到分类'**
  String get moveToCategoryTitle;

  /// No description provided for @confirmDeleteSoundsTitle.
  ///
  /// In zh, this message translates to:
  /// **'确认删除'**
  String get confirmDeleteSoundsTitle;

  /// No description provided for @confirmDeleteSoundsBody.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除 {count} 个音效吗？此操作无法撤销。'**
  String confirmDeleteSoundsBody(int count);

  /// No description provided for @confirmDeleteSingleSoundBody.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除「{name}」吗？此操作不可恢复。'**
  String confirmDeleteSingleSoundBody(String name);

  /// No description provided for @selectedCount.
  ///
  /// In zh, this message translates to:
  /// **'已选 {count}'**
  String selectedCount(int count);

  /// No description provided for @selectAll.
  ///
  /// In zh, this message translates to:
  /// **'全选'**
  String get selectAll;

  /// No description provided for @move.
  ///
  /// In zh, this message translates to:
  /// **'移动'**
  String get move;

  /// No description provided for @fabAdd.
  ///
  /// In zh, this message translates to:
  /// **'添加'**
  String get fabAdd;

  /// No description provided for @emptyFavorites.
  ///
  /// In zh, this message translates to:
  /// **'还没有收藏的音效'**
  String get emptyFavorites;

  /// No description provided for @emptySearch.
  ///
  /// In zh, this message translates to:
  /// **'没有找到匹配的音效'**
  String get emptySearch;

  /// No description provided for @emptyCategory.
  ///
  /// In zh, this message translates to:
  /// **'这个分类还没有音效'**
  String get emptyCategory;

  /// No description provided for @movedSoundsToCategory.
  ///
  /// In zh, this message translates to:
  /// **'已将 {count} 个音效移动到 {category}'**
  String movedSoundsToCategory(int count, String category);

  /// No description provided for @saveAudioFileTitle.
  ///
  /// In zh, this message translates to:
  /// **'保存音频文件'**
  String get saveAudioFileTitle;

  /// No description provided for @saveAudioFileHint.
  ///
  /// In zh, this message translates to:
  /// **'请输入文件名'**
  String get saveAudioFileHint;

  /// No description provided for @audioSaveSuccess.
  ///
  /// In zh, this message translates to:
  /// **'音频保存成功'**
  String get audioSaveSuccess;

  /// No description provided for @imageSaveSuccess.
  ///
  /// In zh, this message translates to:
  /// **'图片保存成功'**
  String get imageSaveSuccess;

  /// No description provided for @saveCancelledGeneric.
  ///
  /// In zh, this message translates to:
  /// **'保存取消'**
  String get saveCancelledGeneric;

  /// No description provided for @saveFailedWith.
  ///
  /// In zh, this message translates to:
  /// **'保存失败: {error}'**
  String saveFailedWith(String error);

  /// No description provided for @shareFailedWith.
  ///
  /// In zh, this message translates to:
  /// **'分享失败: {error}'**
  String shareFailedWith(String error);

  /// No description provided for @exportDirUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'无法获取导出目录'**
  String get exportDirUnavailable;

  /// No description provided for @dialogSaveExportLocation.
  ///
  /// In zh, this message translates to:
  /// **'选择导出位置'**
  String get dialogSaveExportLocation;

  /// No description provided for @dialogPickImportFile.
  ///
  /// In zh, this message translates to:
  /// **'选择导入文件'**
  String get dialogPickImportFile;

  /// No description provided for @soundTileCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个音效'**
  String soundTileCount(int count);

  /// No description provided for @unfavorite.
  ///
  /// In zh, this message translates to:
  /// **'取消收藏'**
  String get unfavorite;

  /// No description provided for @favoriteAdd.
  ///
  /// In zh, this message translates to:
  /// **'添加到收藏'**
  String get favoriteAdd;

  /// No description provided for @exportAsMsb.
  ///
  /// In zh, this message translates to:
  /// **'导出为 .msb 文件'**
  String get exportAsMsb;

  /// No description provided for @saveAudioFileAction.
  ///
  /// In zh, this message translates to:
  /// **'保存音频文件'**
  String get saveAudioFileAction;

  /// No description provided for @saveCoverImageAction.
  ///
  /// In zh, this message translates to:
  /// **'保存封面图片'**
  String get saveCoverImageAction;

  /// No description provided for @viewDetails.
  ///
  /// In zh, this message translates to:
  /// **'查看详情'**
  String get viewDetails;

  /// No description provided for @edit.
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get edit;

  /// No description provided for @previewName.
  ///
  /// In zh, this message translates to:
  /// **'预览'**
  String get previewName;

  /// No description provided for @downloadAudioFailed.
  ///
  /// In zh, this message translates to:
  /// **'下载音频失败:\n{msg}'**
  String downloadAudioFailed(String msg);

  /// No description provided for @exceptionPickAudioFirst.
  ///
  /// In zh, this message translates to:
  /// **'请先选择音频文件或输入链接'**
  String get exceptionPickAudioFirst;

  /// No description provided for @exportCancelledException.
  ///
  /// In zh, this message translates to:
  /// **'导出取消'**
  String get exportCancelledException;

  /// No description provided for @defaultExportBackupName.
  ///
  /// In zh, this message translates to:
  /// **'梗音效备份'**
  String get defaultExportBackupName;

  /// No description provided for @defaultExportMultiName.
  ///
  /// In zh, this message translates to:
  /// **'音效合集'**
  String get defaultExportMultiName;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
