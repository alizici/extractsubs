// lib/providers/subtitle_state.dart
import 'package:extractsubs/models/video_file.dart';
import 'package:flutter/foundation.dart';

class SubtitleState extends ChangeNotifier {
  List<VideoFile> _videoFiles = [];
  String _selectedFormat = 'srt';
  bool _isProcessing = false;
  Map<String, int?> _selectedTracks = {};
  double _progress = 0.0;
  String? _currentProcessingFile;

  // Getters
  List<VideoFile> get videoFiles => _videoFiles;
  String get selectedFormat => _selectedFormat;
  bool get isProcessing => _isProcessing;
  Map<String, int?> get selectedTracks => _selectedTracks;
  double get progress => _progress;
  String? get currentProcessingFile => _currentProcessingFile;

  void setVideoFiles(List<VideoFile> files) {
    _videoFiles = files;
    _selectedTracks.clear(); // Yeni dosyalar eklendiğinde seçimleri sıfırla
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

  void setSelectedTrack(String filePath, int? trackIndex) {
    _selectedTracks[filePath] = trackIndex;
    notifyListeners();
  }

  void clearAll() {
    _videoFiles = [];
    _selectedTracks = {};
    _progress = 0.0;
    _currentProcessingFile = null;
    notifyListeners();
  }

  bool isTrackSelected(String filePath) {
    return _selectedTracks.containsKey(filePath) &&
        _selectedTracks[filePath] != null;
  }
}
