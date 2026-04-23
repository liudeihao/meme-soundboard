import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/return_code.dart';
import 'package:flutter/foundation.dart';

/// Cross-platform audio trim: FFmpeg Kit on Android / iOS / macOS; system `ffmpeg` on Windows / Linux.
class AudioTrimService {
  static const Duration _minClip = Duration(milliseconds: 200);

  /// Read duration using AudioPlayer (local file or accessible path).
  static Future<Duration?> probeDuration(String path) async {
    if (kIsWeb) return null;
    final player = AudioPlayer();
    try {
      await player.setSource(DeviceFileSource(path));
      Duration? d;
      for (var i = 0; i < 25; i++) {
        d = await player.getDuration();
        if (d != null && d > Duration.zero) break;
        await Future<void>.delayed(const Duration(milliseconds: 40));
      }
      return d;
    } catch (e) {
      debugPrint('probeDuration failed: $e');
      return null;
    } finally {
      await player.release();
    }
  }

  static Future<void> trimToFile({
    required String inputPath,
    required String outputPath,
    required Duration start,
    required Duration end,
  }) async {
    if (kIsWeb) {
      throw Exception('当前平台不支持音频截取');
    }
    if (end - start < _minClip) {
      throw Exception('截取片段过短（至少 ${_minClip.inMilliseconds} ms）');
    }

    final startSec = start.inMilliseconds / 1000.0;
    final lengthSec = (end - start).inMilliseconds / 1000.0;

    if (Platform.isWindows || Platform.isLinux) {
      await _trimWithSystemFfmpeg(
        inputPath: inputPath,
        outputPath: outputPath,
        startSec: startSec,
        lengthSec: lengthSec,
      );
    } else {
      await _trimWithFfmpegKit(
        inputPath: inputPath,
        outputPath: outputPath,
        startSec: startSec,
        lengthSec: lengthSec,
      );
    }
  }

  static Future<void> _trimWithFfmpegKit({
    required String inputPath,
    required String outputPath,
    required double startSec,
    required double lengthSec,
  }) async {
    final args = <String>[
      '-y',
      '-i',
      inputPath,
      '-ss',
      startSec.toString(),
      '-t',
      lengthSec.toString(),
      '-vn',
      '-c:a',
      'aac',
      '-b:a',
      '192k',
      outputPath,
    ];
    final session = await FFmpegKit.executeWithArguments(args);
    final code = await session.getReturnCode();
    if (!ReturnCode.isSuccess(code)) {
      final out = await session.getOutput();
      final fail = await session.getFailStackTrace();
      throw Exception(
        '截取失败: ${out ?? ''} ${fail ?? ''}'.trim().isEmpty
            ? 'FFmpeg 返回错误'
            : '${out ?? ''} ${fail ?? ''}'.trim(),
      );
    }
  }

  static Future<String> _resolveSystemFfmpeg() async {
    if (Platform.isWindows) {
      final r = await Process.run('where', ['ffmpeg']);
      if (r.exitCode != 0 || (r.stdout as String).trim().isEmpty) {
        throw Exception(
          '未找到 ffmpeg。请安装 FFmpeg 并加入 PATH，或使用 Android / iOS / macOS 版本（内置截取）。',
        );
      }
      final lines = const LineSplitter()
          .convert((r.stdout as String).trim())
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
      if (lines.isEmpty) {
        throw Exception(
          '未找到 ffmpeg。请安装 FFmpeg 并加入 PATH，或使用 Android / iOS / macOS 版本（内置截取）。',
        );
      }
      return lines.first;
    }
    final r = await Process.run('which', ['ffmpeg']);
    if (r.exitCode != 0 || (r.stdout as String).trim().isEmpty) {
      throw Exception(
        '未找到 ffmpeg。请安装 FFmpeg（例如 apt install ffmpeg）或使用 Android / iOS / macOS 版本。',
      );
    }
    return (r.stdout as String).trim();
  }

  static Future<void> _trimWithSystemFfmpeg({
    required String inputPath,
    required String outputPath,
    required double startSec,
    required double lengthSec,
  }) async {
    final ffmpeg = await _resolveSystemFfmpeg();
    final r = await Process.run(ffmpeg, [
      '-y',
      '-i',
      inputPath,
      '-ss',
      startSec.toString(),
      '-t',
      lengthSec.toString(),
      '-vn',
      '-c:a',
      'aac',
      '-b:a',
      '192k',
      outputPath,
    ]);
    if (r.exitCode != 0) {
      final err = '${r.stderr}${r.stdout}'.trim();
      throw Exception(err.isEmpty ? 'ffmpeg 执行失败 (exit ${r.exitCode})' : err);
    }
  }
}
