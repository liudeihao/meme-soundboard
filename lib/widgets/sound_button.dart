import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../models/sound_item.dart';

/// 音效按钮组件 - 实现即点即播和视觉反馈
class SoundButton extends StatefulWidget {
  final SoundItem sound;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onDoubleTap;

  const SoundButton({
    super.key,
    required this.sound,
    required this.isPlaying,
    required this.onTap,
    required this.onLongPress,
    required this.onDoubleTap,
  });

  @override
  State<SoundButton> createState() => _SoundButtonState();
}

class _SoundButtonState extends State<SoundButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticIn));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 获取按钮背景色
    final backgroundColor =
        widget.sound.dominantColor?.withOpacity(0.15) ??
        (isDark ? Colors.grey.shade800 : Colors.grey.shade100);

    final borderColor =
        widget.sound.dominantColor?.withOpacity(0.3) ??
        (isDark ? Colors.grey.shade700 : Colors.grey.shade300);

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: () {
        // 触发触觉反馈
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        widget.onLongPress();
      },
      onDoubleTap: () {
        HapticFeedback.selectionClick();
        widget.onDoubleTap();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.translate(
              offset: Offset(
                _shakeAnimation.value * 2 * (widget.isPlaying ? 1 : 0),
                0,
              ),
              child: child,
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: widget.isPlaying
                ? (widget.sound.dominantColor?.withOpacity(0.25) ??
                      theme.primaryColor.withOpacity(0.2))
                : backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isPlaying
                  ? (widget.sound.dominantColor ?? theme.primaryColor)
                  : borderColor,
              width: widget.isPlaying ? 2.5 : 1,
            ),
            boxShadow: widget.isPlaying
                ? [
                    BoxShadow(
                      color: (widget.sound.dominantColor ?? theme.primaryColor)
                          .withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 背景图片
                _buildImage(),

                // 渐变遮罩
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ),

                // 文字标签
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Text(
                    widget.sound.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),

                // 收藏图标
                if (widget.sound.isFavorite)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 14,
                      ),
                    ),
                  ),

                // URL 来源警告图标
                if (widget.sound.isUrl)
                  Positioned(
                    top: 6,
                    right: widget.sound.isFavorite ? 30 : 6,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.sound.isUrl)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.link_rounded,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                      ],
                    ),
                  ),

                // 播放动画指示器
                if (widget.isPlaying)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: widget.sound.dominantColor ?? theme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const _PlayingIndicator(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (widget.sound.imagePath == null || widget.sound.imagePath!.isEmpty) {
      // 无图片时显示默认图标
      return Container(
        color:
            widget.sound.dominantColor?.withOpacity(0.2) ??
            Colors.grey.shade300,
        child: Icon(
          Icons.music_note_rounded,
          size: 40,
          color: widget.sound.dominantColor ?? Colors.grey.shade600,
        ),
      );
    }

    // URL 图片
    if (widget.sound.isImageUrl) {
      return Image.network(
        widget.sound.imagePath!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color:
                widget.sound.dominantColor?.withOpacity(0.2) ??
                Colors.grey.shade300,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          // 加载失败时显示默认音符图，而不是链接失效提示
          return Container(
            color:
                widget.sound.dominantColor?.withOpacity(0.2) ??
                Colors.grey.shade300,
            child: Icon(
              Icons.music_note_rounded,
              size: 40,
              color: widget.sound.dominantColor ?? Colors.grey.shade600,
            ),
          );
        },
      );
    }

    if (widget.sound.isAsset) {
      return Image.asset(
        widget.sound.displayImagePath!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color:
                widget.sound.dominantColor?.withOpacity(0.2) ??
                Colors.grey.shade300,
            child: Icon(
              Icons.music_note_rounded,
              size: 40,
              color: widget.sound.dominantColor ?? Colors.grey.shade600,
            ),
          );
        },
      );
    } else {
      return Image.file(
        File(widget.sound.imagePath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color:
                widget.sound.dominantColor?.withOpacity(0.2) ??
                Colors.grey.shade300,
            child: Icon(
              Icons.music_note_rounded,
              size: 40,
              color: widget.sound.dominantColor ?? Colors.grey.shade600,
            ),
          );
        },
      );
    }
  }
}

/// 播放状态动画指示器
class _PlayingIndicator extends StatefulWidget {
  const _PlayingIndicator();

  @override
  State<_PlayingIndicator> createState() => _PlayingIndicatorState();
}

class _PlayingIndicatorState extends State<_PlayingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final value = (_controller.value + delay) % 1.0;
            return Container(
              width: 3,
              height: 6 + (value * 6),
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(1.5),
              ),
            );
          }),
        );
      },
    );
  }
}
