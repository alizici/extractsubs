// lib/views/subtitle_track_selector.dart
import 'dart:io';

import 'package:extractsubs/models/video_file.dart';
import 'package:extractsubs/views/subtitle_editor_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subtitle_state.dart';
import 'package:extractsubs/models/extract_params.dart';

// Callback tipini güncelle
typedef OnExtractCallback = void Function(ExtractParams params);

class SubtitleTrackSelector extends StatelessWidget {
  final VideoFile videoFile;
  final OnExtractCallback onExtract;

  const SubtitleTrackSelector({
    super.key,
    required this.videoFile,
    required this.onExtract,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SubtitleState>(
      builder: (context, state, _) {
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
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Inside SubtitleTrackSelector class
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        final outputPath =
                            '${videoFile.path}_${track.language}_${track.index}.srt';

                        // Altyazı dosyası yoksa, önce çıkarılması gerektiğini kullanıcıya bildir
                        if (!File(outputPath).existsSync()) {
                          if (context.mounted) {
                            final shouldExtract = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Altyazı Çıkarılmamış'),
                                content: const Text(
                                    'Düzenlemek için önce altyazıyı çıkarmanız gerekiyor. Altyazı çıkarılsın mı?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('İptal'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Çıkar'),
                                  ),
                                ],
                              ),
                            );

                            if (shouldExtract == true) {
                              // Sabit gecikme yerine işlemin tamamlanmasını bekle
                              onExtract(
                                  ExtractParams(videoFile.path, track.index));
                            } else {
                              return;
                            }
                          }
                        }

                        // Düzenleyici sayfasını aç
                        if (context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VideoSubtitleEditorPage(
                                videoPath: videoFile.path,
                                subtitlePath: outputPath,
                              ),
                            ),
                          );
                        }
                      },
                      tooltip: 'Düzenle',
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        onExtract(ExtractParams(videoFile.path, track.index));
                      },
                      child: const Text('Çıkar'),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
