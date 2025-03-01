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
}
