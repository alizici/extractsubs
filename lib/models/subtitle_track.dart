// lib/models/subtitle_track.dart
// lib/models/subtitle_track.dart
class SubtitleTrack {
  final int index;
  final String language;
  final String codec;
  final String title;

  SubtitleTrack({
    required this.index,
    required this.language,
    required this.codec,
    this.title = '',
  });

  @override
  String toString() {
    return 'SubtitleTrack(index: $index, language: $language, codec: $codec, title: $title)';
  }

  factory SubtitleTrack.fromFFmpegOutput(String output, int index) {
    // FFmpeg çıktısından altyazı bilgilerini parse et
    final language = _parseLanguage(output);
    final codec = _parseCodec(output);
    final title = _parseTitle(output);

    return SubtitleTrack(
      index: index,
      language: language,
      codec: codec,
      title: title,
    );
  }

  static String _parseLanguage(String output) {
    final languageMatch = RegExp(r'\((.*?)\)').firstMatch(output);
    return languageMatch?.group(1)?.toLowerCase() ?? 'unk';
  }

  static String _parseCodec(String output) {
    final codecMatch = RegExp(r'Subtitle:\s*(\w+)').firstMatch(output);
    return codecMatch?.group(1)?.toLowerCase() ?? 'unknown';
  }

  static String _parseTitle(String output) {
    // Başlık bilgisini çıkar
    return ''; // Varsayılan değer
  }
}
