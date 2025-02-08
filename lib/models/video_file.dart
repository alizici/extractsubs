// lib/models/video_file.dart
import 'package:extractsubs/models/subtitle_track.dart';

class VideoFile {
  final String path;
  final String name;
  final List<SubtitleTrack> subtitleTracks;

  VideoFile({
    required this.path,
    required this.name,
    this.subtitleTracks = const [],
  });
}
