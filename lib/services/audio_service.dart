import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/sound_item.dart';
import 'settings_service.dart';

/// 音频服务 - 管理音效的播放
/// 支持单播放和多播放模式
class AudioService {
  // 所有活跃的播放器列表（用于多播放）
  final List<AudioPlayer> _activePlayers = [];

  // 当前活跃的播放器（最后一个播放的）
  AudioPlayer? _currentPlayer;

  // 播放状态回调
  final ValueNotifier<String?> currentlyPlaying = ValueNotifier(null);

  // URL 播放错误通知
  final ValueNotifier<String?> playError = ValueNotifier(null);

  AudioService();

  /// Avoid exclusive Android audio focus and enable iOS mixing so overlapping
  /// sounds in this app do not interrupt each other.
  static AudioContext _parallelPlaybackAudioContext() {
    return AudioContext(
      android: const AudioContextAndroid(
        audioFocus: AndroidAudioFocus.none,
        contentType: AndroidContentType.sonification,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: const {AVAudioSessionOptions.mixWithOthers},
      ),
    );
  }

  /// 播放音效
  Future<void> play(SoundItem sound) async {
    try {
      // 根据设置决定是否停止当前播放
      // 如果启用了同时播放，就不停止；否则停止当前播放器
      final settings = SettingsService.instance;
      if (!settings.allowMultiPlay) {
        await stopCurrent();
      }

      // 清除之前的错误
      playError.value = null;
      currentlyPlaying.value = sound.id;

      // 创建新的播放器
      final player = AudioPlayer();
      _currentPlayer = player;
      _activePlayers.add(player);

      // 设置播放完成回调
      player.onPlayerComplete.listen(
        (_) {
          // 确保在主线程上执行
          Future.microtask(() => _onPlaybackComplete(player));
        },
        onError: (error) {
          debugPrint('播放错误: $error');
          // 确保在主线程上执行
          Future.microtask(() => _onPlaybackComplete(player));
        },
      );

      // 设置播放器音量
      await player.setVolume(sound.advancedSettings.volumeLevel);

      final AudioContext? parallelCtx =
          settings.allowMultiPlay ? _parallelPlaybackAudioContext() : null;

      if (sound.isAsset) {
        await player.play(AssetSource(sound.soundPath), ctx: parallelCtx);
      } else if (sound.isUrl) {
        await player.setPlayerMode(PlayerMode.mediaPlayer);
        await player.play(UrlSource(sound.soundPath), ctx: parallelCtx);
      } else {
        await player.play(DeviceFileSource(sound.soundPath), ctx: parallelCtx);
      }
    } catch (e) {
      debugPrint('播放失败: $e');
      playError.value = '播放失败: $e';
      currentlyPlaying.value = null;
    }
  }

  /// 播放完成回调
  void _onPlaybackComplete(AudioPlayer player) {
    _activePlayers.remove(player);
    if (_currentPlayer == player) {
      _currentPlayer = null;
      currentlyPlaying.value = null;
    }
    unawaited(_disposePlayerQuietly(player));
  }

  Future<void> _disposePlayerQuietly(AudioPlayer player) async {
    try {
      if (player.state == PlayerState.disposed) return;
      await player.dispose();
    } catch (e) {
      debugPrint('释放播放器失败: $e');
    }
  }

  /// 停止当前播放并释放资源
  Future<void> stopCurrent() async {
    if (_currentPlayer != null) {
      try {
        await _currentPlayer!.stop();
        await _currentPlayer!.dispose();
      } catch (e) {
        debugPrint('停止播放器失败: $e');
      }
      _activePlayers.remove(_currentPlayer);
      _currentPlayer = null;
      currentlyPlaying.value = null;
    }
  }

  /// 停止所有播放
  Future<void> stopAll() async {
    // 停止所有活跃的播放器
    for (final player in List.from(_activePlayers)) {
      try {
        await player.stop();
        await player.dispose();
      } catch (e) {
        debugPrint('停止播放器失败: $e');
      }
    }
    _activePlayers.clear();
    _currentPlayer = null;
    currentlyPlaying.value = null;
  }
}
