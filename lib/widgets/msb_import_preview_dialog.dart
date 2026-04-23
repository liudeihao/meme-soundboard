import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Shared "import preview" for .msb packs (home import, external open, export manager).
class MsbImportPreviewDialog {
  static String typeLabel(String type) {
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
  ) {
    final type = json['type'] as String? ?? 'unknown';
    final soundNames = <String>[];
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

    return (type: type, soundNames: soundNames, categoryName: categoryName);
  }

  /// Shared body: metadata + scrollable sound name list (import preview & export file details).
  static Widget buildPackPreviewBody(
    BuildContext context, {
    required String displayName,
    required Map<String, dynamic> json,
    int? sizeBytes,
    DateTime? modifiedTime,
    required String soundSectionTitle,
  }) {
    final parsed = _parseSounds(json);
    final type = parsed.type;
    final soundNames = parsed.soundNames;
    final categoryName = parsed.categoryName;
    final exportDate = _parseExportDate(json);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _previewRow('文件名', displayName),
        _previewRow('类型', typeLabel(type)),
        _previewRow('大小', sizeLabel(sizeBytes)),
        if (modifiedTime != null)
          _previewRow(
            '文件时间',
            DateFormat('yyyy-MM-dd HH:mm').format(modifiedTime),
          ),
        if (exportDate != null)
          _previewRow(
            '导出时间',
            DateFormat('yyyy-MM-dd HH:mm').format(exportDate),
          ),
        if (categoryName != null) _previewRow('分类', categoryName),
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

  /// Read-only pack details (e.g. export manager).
  static Future<void> showPackDetails(
    BuildContext context, {
    required String displayName,
    required Map<String, dynamic> json,
    int? sizeBytes,
    DateTime? modifiedTime,
  }) async {
    final parsed = _parseSounds(json);
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
            const Text('文件详情'),
          ],
        ),
        content: SingleChildScrollView(
          child: buildPackPreviewBody(
            context,
            displayName: displayName,
            json: json,
            sizeBytes: sizeBytes,
            modifiedTime: modifiedTime,
            soundSectionTitle: '包含的音效 ($n 个):',
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

  /// Returns true if the user taps the confirm button.
  static Future<bool> show(
    BuildContext context, {
    required String displayName,
    required Map<String, dynamic> json,
    int? sizeBytes,
    DateTime? modifiedTime,
    String confirmLabel = '继续',
  }) async {
    final parsed = _parseSounds(json);
    final n = parsed.soundNames.length;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(typeIcon(parsed.type), color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            const Text('导入预览'),
          ],
        ),
        content: SingleChildScrollView(
          child: buildPackPreviewBody(
            context,
            displayName: displayName,
            json: json,
            sizeBytes: sizeBytes,
            modifiedTime: modifiedTime,
            soundSectionTitle: '将导入的音效 ($n 个):',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
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
