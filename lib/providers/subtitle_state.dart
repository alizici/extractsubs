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
  final Map<String, bool> _expandedItems = {};
  final Map<String, int> _manualIndices =
      {}; // Video path -> manual indeks eşlemesi

  // Getters
  List<VideoFile> get videoFiles => _videoFiles;
  String get selectedFormat => _selectedFormat;
  bool get isProcessing => _isProcessing;
  double get progress => _progress;
  String? get currentProcessingFile => _currentProcessingFile;
  int? get selectedIndex => _selectedIndex;
  bool isExpanded(String path) => _expandedItems[path] ?? false;

  // Manuel indeks seçili mi kontrolü için getter
  bool hasManualIndex(String path) => _manualIndices.containsKey(path);

  // Video için seçili indeksi getir (manuel veya global)
  int? getSelectedIndexForVideo(String videoPath) {
    return _manualIndices[videoPath] ?? _selectedIndex;
  }

  // Manuel indeks ayarla
  void setManualIndex(String videoPath, int index) {
    _manualIndices[videoPath] = index;
    notifyListeners();
  }

  // Manuel indeksi temizle
  void clearManualIndex(String videoPath) {
    _manualIndices.remove(videoPath);
    notifyListeners();
  }

  void toggleExpanded(String path) {
    _expandedItems[path] = !(_expandedItems[path] ?? false);
    notifyListeners();
  }

  void clearAll() {
    _videoFiles = [];
    _progress = 0.0;
    _currentProcessingFile = null;
    _selectedIndex = null;
    _expandedItems.clear();
    _manualIndices.clear(); // Manuel indeksleri temizle
    notifyListeners();
  }

  void removeVideoFile(String filePath) {
    _videoFiles.removeWhere((file) => file.path == filePath);
    _expandedItems.remove(filePath);
    _manualIndices.remove(filePath); // Manuel indeksi temizle
    notifyListeners();
  }

  String? get currentCodec {
    // Hiç video dosyası yoksa null döndür
    if (_videoFiles.isEmpty) return null;

    // Önce manuel veya global olarak seçili indekse sahip bir codec ara
    if (_selectedIndex != null) {
      for (var file in _videoFiles) {
        final track = file.subtitleTracks
            .where((t) => t.index == getSelectedIndexForVideo(file.path))
            .firstOrNull;
        if (track != null) {
          return track.codec;
        }
      }
    }

    // Seçili indeks yoksa veya bulunamadıysa, ilk kullanılabilir altyazı parçasının codec'ini döndür
    for (var file in _videoFiles) {
      if (file.subtitleTracks.isNotEmpty) {
        return file.subtitleTracks.first.codec;
      }
    }

    return null;
  }

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

    if (index != null) {
      // Sadece seçilen indekse sahip olmayan videoların manuel seçimlerini temizle
      for (var file in _videoFiles) {
        bool hasMatchingTrack =
            file.subtitleTracks.any((track) => track.index == index);
        if (!hasMatchingTrack) {
          _manualIndices.remove(file.path);
        }
      }

      // PGS/SUP altyazı kontrolü ve format değişikliği
      final codec = currentCodec;
      if (codec != null && SubtitleUtils.isBitmapSubtitle(codec)) {
        _selectedFormat = 'sup';
      }
    } else {
      // index null ise tüm manuel seçimleri temizle
      _manualIndices.clear();
    }

    notifyListeners();
  }

  void setVideoFiles(List<VideoFile> files) {
    _videoFiles = files;
    _selectedIndex = null;
    _manualIndices
        .clear(); // Yeni videolar yüklendiğinde manuel indeksleri temizle
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
