// lib/models/subtitle_entry.dart
class SubtitleEntry {
  final int index;
  final Duration startTime;
  final Duration endTime;
  String text;

  SubtitleEntry({
    required this.index,
    required this.startTime,
    required this.endTime,
    required this.text,
  });

  factory SubtitleEntry.fromSrt(String block) {
    final parts = block.trim().split('\n');
    if (parts.length < 3) {
      return SubtitleEntry(
        index: 0,
        startTime: Duration.zero,
        endTime: Duration.zero,
        text: '',
      );
    }

    final timeString = parts[1];
    final times = timeString.split(' --> ');

    return SubtitleEntry(
      index: int.tryParse(parts[0]) ?? 0,
      startTime: _parseTimeString(times[0]),
      endTime: _parseTimeString(times[1]),
      text: parts.sublist(2).join('\n'),
    );
  }

  // New factory method for ASS format
  factory SubtitleEntry.fromAss(String block, int index) {
    try {
      // Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
      // Example: "Dialogue: 0,0:00:08.00,0:00:12.00,Default,,0,0,0,,Line of text"
      final parts = block.split(',');
      if (parts.length < 10) {
        return SubtitleEntry(
          index: index,
          startTime: Duration.zero,
          endTime: Duration.zero,
          text: '',
        );
      }

      // Parse start and end times
      final startTime = _parseAssTimeString(parts[1]);
      final endTime = _parseAssTimeString(parts[2]);

      // Get text (everything after the 9th comma)
      final text = parts.sublist(9).join(',');

      return SubtitleEntry(
        index: index,
        startTime: startTime,
        endTime: endTime,
        text: text,
      );
    } catch (e) {
      print('Error parsing ASS block: $e for block: $block');
      return SubtitleEntry(
        index: index,
        startTime: Duration.zero,
        endTime: Duration.zero,
        text: '',
      );
    }
  }

  static Duration _parseTimeString(String time) {
    final parts = time.trim().split(':');
    if (parts.length != 3) return Duration.zero;

    final seconds = parts[2].split(',');
    return Duration(
      hours: int.tryParse(parts[0]) ?? 0,
      minutes: int.tryParse(parts[1]) ?? 0,
      seconds: int.tryParse(seconds[0]) ?? 0,
      milliseconds: int.tryParse(seconds[1]) ?? 0,
    );
  }

  // New method to parse ASS format time (H:MM:SS.CC)
  static Duration _parseAssTimeString(String time) {
    final parts = time.trim().split(':');
    if (parts.length != 3) return Duration.zero;

    final seconds = parts[2].split('.');
    return Duration(
      hours: int.tryParse(parts[0]) ?? 0,
      minutes: int.tryParse(parts[1]) ?? 0,
      seconds: int.tryParse(seconds[0]) ?? 0,
      milliseconds:
          seconds.length > 1 ? ((int.tryParse(seconds[1]) ?? 0) * 10) : 0,
    );
  }

  String toSrt() {
    String formatDuration(Duration d) {
      return '${d.inHours.toString().padLeft(2, '0')}:'
          '${(d.inMinutes % 60).toString().padLeft(2, '0')}:'
          '${(d.inSeconds % 60).toString().padLeft(2, '0')},'
          '${(d.inMilliseconds % 1000).toString().padLeft(3, '0')}';
    }

    return '$index\n'
        '${formatDuration(startTime)} --> ${formatDuration(endTime)}\n'
        '$text\n';
  }

  // New method to convert to ASS format
  String toAss(String style) {
    String formatAssTime(Duration d) {
      return '${d.inHours}:'
          '${(d.inMinutes % 60).toString().padLeft(2, '0')}:'
          '${(d.inSeconds % 60).toString().padLeft(2, '0')}.'
          '${((d.inMilliseconds % 1000) ~/ 10).toString().padLeft(2, '0')}';
    }

    return 'Dialogue: 0,${formatAssTime(startTime)},${formatAssTime(endTime)},$style,,0,0,0,,$text';
  }
}
