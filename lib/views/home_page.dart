// lib/views/home_page.dart
import 'package:extractsubs/models/video_file.dart';
import 'package:extractsubs/providers/subtitle_state.dart';
import 'package:extractsubs/services/ffmpeg_service.dart';
import 'package:extractsubs/services/file_service.dart';
import 'package:extractsubs/views/format_selector.dart';
import 'package:extractsubs/views/subtitle_track_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  Future<void> _pickFiles(BuildContext context) async {
    final state = Provider.of<SubtitleState>(context, listen: false);
    state.setProcessing(true);

    try {
      final paths = await FileService.pickVideoFiles();
      if (paths.isNotEmpty) {
        final videoFiles = await Future.wait(
          paths.map((path) async {
            final name = path.split('/').last;
            try {
              final tracks = await FFmpegService.getSubtitleTracks(path);
              print('Found tracks for $name: ${tracks.length}');
              if (tracks.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$name: Altyazı bulunamadı'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
              return VideoFile(
                path: path,
                name: name,
                subtitleTracks: tracks,
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$name: Altyazı bilgileri okunamadı: $e'),
                  backgroundColor: Colors.orange,
                ),
              );
              return VideoFile(path: path, name: name);
            }
          }),
        );

        final validFiles =
            videoFiles.where((vf) => vf.subtitleTracks.isNotEmpty).toList();
        if (validFiles.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Seçilen dosyalarda altyazı bulunamadı'),
              backgroundColor: Colors.red,
            ),
          );
        }
        state.setVideoFiles(validFiles);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dosya seçimi sırasında hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      state.setProcessing(false);
    }
  }

  Future<void> _extractSubtitles(BuildContext context) async {
    final state = Provider.of<SubtitleState>(context, listen: false);
    if (state.videoFiles.isEmpty) return;

    state.setProcessing(true);
    final List<String> errors = [];
    final List<String> successes = [];

    try {
      int totalFiles = state.videoFiles.length;
      for (int i = 0; i < state.videoFiles.length; i++) {
        final videoFile = state.videoFiles[i];

        if (!state.isTrackSelected(videoFile.path)) {
          errors.add('${videoFile.name}: Altyazı parçası seçilmedi');
          continue;
        }

        state.updateProgress(i / totalFiles, videoFile.name);

        final outputPath = await FileService.getOutputPath(
          videoFile.path,
          state.selectedFormat,
        );

        final success = await FFmpegService.extractSubtitle(
          inputPath: videoFile.path,
          outputPath: outputPath,
          format: state.selectedFormat,
          trackIndex: state.selectedTracks[videoFile.path],
        );

        if (success) {
          successes.add(videoFile.name);
        } else {
          errors.add(videoFile.name);
        }
      }

      // İşlem sonuçlarını göster
      if (successes.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${successes.length} dosya başarıyla işlendi'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      if (errors.isNotEmpty) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('İşlem Sonucu'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Aşağıdaki dosyalarda hata oluştu:'),
                  const SizedBox(height: 8),
                  ...errors.map((e) => Text('• $e')),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tamam'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('İşlem sırasında hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      state.setProcessing(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Altyazı Çıkarıcı'),
        actions: [
          Consumer<SubtitleState>(
            builder: (context, state, _) => state.videoFiles.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_all),
                    onPressed: state.isProcessing ? null : state.clearAll,
                    tooltip: 'Tümünü Temizle',
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: Consumer<SubtitleState>(
        builder: (context, state, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed:
                      state.isProcessing ? null : () => _pickFiles(context),
                  child: const Text('Video Dosyası Seç'),
                ),
                const SizedBox(height: 16),
                if (state.videoFiles.isNotEmpty) ...[
                  FormatSelector(
                    selectedFormat: state.selectedFormat,
                    onFormatChanged: (format) {
                      if (format != null) state.setFormat(format);
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: state.videoFiles.length,
                      itemBuilder: (context, index) {
                        final videoFile = state.videoFiles[index];
                        return SubtitleTrackSelector(
                          videoFile: videoFile,
                          selectedTrackIndex:
                              state.selectedTracks[videoFile.path],
                          onTrackSelected: (index) {
                            state.setSelectedTrack(videoFile.path, index);
                          },
                        );
                      },
                    ),
                  ),
                  ElevatedButton(
                    onPressed: state.isProcessing
                        ? null
                        : () => _extractSubtitles(context),
                    child: Text(
                      state.isProcessing ? 'İşleniyor...' : 'Altyazıları Çıkar',
                    ),
                  ),
                ],
                if (state.isProcessing) ...[
                  const SizedBox(height: 16),
                  LinearProgressIndicator(value: state.progress),
                  const SizedBox(height: 8),
                  if (state.currentProcessingFile != null)
                    Text(
                      'İşleniyor: ${state.currentProcessingFile}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
