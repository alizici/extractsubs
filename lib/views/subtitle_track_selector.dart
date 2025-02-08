// lib/views/subtitle_track_selector.dart
import 'package:extractsubs/models/video_file.dart';
import 'package:flutter/material.dart';

class SubtitleTrackSelector extends StatelessWidget {
  final VideoFile videoFile;
  final int? selectedTrackIndex;
  final Function(int?) onTrackSelected;

  const SubtitleTrackSelector({
    Key? key,
    required this.videoFile,
    required this.selectedTrackIndex,
    required this.onTrackSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${videoFile.name} - Altyazı Parçaları:'),
        ...videoFile.subtitleTracks.map((track) {
          return RadioListTile<int>(
            title: Text(
                '${track.language} - ${track.codec}${track.title.isNotEmpty ? ' - ${track.title}' : ''}'),
            value: track.index,
            groupValue: selectedTrackIndex,
            onChanged: onTrackSelected,
          );
        }),
      ],
    );
  }
}
