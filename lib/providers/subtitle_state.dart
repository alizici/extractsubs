// lib/providers/subtitle_state.dart
import 'package:extractsubs/models/video_file.dart';
import 'package:flutter/foundation.dart';

class SubtitleState extends ChangeNotifier {
  List<VideoFile> _videoFiles = [];
  String _selectedFormat = 'srt';
  bool _isProcessing = false;
  double _progress = 0.0;
  String? _currentProcessingFile;
  int? _selectedIndex; // Seçili altyazı index'i

  // Getters
  List<VideoFile> get videoFiles => _videoFiles;
  String get selectedFormat => _selectedFormat;
  bool get isProcessing => _isProcessing;
  double get progress => _progress;
  String? get currentProcessingFile => _currentProcessingFile;
  int? get selectedIndex => _selectedIndex;

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
    notifyListeners();
  }

  void setVideoFiles(List<VideoFile> files) {
    _videoFiles = files;
    // Yeni videolar yüklendiğinde seçili index'i sıfırla
    _selectedIndex = null;
    notifyListeners();
  }

  void setFormat(String format) {
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

  void clearAll() {
    _videoFiles = [];
    _progress = 0.0;
    _currentProcessingFile = null;
    _selectedIndex = null;
    notifyListeners();
  }

  void removeVideoFile(String filePath) {
    _videoFiles.removeWhere((file) => file.path == filePath);
    notifyListeners();
  }
}
