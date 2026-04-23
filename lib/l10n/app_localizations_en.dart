// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Meme Soundboard';

  @override
  String soundCount(int count) {
    return '$count sounds';
  }

  @override
  String get categoryAll => 'All';

  @override
  String get categoryFavorites => 'Favorites';

  @override
  String get categoryDefault => 'Default';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get save => 'Save';

  @override
  String get done => 'Done';

  @override
  String get delete => 'Delete';

  @override
  String get continueLabel => 'Continue';

  @override
  String get import => 'Import';

  @override
  String get unknown => 'Unknown';

  @override
  String get settings => 'Settings';

  @override
  String get sectionAppearance => 'Appearance';

  @override
  String get themeMode => 'Theme';

  @override
  String get selectThemeMode => 'Choose theme';

  @override
  String get themeFollowSystem => 'Use system setting';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get gridColumns => 'Grid columns';

  @override
  String get selectGridColumns => 'Choose column count';

  @override
  String columnsCount(int n) {
    return '$n columns';
  }

  @override
  String get sectionAudio => 'Audio';

  @override
  String get hapticFeedback => 'Haptic feedback';

  @override
  String get hapticFeedbackDesc => 'Vibrate when tapping buttons';

  @override
  String get allowMultiPlay => 'Allow overlap';

  @override
  String get allowMultiPlayDesc => 'New taps won’t stop sounds already playing';

  @override
  String get sectionSounds => 'Sounds';

  @override
  String get importSamplePack => 'Import sample pack';

  @override
  String get importSamplePackDesc => 'Import curated sample sounds';

  @override
  String get startupCategory => 'Category on startup';

  @override
  String get sectionDataExport => 'Data & export';

  @override
  String get manageExportFiles => 'Manage export files';

  @override
  String get manageExportFilesDesc => 'View, share, and import exported packs';

  @override
  String get sectionCategoryMgmt => 'Categories';

  @override
  String get customCategories => 'Custom categories';

  @override
  String get customCategoriesEmpty => 'No custom categories yet';

  @override
  String customCategoriesCount(int n) {
    return '$n custom categories';
  }

  @override
  String get categoryOrder => 'Category order';

  @override
  String get categoryOrderDesc => 'Reorder categories on the home screen';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get versionNumber => '1.0.0';

  @override
  String get sectionLanguage => 'Language';

  @override
  String get language => 'App language';

  @override
  String get languageSystem => 'Use system setting';

  @override
  String get languageZh => '简体中文';

  @override
  String get languageEn => 'English';

  @override
  String get selectLanguage => 'Choose app language';

  @override
  String get selectImportCategory => 'Choose import category';

  @override
  String get pickCategory => 'Category';

  @override
  String get newCategory => 'New category';

  @override
  String get newCategoryName => 'New category name';

  @override
  String get newCategoryHint => 'Enter a category name';

  @override
  String get manageCategories => 'Manage categories';

  @override
  String get deleteCategoryTitle => 'Delete category';

  @override
  String deleteCategoryConfirm(String name) {
    return 'Delete category \"$name\"?';
  }

  @override
  String deleteCategoryHasSounds(int count) {
    return 'This category has $count sounds';
  }

  @override
  String get deleteCategoryChooseAction => 'Choose what to do:';

  @override
  String get deleteCategoryNoSounds =>
      'No sounds in this category. This cannot be undone.';

  @override
  String get moveToDefaultCategory => 'Move to Default';

  @override
  String get deleteCategoryAndSounds => 'Delete category & sounds';

  @override
  String movedToDefaultSnack(int count) {
    return 'Moved $count sounds to \"Default\"';
  }

  @override
  String deletedCategoryAndSoundsSnack(int count) {
    return 'Deleted category and $count sounds';
  }

  @override
  String get importSampleTitle => 'Import sample pack';

  @override
  String get importSampleBody =>
      'Import the sample sound pack?\n\nIt’s a curated set to help you try the app.\n\nYou can also import it anytime from Export file manager.';

  @override
  String importFailedWith(String error) {
    return 'Import failed: $error';
  }

  @override
  String get reorderCategoriesTitle => 'Reorder categories';

  @override
  String get reorderCategoriesHint => 'Long-press and drag to reorder';

  @override
  String get categoryOrderSaved => 'Category order saved';

  @override
  String get stopAllSounds => 'Stop all sounds';

  @override
  String get exitMultiSelect => 'Exit selection';

  @override
  String get multiSelect => 'Select';

  @override
  String get importSounds => 'Import sounds';

  @override
  String get exportAll => 'Export all';

  @override
  String get exportCurrentCategory => 'Export this category';

  @override
  String get soundAddedSuccess => 'Sound added.';

  @override
  String get soundDeleted => 'Deleted';

  @override
  String get pressAgainToExit => 'Press back again to exit';

  @override
  String get searchHint => 'Search sounds…';

  @override
  String get noSoundsToExport => 'Nothing to export';

  @override
  String get exportSuccessFullBackup => 'Exported (full backup)';

  @override
  String get exportCancelled => 'Export cancelled';

  @override
  String exportFailedWith(String error) {
    return 'Export failed: $error';
  }

  @override
  String get currentCategoryEmpty => 'No sounds in this category';

  @override
  String get exportSuccessCategory => 'Exported (category)';

  @override
  String exportSuccessMultiple(int count) {
    return 'Exported $count sounds';
  }

  @override
  String get exportFailed => 'Export failed';

  @override
  String get exportSuccessSingle => 'Exported (single sound)';

  @override
  String get exportSingleCancelled => 'Export cancelled';

  @override
  String deletedSoundsCount(int count) {
    return 'Deleted $count sounds';
  }

  @override
  String get importPreviewTitle => 'Import preview';

  @override
  String get fileDetailsTitle => 'File details';

  @override
  String get labelFileName => 'File name';

  @override
  String get labelType => 'Type';

  @override
  String get labelSize => 'Size';

  @override
  String get labelFileTime => 'File time';

  @override
  String get labelExportTime => 'Exported at';

  @override
  String get labelCategory => 'Category';

  @override
  String soundsContained(int count) {
    return 'Sounds in pack ($count):';
  }

  @override
  String soundsToImport(int count) {
    return 'Sounds to import ($count):';
  }

  @override
  String get typeSoundSingle => 'Single sound';

  @override
  String get typeSoundCategory => 'Category pack';

  @override
  String get typeSoundMultiple => 'Multiple sounds';

  @override
  String get typeSoundFull => 'Full backup';

  @override
  String get typeUnknown => 'Unknown';

  @override
  String get exportManagerTitle => 'Export files';

  @override
  String get refresh => 'Refresh';

  @override
  String get exportDirEmpty => 'No export files yet';

  @override
  String get exportDirEmptyHint =>
      'Export from the home screen to see files here';

  @override
  String get fileOptions => 'File options';

  @override
  String get fileDetails => 'Details';

  @override
  String get fileDetailsSubtitle => 'Type and sound list';

  @override
  String get importThisFile => 'Import';

  @override
  String get importThisFileSubtitle => 'Import into the app';

  @override
  String get share => 'Share';

  @override
  String get shareSubtitle => 'Share via other apps';

  @override
  String get deleteFile => 'Delete';

  @override
  String get deleteFileSubtitle => 'Remove this file';

  @override
  String get samplePackNoDeleteSubtitle => 'Sample pack can’t be deleted';

  @override
  String shareSoundFile(String name) {
    return 'Share: $name';
  }

  @override
  String get cannotDeleteSamplePack => 'The sample pack can’t be deleted';

  @override
  String get samplePackNoDelete => 'Sample pack can’t be deleted';

  @override
  String get confirmDelete => 'Delete?';

  @override
  String confirmDeleteFile(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get deletedOk => 'Deleted';

  @override
  String deleteFailedWith(String error) {
    return 'Delete failed: $error';
  }

  @override
  String readFileFailed(String error) {
    return 'Couldn’t read file: $error';
  }

  @override
  String get unknownFileType => 'Unknown file type';

  @override
  String importReadError(String error) {
    return 'Couldn’t read file: $error';
  }

  @override
  String fileDetailsReadError(String error) {
    return 'Couldn’t read details: $error';
  }

  @override
  String importFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String get builtInSampleNoDelete => 'Built-in sample · can’t delete';

  @override
  String get chooseImportMethod => 'Import method';

  @override
  String get howImportCategory => 'How should this category pack be imported?';

  @override
  String get keepOriginalCategory => 'Keep categories';

  @override
  String get pickNewCategory => 'Pick new category';

  @override
  String get importFullBackupTitle => 'Import full backup';

  @override
  String get importFullBackupBody => 'Imports all sounds and settings.';

  @override
  String get importFullBackupChoose => 'Choose how to import:';

  @override
  String get mergeIntoExisting => 'Merge into current data';

  @override
  String get replaceAllData => 'Replace everything';

  @override
  String get confirmReplaceTitle => 'Replace all data?';

  @override
  String get confirmReplaceBody =>
      'This removes all current sounds and settings and replaces them with the backup.\n\nThis can’t be undone.';

  @override
  String get confirmReplace => 'Replace';

  @override
  String get finalConfirmTitle => 'Last chance';

  @override
  String get finalConfirmBody => 'Really replace all data?';

  @override
  String get confirmReplaceAll => 'Yes, replace all';

  @override
  String get exportNameTitle => 'Export name';

  @override
  String get exportNameHint => 'File name';

  @override
  String get confirm => 'OK';

  @override
  String get pickExportZip => 'Export as one pack';

  @override
  String pickExportZipSubtitle(int count) {
    return 'Pack $count sounds';
  }

  @override
  String get pickExportSeparate => 'Export separately';

  @override
  String pickExportSeparateSubtitle(int count) {
    return 'Export $count files';
  }

  @override
  String get export => 'Export';

  @override
  String get notValidPackFile => 'Not a valid sound pack file';

  @override
  String get invalidImportFormat => 'Invalid pack format';

  @override
  String importErrorGeneric(String error) {
    return 'Import failed: $error';
  }

  @override
  String get importNoFile => 'No file selected';

  @override
  String get importFileMissing => 'File not found';

  @override
  String importSampleFailed(String error) {
    return 'Sample import failed: $error';
  }

  @override
  String importParseFailed(String error) {
    return 'Parse failed: $error';
  }

  @override
  String importUnknownType(String type) {
    return 'Unknown pack type: $type';
  }

  @override
  String importJsonFailed(String error) {
    return 'JSON error: $error';
  }

  @override
  String importSoundFailedWith(String detail) {
    return 'Import failed: $detail';
  }

  @override
  String get cannotParseSoundData => 'Couldn’t parse sound data';

  @override
  String importSoundSuccessNamed(String name) {
    return 'Imported: $name';
  }

  @override
  String importCategoryFailedWith(String error) {
    return 'Category import failed: $error';
  }

  @override
  String importBackupFailedWith(String error) {
    return 'Backup import failed: $error';
  }

  @override
  String successImportCategoryCount(String category, int count) {
    return 'Imported $count sounds from \"$category\"';
  }

  @override
  String successImportCount(int count) {
    return 'Imported $count sounds';
  }

  @override
  String importFailuresLine(int failed, String detail) {
    return '\nFailed $failed: $detail';
  }

  @override
  String get unknownError => 'Unknown error';

  @override
  String audioTrimFailed(String msg) {
    return 'Couldn’t trim audio:\n$msg';
  }

  @override
  String get addSoundTitle => 'Add sound';

  @override
  String get editSoundTitle => 'Edit sound';

  @override
  String get audioSource => 'Audio source';

  @override
  String get sourceFile => 'File';

  @override
  String get sourceUrl => 'URL';

  @override
  String get audioUrlHint => 'Audio URL (http:// or https://)';

  @override
  String get pickAudioFile => 'Choose audio file *';

  @override
  String pickedAudio(String name) {
    return 'Selected: $name';
  }

  @override
  String get clearLink => 'Clear';

  @override
  String get loading => 'Loading…';

  @override
  String get preview => 'Preview';

  @override
  String get stopPlayback => 'Stop';

  @override
  String get coverImage => 'Cover image';

  @override
  String get imageUrlHint => 'Image URL (optional)';

  @override
  String get pickCoverOptional => 'Choose cover (optional)';

  @override
  String get coverSelected => 'Cover selected';

  @override
  String get removeCover => 'Remove cover';

  @override
  String get soundName => 'Name';

  @override
  String get soundNameHint => 'Sound name';

  @override
  String get categoryLabel => 'Category';

  @override
  String get soundSettings => 'Sound settings';

  @override
  String get previewAudioFirst => 'Preview the audio first';

  @override
  String get addSoundButton => 'Add sound';

  @override
  String get saveChanges => 'Save';

  @override
  String get pickAudioFirst => 'Choose a file or enter a URL';

  @override
  String get needSoundName => 'Enter a name';

  @override
  String get urlMustHttp => 'URL must start with http:// or https://';

  @override
  String get fileNotExist => 'File missing or removed';

  @override
  String playbackFailed(String error) {
    return 'Playback failed: $error';
  }

  @override
  String get trimSectionTitle => 'Trim clip';

  @override
  String get trimCannotReadDuration =>
      'Couldn’t read duration; full file will be saved.';

  @override
  String trimPreviewFailed(String error) {
    return 'Clip preview failed: $error';
  }

  @override
  String get trimPreviewPlay => 'Preview clip';

  @override
  String get trimPreviewStop => 'Stop clip';

  @override
  String get trimHint =>
      'Only the selected range is saved (M4A). Windows/Linux need ffmpeg in PATH.';

  @override
  String get needDownloadFirst => 'Preview once to download the URL';

  @override
  String get clipboardCopied => 'Copied';

  @override
  String get onboardingTitle => 'Welcome!';

  @override
  String get onboardingSampleBody =>
      'Import the sample sound pack?\n\nWe’ve put together a curated set for you to try.\n\nYou can also import it later from Export file manager.';

  @override
  String get skip => 'Skip';

  @override
  String get toastFavoriteAdded => 'Added to favorites';

  @override
  String get toastFavoriteRemoved => 'Removed from favorites';

  @override
  String get detailName => 'Name';

  @override
  String get detailCategory => 'Category';

  @override
  String get detailFavorite => 'Favorite';

  @override
  String get favoriteYes => 'Yes';

  @override
  String get favoriteNo => 'No';

  @override
  String get detailSourceType => 'Source';

  @override
  String get sourceTypeBuiltin => 'Built-in';

  @override
  String get sourceTypeLocalFile => 'Local file';

  @override
  String get sourceTypeNetwork => 'URL';

  @override
  String get detailSoundPath => 'Audio path';

  @override
  String get detailImagePath => 'Image path';

  @override
  String get moveToCategoryTitle => 'Move to category';

  @override
  String get confirmDeleteSoundsTitle => 'Delete sounds?';

  @override
  String confirmDeleteSoundsBody(int count) {
    return 'Delete $count sounds? This can’t be undone.';
  }

  @override
  String confirmDeleteSingleSoundBody(String name) {
    return 'Delete \"$name\"? This can’t be undone.';
  }

  @override
  String selectedCount(int count) {
    return 'Selected $count';
  }

  @override
  String get selectAll => 'Select all';

  @override
  String get move => 'Move';

  @override
  String get fabAdd => 'Add';

  @override
  String get emptyFavorites => 'No favorites yet';

  @override
  String get emptySearch => 'No matching sounds';

  @override
  String get emptyCategory => 'No sounds in this category';

  @override
  String movedSoundsToCategory(int count, String category) {
    return 'Moved $count sounds to $category';
  }

  @override
  String get saveAudioFileTitle => 'Save audio file';

  @override
  String get saveAudioFileHint => 'File name';

  @override
  String get audioSaveSuccess => 'Audio saved';

  @override
  String get imageSaveSuccess => 'Image saved';

  @override
  String get saveCancelledGeneric => 'Save cancelled';

  @override
  String saveFailedWith(String error) {
    return 'Save failed: $error';
  }

  @override
  String shareFailedWith(String error) {
    return 'Share failed: $error';
  }

  @override
  String get exportDirUnavailable => 'Couldn’t get export folder';

  @override
  String get dialogSaveExportLocation => 'Choose where to save';

  @override
  String get dialogPickImportFile => 'Choose file to import';

  @override
  String soundTileCount(int count) {
    return '$count sounds';
  }

  @override
  String get unfavorite => 'Remove from favorites';

  @override
  String get favoriteAdd => 'Add to favorites';

  @override
  String get exportAsMsb => 'Export as .msb';

  @override
  String get saveAudioFileAction => 'Save audio file';

  @override
  String get saveCoverImageAction => 'Save cover image';

  @override
  String get viewDetails => 'View details';

  @override
  String get edit => 'Edit';

  @override
  String get previewName => 'Preview';

  @override
  String downloadAudioFailed(String msg) {
    return 'Download failed:\n$msg';
  }

  @override
  String get exceptionPickAudioFirst => 'Choose a file or enter a URL first';

  @override
  String get exportCancelledException => 'Export cancelled';

  @override
  String get defaultExportBackupName => 'meme_soundboard_backup';

  @override
  String get defaultExportMultiName => 'sound_collection';
}
