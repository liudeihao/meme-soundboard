import '../l10n/app_localizations.dart';
import 'app_constants.dart';

extension CategoryStoredL10n on AppLocalizations {
  /// Maps persisted category name (Chinese constants) to UI label.
  String categoryLabelForStored(String stored) {
    if (stored == AppConstants.categoryAll) return categoryAll;
    if (stored == AppConstants.categoryFavorites) return categoryFavorites;
    if (stored == AppConstants.categoryDefault) return categoryDefault;
    return stored;
  }
}
