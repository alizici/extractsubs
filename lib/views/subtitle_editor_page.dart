// lib/views/video_subtitle_editor_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:extractsubs/models/subtitle_entry.dart';

class VideoSubtitleEditorPage extends StatefulWidget {
  final String videoPath;
  final String subtitlePath;

  const VideoSubtitleEditorPage({
    super.key,
    required this.videoPath,
    required this.subtitlePath,
  });

  @override
  State<VideoSubtitleEditorPage> createState() =>
      _VideoSubtitleEditorPageState();
}

class _VideoSubtitleEditorPageState extends State<VideoSubtitleEditorPage> {
  late final player = Player();
  late final controller = VideoController(player);
  List<SubtitleEntry> subtitles = [];
  int? selectedIndex;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _loadSubtitles();
  }

  Future<void> _initializeVideo() async {
    try {
      await player.open(Media(
        widget.videoPath,
        extras: {
          'subtitle': [widget.subtitlePath],
          'subtitle-style': '''
{
  "Fontname": "Arial",
  "Fontsize": "28",
  "PrimaryColour": "&H00FFFFFF",
  "OutlineColour": "&H00000000",
  "BackColour": "&H80000000",
  "Bold": "1",
  "Alignment": "2",
  "MarginV": "40"
}''',
          'sub-codepage': 'utf-8',
          'ass-styles': '1'
        },
      ));

      await player.setVolume(100);
    } catch (e) {
      print('Video initialization error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Video yüklenirken hata: $e')),
        );
      }
    }
  }

  Future<void> _loadSubtitles() async {
    try {
      final file = File(widget.subtitlePath);
      if (!await file.exists()) {
        throw Exception('Altyazı dosyası bulunamadı: ${widget.subtitlePath}');
      }
      final content = await file.readAsString();
      if (content.isEmpty) {
        throw Exception('Altyazı dosyası boş: ${widget.subtitlePath}');
      }

      final blocks = content.split('\n\n');
      print('Found ${blocks.length} subtitle blocks');

      final parsedSubtitles = blocks
          .where((block) => block.trim().isNotEmpty)
          .map((block) {
            try {
              return SubtitleEntry.fromSrt(block);
            } catch (e) {
              print('Error parsing subtitle block: $e');
              return null;
            }
          })
          .where((subtitle) => subtitle != null)
          .cast<SubtitleEntry>()
          .toList();

      setState(() {
        subtitles = parsedSubtitles;
        isLoading = false;
      });

      print('Successfully loaded ${subtitles.length} subtitles');
    } catch (e) {
      print('Subtitle loading error: $e');
      setState(() {
        isLoading = false;
        subtitles = [];
      });
    }
  }

// Altyazı kaydetme fonksiyonunu da güncelle
  void _saveSubtitles() async {
    try {
      final file = File(widget.subtitlePath);
      final content = subtitles.map((s) => s.toSrt()).join('\n\n');
      await file.writeAsString(content);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Altyazılar kaydedildi')),
        );
      }

      // Altyazıyı yeniden yükle
      await player.open(Media(
        widget.videoPath,
        extras: {
          'subtitle': [widget.subtitlePath],
        },
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kayıt hatası: $e')),
        );
      }
    }
  }

  void _seekToSubtitle(SubtitleEntry subtitle) {
    player.seek(subtitle.startTime);
    player.play();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    String milliseconds =
        twoDigits(duration.inMilliseconds.remainder(1000) ~/ 10);
    return '$hours:$minutes:$seconds,$milliseconds';
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Altyazı Düzenleyici'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Video(
              controller: controller,
              controls: MaterialDesktopVideoControls,
            ),
          ),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (subtitles.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Altyazı bulunamadı'),
            )
          else
            Expanded(
              child: Column(
                children: [
                  // Aktif altyazı gösterimi
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey[900],
                    width: double.infinity,
                    child: StreamBuilder<Duration>(
                      stream: player.stream.position,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const SizedBox(height: 50);
                        }

                        final position = snapshot.data!;
                        final currentSubtitle = subtitles.lastWhere(
                          (subtitle) => position >= subtitle.startTime,
                          orElse: () => SubtitleEntry(
                            index: -1,
                            startTime: Duration.zero,
                            endTime: Duration.zero,
                            text: '',
                          ),
                        );

                        return Text(
                          currentSubtitle.text,
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                blurRadius: 2,
                                offset: Offset(1, 1),
                              )
                            ],
                          ),
                          textAlign: TextAlign.center,
                        );
                      },
                    ),
                  ),
                  // Altyazı listesi
                  Expanded(
                    child: ListView.builder(
                      itemCount: subtitles.length,
                      itemBuilder: (context, index) {
                        final subtitle = subtitles[index];
                        return ListTile(
                          selected: selectedIndex == index,
                          title: Text(subtitle.text),
                          subtitle: Text(
                            '${_formatDuration(subtitle.startTime)} - ${_formatDuration(subtitle.endTime)}',
                          ),
                          onTap: () => _seekToSubtitle(subtitle),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
