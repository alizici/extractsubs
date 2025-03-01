// lib/views/subtitle_track_selector.dart
import 'dart:io';

import 'package:extractsubs/models/video_file.dart';
import 'package:extractsubs/services/file_service.dart';
import 'package:extractsubs/views/subtitle_editor_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subtitle_state.dart';
import 'package:extractsubs/models/extract_params.dart';

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
    final theme = Theme.of(context);
    return Consumer<SubtitleState>(
      builder: (context, state, _) {
        final selectedIndex = state.getSelectedIndexForVideo(videoFile.path);

        return Container(
          color: theme.brightness == Brightness.dark
              ? const Color(0xFF2C2C2E).withAlpha(77)
              : Colors.grey[50]?.withAlpha(128),
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Divider(
                height: 1,
                thickness: 0.5,
                color: theme.dividerColor.withAlpha(128),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    Text(
                      'Bu video için altyazılar',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface.withAlpha(204),
                      ),
                    ),
                    const Spacer(),
                    if (state.hasManualIndex(videoFile.path))
                      TextButton.icon(
                        icon: Icon(
                          Icons.restore,
                          size: 16,
                          color: theme.primaryColor,
                        ),
                        label: Text(
                          'Global İndekse Dön',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: theme.primaryColor,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          backgroundColor: theme.primaryColor.withAlpha(26),
                        ),
                        onPressed: () => state.clearManualIndex(videoFile.path),
                      ),
                  ],
                ),
              ),
              for (var track in videoFile.subtitleTracks)
                _buildTrackItem(context, track, selectedIndex, state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrackItem(
    BuildContext context,
    var track,
    int? selectedIndex,
    SubtitleState state,
  ) {
    final theme = Theme.of(context);
    final isSelected = selectedIndex == track.index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.primaryColor.withAlpha(26)
            : theme.brightness == Brightness.dark
                ? Colors.black.withAlpha(26)
                : Colors.white.withAlpha(128),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            if (selectedIndex != track.index) {
              state.setManualIndex(videoFile.path, track.index);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                // Radio butonu
                Radio<int>(
                  value: track.index,
                  groupValue: selectedIndex,
                  activeColor: theme.primaryColor,
                  onChanged: (value) {
                    if (value != null) {
                      state.setManualIndex(videoFile.path, value);
                    }
                  },
                ),
                // Altyazı bilgileri
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${track.language} (İndeks: ${track.index})',
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 14,
                          color: isSelected
                              ? theme.primaryColor
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Codec: ${track.codec}',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withAlpha(153),
                        ),
                      ),
                    ],
                  ),
                ),
                // Butonlar
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Düzenleme butonu
                    IconButton(
                      icon: Icon(
                        Icons.edit_note,
                        size: 20,
                        color: theme.colorScheme.primary.withAlpha(204),
                      ),
                      onPressed: () async {
                        // Altyazı düzenleme işlemi
                        final subtitleFormat =
                            Provider.of<SubtitleState>(context, listen: false)
                                .selectedFormat;
                        final outputPath = FileService.getOutputPath(
                          videoFile.path,
                          subtitleFormat,
                        );

                        if (!File(outputPath).existsSync()) {
                          // Async işlemden önce context.mounted kontrolü
                          if (!context.mounted) return;

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
                                  style: TextButton.styleFrom(
                                    foregroundColor:
                                        theme.colorScheme.onSurface,
                                  ),
                                  child: const Text('İptal'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: theme.primaryColor,
                                  ),
                                  child: const Text('Çıkar'),
                                ),
                              ],
                            ),
                          );

                          // Dialog sonrası tekrar context.mounted kontrolü
                          if (!context.mounted) return;

                          if (shouldExtract == true) {
                            onExtract(
                                ExtractParams(videoFile.path, track.index));
                            await Future.delayed(const Duration(seconds: 1));

                            // Future.delayed sonrası context.mounted kontrolü
                            if (!context.mounted) return;
                          } else {
                            return;
                          }
                        }

                        // Son context kullanımı öncesi mounted kontrolü
                        if (!context.mounted) return;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoSubtitleEditorPage(
                              videoPath: videoFile.path,
                              subtitlePath: outputPath,
                            ),
                          ),
                        );
                      },
                      tooltip: 'Düzenle',
                    ),
                    const SizedBox(width: 4),
                    // Çıkar butonu
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () {
                            onExtract(
                                ExtractParams(videoFile.path, track.index));
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: Text(
                              'Çıkar',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
