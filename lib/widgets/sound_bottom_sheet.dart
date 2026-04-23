import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/sound_item.dart';
import '../utils/category_l10n.dart';

/// 音效详情/操作底部弹窗
class SoundBottomSheet extends StatelessWidget {
  final SoundItem sound;
  final VoidCallback onPlay;
  final VoidCallback onToggleFavorite;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onShare;
  final VoidCallback? onExport;
  final VoidCallback? onSaveAudio;
  final VoidCallback? onSaveImage;
  final VoidCallback? onShowDetails;

  const SoundBottomSheet({
    super.key,
    required this.sound,
    required this.onPlay,
    required this.onToggleFavorite,
    this.onEdit,
    this.onDelete,
    this.onShare,
    this.onExport,
    this.onSaveAudio,
    this.onSaveImage,
    this.onShowDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 拖动指示条
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // 音效信息头部
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // 封面图
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color:
                          sound.dominantColor?.withOpacity(0.2) ??
                          Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            sound.dominantColor?.withOpacity(0.3) ??
                            Colors.grey.shade300,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: sound.imagePath != null
                          ? (sound.isAsset
                                ? Image.asset(
                                    sound.imagePath!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _buildDefaultIcon(),
                                  )
                                : Image.network(
                                    sound.imagePath!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _buildDefaultIcon(),
                                  ))
                          : _buildDefaultIcon(),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // 名称和分类
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sound.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    sound.dominantColor?.withOpacity(0.1) ??
                                    theme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                l10n.categoryLabelForStored(sound.category),
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      sound.dominantColor ?? theme.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (sound.isFavorite) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.favorite,
                                color: Colors.red,
                                size: 16,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 播放按钮
                  FloatingActionButton(
                    onPressed: onPlay,
                    backgroundColor: sound.dominantColor ?? theme.primaryColor,
                    child: const Icon(Icons.play_arrow_rounded, size: 32),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // 操作列表
            _buildActionTile(
              context,
              icon: sound.isFavorite ? Icons.favorite : Icons.favorite_border,
              iconColor: Colors.red,
              title: sound.isFavorite ? l10n.unfavorite : l10n.favoriteAdd,
              onTap: () {
                onToggleFavorite();
                Navigator.pop(context);
              },
            ),

            if (onShare != null)
              _buildActionTile(
                context,
                icon: Icons.share_rounded,
                iconColor: Colors.blue,
                title: l10n.share,
                onTap: () {
                  onShare!();
                  Navigator.pop(context);
                },
              ),

            if (onExport != null)
              _buildActionTile(
                context,
                icon: Icons.upload_file_rounded,
                iconColor: Colors.teal,
                title: l10n.exportAsMsb,
                onTap: () {
                  Navigator.pop(context);
                  onExport!();
                },
              ),

            if (onSaveAudio != null)
              _buildActionTile(
                context,
                icon: Icons.audio_file_rounded,
                iconColor: Colors.purple,
                title: l10n.saveAudioFileAction,
                onTap: () {
                  Navigator.pop(context);
                  onSaveAudio!();
                },
              ),

            if (onSaveImage != null && sound.imagePath != null)
              _buildActionTile(
                context,
                icon: Icons.image_rounded,
                iconColor: Colors.green,
                title: l10n.saveCoverImageAction,
                onTap: () {
                  Navigator.pop(context);
                  onSaveImage!();
                },
              ),

            if (onShowDetails != null)
              _buildActionTile(
                context,
                icon: Icons.info_outline_rounded,
                iconColor: Colors.blueGrey,
                title: l10n.viewDetails,
                onTap: () {
                  Navigator.pop(context);
                  onShowDetails!();
                },
              ),

            if (onEdit != null)
              _buildActionTile(
                context,
                icon: Icons.edit_rounded,
                iconColor: Colors.orange,
                title: l10n.edit,
                onTap: () {
                  Navigator.pop(context);
                  onEdit!();
                },
              ),

            if (onDelete != null)
              _buildActionTile(
                context,
                icon: Icons.delete_rounded,
                iconColor: Colors.red,
                title: l10n.delete,
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context, l10n);
                },
              ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultIcon() {
    return Container(
      color: sound.dominantColor?.withOpacity(0.2) ?? Colors.grey.shade200,
      child: Icon(
        Icons.music_note_rounded,
        color: sound.dominantColor ?? Colors.grey.shade600,
        size: 30,
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }

  void _showDeleteConfirmation(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.confirmDelete),
        content: Text(l10n.confirmDeleteSingleSoundBody(sound.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}
