// lib/providers/subtitle_state.dart
import 'package:extractsubs/models/video_file.dart';
import 'package:extractsubs/utils/subtitle_utils.dart';
import 'package:flutter/foundation.dart';

class SubtitleState extends ChangeNotifier {
  List<VideoFile> _videoFiles = [];
  String _selectedFormat = 'srt';
  bool _isProcessing = false;
  double _progress = 0.0;
  String? _currentProcessingFile;
  int? _selectedIndex;

  // Getters
  List<VideoFile> get videoFiles => _videoFiles;
  String get selectedFormat => _selectedFormat;
  bool get isProcessing => _isProcessing;
  double get progress => _progress;
  String? get currentProcessingFile => _currentProcessingFile;
  int? get selectedIndex => _selectedIndex;
  final Map<String, bool> _expandedItems = {};

  // Getter
  bool isExpanded(String path) => _expandedItems[path] ?? false;

  // Genişletme durumunu değiştir
  void toggleExpanded(String path) {
    _expandedItems[path] = !(_expandedItems[path] ?? false);
    notifyListeners();
  }

  // Video dosyası silindiğinde veya tümü temizlendiğinde expand durumlarını da temizle

  // Video dosyası silindiğinde veya tümü temizlendiğinde expand durumlarını da temizle
  void clearAll() {
    _videoFiles = [];
    _progress = 0.0;
    _currentProcessingFile = null;
    _selectedIndex = null;
    _expandedItems.clear(); // Expand durumlarını temizle
    notifyListeners();
  }

  void removeVideoFile(String filePath) {
    _videoFiles.removeWhere((file) => file.path == filePath);
    _expandedItems.remove(filePath); // Expand durumunu temizle
    notifyListeners();
  }

  // Geçerli altyazı kodekini al
  String? get currentCodec {
    if (_selectedIndex == null || _videoFiles.isEmpty) return null;

    for (var file in _videoFiles) {
      final track = file.subtitleTracks
          .where((t) => t.index == _selectedIndex)
          .firstOrNull;
      if (track != null) {
        return track.codec;
      }
    }
    return null;
  }

  // Mevcut videolarda bulunan tüm altyazı index'lerini getir
  Set<int> get availableIndices {
    Set<int> indices = {};
    for (var file in _videoFiles) {
      for (var track in file.subtitleTracks) {
        indices.add(track.index);
      }
    }
    return indices;
  }

  void setSelectedIndex(int? index) {
    _selectedIndex = index;

    // Index seçildiğinde ve PGS/SUP altyazı ise otomatik olarak SUP formatına geç
    if (index != null) {
      final codec = currentCodec;
      if (codec != null && SubtitleUtils.isBitmapSubtitle(codec)) {
        _selectedFormat = 'sup';
      }
    }

    notifyListeners();
  }

  void setVideoFiles(List<VideoFile> files) {
    _videoFiles = files;
    // Yeni videolar yüklendiğinde seçili index'i sıfırla
    _selectedIndex = null;
    notifyListeners();
  }

  void setFormat(String format) {
    // Eğer bitmap altyazı seçili ve SUP dışında bir format seçilmeye çalışılıyorsa izin verme
    if (_selectedIndex != null) {
      final codec = currentCodec;
      if (codec != null &&
          SubtitleUtils.isBitmapSubtitle(codec) &&
          format != 'sup') {
        return;
      }
    }

    _selectedFormat = format;
    notifyListeners();
  }

  void setProcessing(bool processing) {
    _isProcessing = processing;
    if (!processing) {
      _progress = 0.0;
      _currentProcessingFile = null;
    }
    notifyListeners();
  }

  void updateProgress(double value, String fileName) {
    _progress = value;
    _currentProcessingFile = fileName;
    notifyListeners();
  }
}
