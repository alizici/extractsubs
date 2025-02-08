// lib/utils/language_utils.dart
class LanguageUtils {
  // ISO 639-2 dil kodlarının bir kısmı - gerektiğinde genişletilebilir
  static final Set<String> validLanguageCodes = {
    'eng', // English
    'tur', // Turkish
    'fra', // French
    'deu', // German
    'spa', // Spanish
    'ita', // Italian
    'por', // Portuguese
    'rus', // Russian
    'jpn', // Japanese
    'kor', // Korean
    'chi', // Chinese
    'und', // Undetermined (son çare olarak)
  };

  // ISO 639-1 to ISO 639-2 dönüşüm map'i
  static final Map<String, String> iso6391to6392 = {
    'en': 'eng',
    'tr': 'tur',
    'fr': 'fra',
    'de': 'deu',
    'es': 'spa',
    'it': 'ita',
    'pt': 'por',
    'ru': 'rus',
    'ja': 'jpn',
    'ko': 'kor',
    'zh': 'chi',
  };

  /// Dil kodunu doğrula ve standardize et
  static String normalizeLanguageCode(String languageCode) {
    // Boş veya null ise 'und' döndür
    if (languageCode.isEmpty) {
      return 'und';
    }

    // Küçük harfe çevir ve boşlukları temizle
    final normalized = languageCode.toLowerCase().trim();

    // Eğer direkt olarak geçerli bir ISO 639-2 kodu ise
    if (validLanguageCodes.contains(normalized)) {
      return normalized;
    }

    // ISO 639-1'den ISO 639-2'ye dönüşüm dene
    if (iso6391to6392.containsKey(normalized)) {
      return iso6391to6392[normalized]!;
    }

    // Geçersiz kod durumunda varsayılan olarak 'und' döndür
    // Not: IETF BCP 47 standardına göre 'und' bilinmeyen diller için kullanılır
    return 'und';
  }
}
