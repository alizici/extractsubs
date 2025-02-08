// lib/utils/subtitle_utils.dart
class SubtitleUtils {
  static bool isBitmapSubtitle(String codec) {
    final bitmapCodecs = [
      'hdmv_pgs_subtitle',
      'dvd_subtitle',
      'pgs',
      'sup',
      'dvdsub'
    ];
    return bitmapCodecs.contains(codec.toLowerCase());
  }

  static List<String> getSupportedFormatsForCodec(String codec) {
    if (isBitmapSubtitle(codec)) {
      return ['sup'];
    }
    return ['srt', 'ass', 'ssa', 'vtt'];
  }

  static String getWarningForCodec(String codec) {
    if (isBitmapSubtitle(codec)) {
      return 'Bu altyazı bitmap formatında (PGS/SUB). Sadece SUP formatında çıkartılabilir.';
    }
    return '';
  }
}
