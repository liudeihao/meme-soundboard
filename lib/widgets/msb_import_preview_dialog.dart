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

  /// Returns true if the user taps the confirm button.
  static Future<bool> show(
    BuildContext context, {
    required String displayName,
    required Map<String, dynamic> json,
    int? sizeBytes,
    DateTime? modifiedTime,
    String confirmLabel = '继续',
  }) async {
    final type = json['type'] as String? ?? 'unknown';
    final exportedAt = json['exportedAt'] as String?;
    DateTime? exportDate;
    if (exportedAt != null) {
      try {
        exportDate = DateTime.parse(exportedAt);
      } catch (_) {}
    }

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

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(typeIcon(type), color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            const Text('导入预览'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
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
                '将导入的音效 (${soundNames.length} 个):',
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
