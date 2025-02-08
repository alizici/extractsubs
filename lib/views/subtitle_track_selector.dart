// lib/views/subtitle_track_selector.dart
import 'package:extractsubs/models/video_file.dart';
import 'package:flutter/material.dart';

// lib/views/subtitle_track_selector.dart

class SubtitleTrackSelector extends StatelessWidget {
  final VideoFile videoFile;
  final Function(String) onExtract;

  const SubtitleTrackSelector({
    Key? key,
    required this.videoFile,
    required this.onExtract,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text('Bu video için altyazılar:'),
        ),
        ...videoFile.subtitleTracks.map((track) {
          return ListTile(
            dense: true,
            title: Text('${track.language} (İndeks: ${track.index})'),
            subtitle: Text('Codec: ${track.codec}'),
            trailing: ElevatedButton(
              onPressed: () => onExtract('${videoFile.path}|${track.index}'),
              child: const Text('Çıkar'),
            ),
          );
        }),
      ],
    );
  }
}
