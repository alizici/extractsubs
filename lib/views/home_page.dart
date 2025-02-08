// lib/views/home_page.dart
import 'package:extractsubs/models/video_file.dart';
import 'package:extractsubs/providers/subtitle_state.dart';
import 'package:extractsubs/services/ffmpeg_service.dart';
import 'package:extractsubs/services/file_service.dart';
import 'package:extractsubs/utils/subtitle_utils.dart';
import 'package:extractsubs/views/format_selector.dart';
import 'package:extractsubs/views/index_selector.dart';
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
                  content: Text('$name: Dosya işlenirken hata oluştu: $e'),
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
          content: Text('${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      state.setProcessing(false);
    }
  }

  Future<void> _extractSubtitles(BuildContext context) async {
    final state = Provider.of<SubtitleState>(context, listen: false);
    if (state.videoFiles.isEmpty || state.selectedIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Lütfen önce video dosyalarını ve altyazı indeksini seçin'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // PGS/SUB kontrolü
    final codec = state.currentCodec;
    if (codec != null &&
        SubtitleUtils.isBitmapSubtitle(codec) &&
        state.selectedFormat != 'sup') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Bitmap altyazılar (PGS/SUB) sadece SUP formatında çıkartılabilir'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    state.setProcessing(true);
    final List<String> errors = [];
    final List<String> successes = [];

    try {
      int totalFiles = state.videoFiles.length;
      for (int i = 0; i < state.videoFiles.length; i++) {
        final videoFile = state.videoFiles[i];
        state.updateProgress(i / totalFiles, videoFile.name);

        final track = videoFile.subtitleTracks
            .where((track) => track.index == state.selectedIndex)
            .firstOrNull;

        if (track == null) {
          errors.add(
              '${videoFile.name} - İndeks ${state.selectedIndex} bulunamadı');
          continue;
        }

        final outputPath = FileService.getOutputPath(
          videoFile.path,
          state.selectedFormat,
        );

        final success = await FFmpegService.extractSubtitle(
          inputPath: videoFile.path,
          outputPath: outputPath,
          format: state.selectedFormat,
          trackIndex: track.index,
        );

        if (success) {
          successes.add('${videoFile.name} - ${track.language}');
        } else {
          errors.add('${videoFile.name} - ${track.language}');
        }
      }

      if (successes.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${successes.length} altyazı başarıyla çıkarıldı'),
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
                  const Text('Aşağıdaki altyazılar çıkarılamadı:'),
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
        title: const Text('Toplu Altyazı Çıkarıcı'),
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
          // Get current codec for warning
          final currentCodec = state.currentCodec;
          final showBitmapWarning = currentCodec != null &&
              SubtitleUtils.isBitmapSubtitle(currentCodec);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed:
                      state.isProcessing ? null : () => _pickFiles(context),
                  icon: const Icon(Icons.file_upload),
                  label: const Text('Video Dosyalarını Seç'),
                ),
                const SizedBox(height: 16),
                if (state.videoFiles.isNotEmpty) ...[
                  Row(
                    children: [
                      Expanded(
                        child: IndexSelector(
                          selectedIndex: state.selectedIndex,
                          availableIndices: state.availableIndices,
                          onIndexChanged: (index) =>
                              state.setSelectedIndex(index),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FormatSelector(
                          selectedFormat: state.selectedFormat,
                          onFormatChanged: (format) {
                            if (format != null) state.setFormat(format);
                          },
                          currentCodec: currentCodec,
                        ),
                      ),
                    ],
                  ),
                  if (showBitmapWarning) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: Colors.orange.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Bu altyazı bitmap formatında (PGS/SUB). '
                              'Sadece SUP formatında çıkartılabilir.',
                              style: TextStyle(
                                color: Colors.orange.shade900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Seçili Videolar (${state.videoFiles.length}):',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: state.videoFiles.length,
                      itemBuilder: (context, index) {
                        final videoFile = state.videoFiles[index];
                        final selectedTrack = state.selectedIndex != null
                            ? videoFile.subtitleTracks
                                .where((t) => t.index == state.selectedIndex)
                                .firstOrNull
                            : null;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.video_file),
                            title: Text(videoFile.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mevcut altyazılar: ${videoFile.subtitleTracks.map((t) => '${t.language} (${t.index})').join(", ")}',
                                ),
                                if (selectedTrack != null)
                                  Text(
                                    'Seçili: ${selectedTrack.language} (${selectedTrack.index})',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                if (state.selectedIndex != null &&
                                    selectedTrack == null)
                                  Text(
                                    'Uyarı: Seçili index ${state.selectedIndex} bu videoda mevcut değil',
                                    style: const TextStyle(
                                      color: Colors.orange,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () =>
                                  state.removeVideoFile(videoFile.path),
                              tooltip: 'Dosyayı Kaldır',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: state.isProcessing || state.selectedIndex == null
                        ? null
                        : () => _extractSubtitles(context),
                    icon: const Icon(Icons.download),
                    label: Text(
                      state.isProcessing
                          ? 'İşleniyor...'
                          : 'Seçili İndeksteki Altyazıları Çıkar',
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
