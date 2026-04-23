import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../utils/category_l10n.dart';

/// Shared "import preview" for .msb packs (home import, external open, export manager).
class MsbImportPreviewDialog {
  static String typeLabel(AppLocalizations l10n, String type) {
    switch (type) {
      case 'sound':
        return l10n.typeSoundSingle;
      case 'category':
        return l10n.typeSoundCategory;
      case 'multiple':
        return l10n.typeSoundMultiple;
      case 'full':
        return l10n.typeSoundFull;
      default:
        return l10n.typeUnknown;
    }
  }

  static String sizeLabel(int? bytes) {
    if (bytes == null) return '—';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static IconData typeIcon(String type) {
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

  static DateTime? _parseExportDate(Map<String, dynamic> json) {
    final exportedAt = json['exportedAt'] as String?;
    if (exportedAt == null) return null;
    try {
      return DateTime.parse(exportedAt);
    } catch (_) {
      return null;
    }
  }

  static ({String type, List<String> soundNames, String? categoryName}) _parseSounds(
    Map<String, dynamic> json,
    AppLocalizations l10n,
  ) {
    final type = json['type'] as String? ?? 'unknown';
    final soundNames = <String>[];
    String? categoryName;

    if (type == 'sound') {
      final data = json['data'] as Map<String, dynamic>?;
      if (data != null) {
        soundNames.add(data['name'] as String? ?? l10n.unknown);
      }
    } else if (type == 'category') {
      categoryName = json['category'] as String?;
      final data = json['data'] as List?;
      if (data != null) {
        for (final item in data) {
          if (item is Map<String, dynamic>) {
            soundNames.add(item['name'] as String? ?? l10n.unknown);
          }
        }
      }
    } else if (type == 'multiple' || type == 'full') {
      final sounds = json['sounds'] as List?;
      if (sounds != null) {
        for (final item in sounds) {
          if (item is Map<String, dynamic>) {
            soundNames.add(item['name'] as String? ?? l10n.unknown);
          }
        }
      }
    }

    return (type: type, soundNames: soundNames, categoryName: categoryName);
  }

  static Widget buildPackPreviewBody(
    BuildContext context, {
    required AppLocalizations l10n,
    required String displayName,
    required Map<String, dynamic> json,
    int? sizeBytes,
    DateTime? modifiedTime,
    required String soundSectionTitle,
  }) {
    final parsed = _parseSounds(json, l10n);
    final type = parsed.type;
    final soundNames = parsed.soundNames;
    final categoryName = parsed.categoryName;
    final exportDate = _parseExportDate(json);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _previewRow(l10n.labelFileName, displayName),
        _previewRow(l10n.labelType, typeLabel(l10n, type)),
        _previewRow(l10n.labelSize, sizeLabel(sizeBytes)),
        if (modifiedTime != null)
          _previewRow(
            l10n.labelFileTime,
            DateFormat('yyyy-MM-dd HH:mm').format(modifiedTime),
          ),
        if (exportDate != null)
          _previewRow(
            l10n.labelExportTime,
            DateFormat('yyyy-MM-dd HH:mm').format(exportDate),
          ),
        if (categoryName != null)
          _previewRow(
            l10n.labelCategory,
            l10n.categoryLabelForStored(categoryName),
          ),
        const SizedBox(height: 12),
        Text(
          soundSectionTitle,
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
    );
  }

  static Future<void> showPackDetails(
    BuildContext context, {
    required String displayName,
    required Map<String, dynamic> json,
    int? sizeBytes,
    DateTime? modifiedTime,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final parsed = _parseSounds(json, l10n);
    final n = parsed.soundNames.length;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              typeIcon(parsed.type),
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
            Text(l10n.fileDetailsTitle),
          ],
        ),
        content: SingleChildScrollView(
          child: buildPackPreviewBody(
            context,
            l10n: l10n,
            displayName: displayName,
            json: json,
            sizeBytes: sizeBytes,
            modifiedTime: modifiedTime,
            soundSectionTitle: l10n.soundsContained(n),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  static Future<bool> show(
    BuildContext context, {
    required String displayName,
    required Map<String, dynamic> json,
    int? sizeBytes,
    DateTime? modifiedTime,
    String? confirmLabel,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final parsed = _parseSounds(json, l10n);
    final n = parsed.soundNames.length;
    final label = confirmLabel ?? l10n.continueLabel;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(typeIcon(parsed.type), color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(l10n.importPreviewTitle),
          ],
        ),
        content: SingleChildScrollView(
          child: buildPackPreviewBody(
            context,
            l10n: l10n,
            displayName: displayName,
            json: json,
            sizeBytes: sizeBytes,
            modifiedTime: modifiedTime,
            soundSectionTitle: l10n.soundsToImport(n),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(label),
          ),
        ],
      ),
    );

    return result == true;
  }

  static Widget _previewRow(String label, String value) {
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
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
