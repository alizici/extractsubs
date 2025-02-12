// lib/views/subtitle_track_selector.dart
import 'package:extractsubs/models/video_file.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subtitle_state.dart';

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
    return Consumer<SubtitleState>(
      builder: (context, state, _) {
        // Bu video için seçili indeksi al
        final selectedIndex = state.getSelectedIndexForVideo(videoFile.path);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  const Text('Bu video için altyazılar:'),
                  const Spacer(),
                  // Manuel seçim yapıldıysa, sıfırlama butonu göster
                  if (state.hasManualIndex(videoFile.path))
                    TextButton.icon(
                      icon: const Icon(Icons.restore, size: 18),
                      label: const Text('Global İndekse Dön'),
                      onPressed: () => state.clearManualIndex(videoFile.path),
                    ),
                ],
              ),
            ),
            ...videoFile.subtitleTracks.map((track) {
              final isSelected = selectedIndex == track.index;
              return ListTile(
                dense: true,
                selected: isSelected,
                title: Text(
                  '${track.language} (İndeks: ${track.index})',
                  style: isSelected
                      ? const TextStyle(fontWeight: FontWeight.bold)
                      : null,
                ),
                subtitle: Text('Codec: ${track.codec}'),
                leading: Radio<int>(
                  value: track.index,
                  groupValue: selectedIndex,
                  onChanged: (value) {
                    if (value != null) {
                      state.setManualIndex(videoFile.path, value);
                    }
                  },
                ),
                trailing: ElevatedButton(
                  onPressed: () =>
                      onExtract('${videoFile.path}|${track.index}'),
                  child: const Text('Çıkar'),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
