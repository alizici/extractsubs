// lib/views/subtitle_editor_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  List<SubtitleEntry> originalSubtitles = []; // Orijinal altyazılar
  int? selectedIndex;
  bool isLoading = true;
  bool hasUnsavedChanges = false;

  // Düzenleme kontrolcüleri
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();

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

  // Replace the _loadSubtitles() method in subtitle_editor_page.dart with this updated version
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

      // Determine subtitle format based on file extension
      final fileExtension = widget.subtitlePath.toLowerCase().split('.').last;
      print('Subtitle format: $fileExtension');

      if (fileExtension == 'srt') {
        // SRT format parsing
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
          originalSubtitles = parsedSubtitles
              .map((s) => SubtitleEntry(
                    index: s.index,
                    startTime: s.startTime,
                    endTime: s.endTime,
                    text: s.text,
                  ))
              .toList();
          isLoading = false;
        });
      } else if (fileExtension == 'ass') {
        // ASS format parsing
        final lines = content.split('\n');
        final dialogueLines =
            lines.where((line) => line.startsWith('Dialogue:')).toList();

        print('Found ${dialogueLines.length} dialogue lines');

        final parsedSubtitles = <SubtitleEntry>[];

        for (int i = 0; i < dialogueLines.length; i++) {
          try {
            final subtitle = SubtitleEntry.fromAss(dialogueLines[i], i + 1);
            parsedSubtitles.add(subtitle);
          } catch (e) {
            print('Error parsing ASS line ${i + 1}: $e');
          }
        }

        setState(() {
          subtitles = parsedSubtitles;
          originalSubtitles = parsedSubtitles
              .map((s) => SubtitleEntry(
                    index: s.index,
                    startTime: s.startTime,
                    endTime: s.endTime,
                    text: s.text,
                  ))
              .toList();
          isLoading = false;
        });
      } else {
        print('Unsupported subtitle format: $fileExtension');
        setState(() {
          isLoading = false;
          subtitles = [];
          originalSubtitles = [];
        });
      }

      print('Successfully loaded ${subtitles.length} subtitles');
    } catch (e) {
      print('Subtitle loading error: $e');
      setState(() {
        isLoading = false;
        subtitles = [];
        originalSubtitles = [];
      });
    }
  }

// Also update the _saveSubtitles method to preserve the original format
  void _saveSubtitles() async {
    try {
      final file = File(widget.subtitlePath);
      final fileExtension = widget.subtitlePath.toLowerCase().split('.').last;
      String content;

      if (fileExtension == 'srt') {
        content = subtitles.map((s) => s.toSrt()).join('\n\n');
      } else if (fileExtension == 'ass') {
        // For ASS files, we need to preserve the header
        final originalContent = await file.readAsString();
        final lines = originalContent.split('\n');

        // Find where [Events] section starts
        int eventsIndex = lines.indexWhere((line) => line.trim() == '[Events]');
        if (eventsIndex == -1) {
          throw Exception(
              'Invalid ASS file format: [Events] section not found');
        }

        // Find the format line after [Events]
        int formatIndex = lines.indexWhere(
            (line) => line.trim().startsWith('Format:'), eventsIndex);
        if (formatIndex == -1) {
          throw Exception('Invalid ASS file format: Format line not found');
        }

        // Get style name from format
        String style = 'Default';
        // Try to find an existing dialogue line to get its style
        for (var line in lines) {
          if (line.startsWith('Dialogue:')) {
            final parts = line.split(',');
            if (parts.length > 3) {
              style = parts[3];
              break;
            }
          }
        }

        // Create new content with preserved header
        final header = lines.sublist(0, formatIndex + 1).join('\n');
        final dialogues = subtitles.map((s) => s.toAss(style)).join('\n');
        content = '$header\n$dialogues';
      } else {
        throw Exception('Unsupported format for saving: $fileExtension');
      }

      await file.writeAsString(content);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Altyazılar kaydedildi')),
        );
      }

      setState(() {
        hasUnsavedChanges = false;
        // Update original subtitles
        originalSubtitles = subtitles
            .map((s) => SubtitleEntry(
                  index: s.index,
                  startTime: s.startTime,
                  endTime: s.endTime,
                  text: s.text,
                ))
            .toList();
      });

      // Reload the subtitle
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

  // Değişiklikleri iptal et
  void _cancelChanges() {
    setState(() {
      subtitles = originalSubtitles
          .map((s) => SubtitleEntry(
                index: s.index,
                startTime: s.startTime,
                endTime: s.endTime,
                text: s.text,
              ))
          .toList();
      hasUnsavedChanges = false;
      selectedIndex = null;
      _clearEditingControllers();
    });
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

  Duration _parseDuration(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length != 3) return Duration.zero;

      final seconds = parts[2].split(',');
      if (seconds.length != 2) return Duration.zero;

      return Duration(
        hours: int.tryParse(parts[0]) ?? 0,
        minutes: int.tryParse(parts[1]) ?? 0,
        seconds: int.tryParse(seconds[0]) ?? 0,
        milliseconds: int.tryParse(seconds[1]) ?? 0,
      );
    } catch (e) {
      return Duration.zero;
    }
  }

  void _selectSubtitle(int index) {
    setState(() {
      selectedIndex = index;

      // Seçilen altyazının bilgilerini düzenleme alanlarına yerleştir
      _textController.text = subtitles[index].text;
      _startTimeController.text = _formatDuration(subtitles[index].startTime);
      _endTimeController.text = _formatDuration(subtitles[index].endTime);
    });

    // Seçilen altyazının olduğu zamana git
    _seekToSubtitle(subtitles[index]);
  }

// _updateSubtitle metodunun düzeltilmiş hali
  void _updateSubtitle() {
    if (selectedIndex == null) return;

    final startTime = _parseDuration(_startTimeController.text);
    final endTime = _parseDuration(_endTimeController.text);

    // Başlangıç zamanı bitiş zamanından sonra olamaz
    if (startTime >= endTime) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Başlangıç zamanı bitiş zamanından önce olmalıdır'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      // Mevcut nesneyi değiştirmek yerine yeni bir SubtitleEntry nesnesi oluştur
      final oldSubtitle = subtitles[selectedIndex!];
      subtitles[selectedIndex!] = SubtitleEntry(
        index: oldSubtitle.index,
        startTime: startTime,
        endTime: endTime,
        text: _textController.text,
      );
      hasUnsavedChanges = true;
    });

    // Zamanlamayı güncellediğimiz için videoda da o noktaya gidelim
    _seekToSubtitle(subtitles[selectedIndex!]);
  }

  void _clearEditingControllers() {
    _textController.clear();
    _startTimeController.clear();
    _endTimeController.clear();
  }

  @override
  void dispose() {
    player.dispose();
    _textController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Altyazı Düzenleyici'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (hasUnsavedChanges) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Kaydedilmemiş Değişiklikler'),
                  content: const Text(
                    'Kaydedilmemiş değişiklikler var. Çıkmak istediğinizden emin misiniz?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('İptal'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Dialog'u kapat
                        Navigator.pop(context); // Sayfadan çık
                      },
                      child: const Text('Çık'),
                    ),
                  ],
                ),
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.cancel),
            label: const Text('İptal'),
            onPressed: hasUnsavedChanges ? _cancelChanges : null,
          ),
          TextButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Kaydet'),
            onPressed: hasUnsavedChanges ? _saveSubtitles : null,
          ),
        ],
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
                        final currentSubtitle = subtitles.firstWhere(
                          (subtitle) =>
                              position >= subtitle.startTime &&
                              position <= subtitle.endTime,
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

                  // Düzenleme paneli
                  if (selectedIndex != null)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Altyazı #${subtitles[selectedIndex!].index} Düzenleme',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),

                          // Metin düzenleme
                          TextField(
                            controller: _textController,
                            decoration: const InputDecoration(
                              labelText: 'Altyazı Metni',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 12),

                          // Zamanlama düzenleme
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _startTimeController,
                                  decoration: const InputDecoration(
                                    labelText: 'Başlangıç (HH:MM:SS,MS)',
                                    border: OutlineInputBorder(),
                                  ),
                                  inputFormatters: [
                                    // Zamanlama formatı için maske
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9:,]'),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _endTimeController,
                                  decoration: const InputDecoration(
                                    labelText: 'Bitiş (HH:MM:SS,MS)',
                                    border: OutlineInputBorder(),
                                  ),
                                  inputFormatters: [
                                    // Zamanlama formatı için maske
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9:,]'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Güncelleme butonu
                          ElevatedButton.icon(
                            onPressed: _updateSubtitle,
                            icon: const Icon(Icons.update),
                            label: const Text('Güncelle'),
                          ),
                        ],
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
                          title: Text(
                            subtitle.text,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${_formatDuration(subtitle.startTime)} - ${_formatDuration(subtitle.endTime)}',
                          ),
                          onTap: () => _selectSubtitle(index),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _selectSubtitle(index),
                          ),
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
