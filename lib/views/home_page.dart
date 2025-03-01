// lib/views/home_page.dart
import 'package:extractsubs/models/video_file.dart';
import 'package:extractsubs/providers/subtitle_state.dart';
import 'package:extractsubs/services/ffmpeg_service.dart';
import 'package:extractsubs/services/file_service.dart';
import 'package:extractsubs/utils/subtitle_utils.dart';
import 'package:extractsubs/utils/video_utils.dart';
import 'package:extractsubs/views/drag_drop_area.dart';
import 'package:extractsubs/views/format_selector.dart';
import 'package:extractsubs/views/index_selector.dart';
import 'package:extractsubs/views/settings_page.dart';
import 'package:extractsubs/views/subtitle_track_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<void> _processFiles(List<String> filePaths) async {
    final state = Provider.of<SubtitleState>(context, listen: false);
    state.setProcessing(true);

    try {
      // Validate files are valid video files
      final validPaths = <String>[];
      final errors = <String>[];

      for (var path in filePaths) {
        final fileName = path.split('/').last;

        // Check file extension
        if (!VideoUtils.isVideoFormatSupported(path)) {
          errors.add('$fileName: Desteklenmeyen dosya formatı');
          continue;
        }

        // Video format check
        if (!await VideoUtils.isValidVideoFile(path)) {
          errors.add(
              '$fileName: Video dosyası okunamadı veya desteklenmeyen format');
          continue;
        }

        validPaths.add(path);
      }

      if (validPaths.isNotEmpty) {
        final videoFiles = await Future.wait(
          validPaths.map((path) async {
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
        } else {
          // Add new files to existing files
          final currentFiles = state.videoFiles;
          state.setVideoFiles([...currentFiles, ...validFiles]);
        }
      }

      // Show errors if any
      if (errors.isNotEmpty) {
        if (context.mounted) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Dosya Hatası'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...errors.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text('• $e'),
                        )),
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
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      state.setProcessing(false);
    }
  }

  Future<void> _pickFiles(BuildContext context) async {
    try {
      final paths = await FileService.pickVideoFiles();
      if (paths.isNotEmpty) {
        await _processFiles(paths);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
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

    state.setProcessing(true);
    final List<String> errors = [];
    final List<String> successes = [];

    try {
      int totalFiles = state.videoFiles.length;
      for (int i = 0; i < state.videoFiles.length; i++) {
        final videoFile = state.videoFiles[i];
        state.updateProgress(i / totalFiles, videoFile.name);

        // Her video için seçili indeksi al (manuel veya global)
        final selectedIndex = state.getSelectedIndexForVideo(videoFile.path);
        final track = videoFile.subtitleTracks
            .where((track) => track.index == selectedIndex)
            .firstOrNull;

        if (track == null) {
          errors.add('${videoFile.name} - İndeks $selectedIndex bulunamadı');
          continue;
        }

        // PGS/SUB kontrolü
        if (SubtitleUtils.isBitmapSubtitle(track.codec) &&
            state.selectedFormat != 'sup') {
          errors.add(
              '${videoFile.name} - Bitmap altyazılar sadece SUP formatında çıkartılabilir');
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

  Future<void> _extractSingleSubtitle(
      BuildContext context, String videoPath, int trackIndex) async {
    final state = Provider.of<SubtitleState>(context, listen: false);
    state.setProcessing(true);

    try {
      final outputPath = FileService.getOutputPath(
        videoPath,
        state.selectedFormat,
      );

      final success = await FFmpegService.extractSubtitle(
        inputPath: videoPath,
        outputPath: outputPath,
        format: state.selectedFormat,
        trackIndex: trackIndex,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Altyazı başarıyla çıkarıldı'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Altyazı çıkarılırken hata oluştu'),
            backgroundColor: Colors.red,
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
          // Yeni eklenen ayarlar butonu
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
            tooltip: 'Ayarlar',
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
                // Sürükle-bırak alanı (tıklanabilir)
                DragDropArea(
                  onFilesDropped: _processFiles,
                  onTap: () => _pickFiles(context),
                  isProcessing: state.isProcessing,
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
                          child: Column(
                            children: [
                              ListTile(
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
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        state.isExpanded(videoFile.path)
                                            ? Icons.expand_less
                                            : Icons.expand_more,
                                      ),
                                      onPressed: () =>
                                          state.toggleExpanded(videoFile.path),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () =>
                                          state.removeVideoFile(videoFile.path),
                                      tooltip: 'Dosyayı Kaldır',
                                    ),
                                  ],
                                ),
                              ),
                              if (state.isExpanded(videoFile.path))
                                SubtitleTrackSelector(
                                  videoFile: videoFile,
                                  onExtract: (params) async {
                                    await _extractSingleSubtitle(
                                      context,
                                      params.videoPath,
                                      params.trackIndex,
                                    );
                                  },
                                ),
                            ],
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
