/// Optional time range when importing an audio file (start inclusive, end exclusive in practice for export).
class AudioTrimRange {
  final Duration start;
  final Duration end;

  const AudioTrimRange({required this.start, required this.end});

  /// Whether this range covers essentially the whole clip (no meaningful trim).
  bool isEffectivelyFull(Duration total, {Duration tolerance = const Duration(milliseconds: 150)}) {
    if (total <= Duration.zero) return true;
    if (start <= Duration.zero && end >= total) return true;
    if (start <= tolerance && end >= total - tolerance) return true;
    return false;
  }

  bool get isValid => end > start;
}
