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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

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
            icon: Icon(
              Icons.cancel_outlined,
              color: hasUnsavedChanges
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurface.withAlpha(128),
            ),
            label: Text(
              'İptal',
              style: TextStyle(
                color: hasUnsavedChanges
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurface.withAlpha(128),
              ),
            ),
            onPressed: hasUnsavedChanges ? _cancelChanges : null,
          ),
          const SizedBox(width: 8),
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: hasUnsavedChanges
                  ? theme.primaryColor
                  : theme.primaryColor.withAlpha(128),
              borderRadius: BorderRadius.circular(6),
            ),
            child: TextButton.icon(
              icon: const Icon(Icons.save, color: Colors.white, size: 18),
              label: const Text(
                'Kaydet',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: hasUnsavedChanges ? _saveSubtitles : null,
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Video Player Container
          Container(
            decoration: BoxDecoration(
              color: Colors.black,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(60),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                child: Video(
                  controller: controller,
                  controls: MaterialDesktopVideoControls,
                ),
              ),
            ),
          ),

          if (isLoading)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: theme.primaryColor),
                    const SizedBox(height: 16),
                    Text(
                      'Altyazılar yükleniyor...',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withAlpha(204),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (subtitles.isEmpty)
            Expanded(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? const Color(0xFF2C2C2E).withAlpha(153)
                        : Colors.white.withAlpha(153),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.grey[800]!.withAlpha(51)
                          : Colors.grey[300]!.withAlpha(128),
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.subtitles_off,
                        size: 48,
                        color: theme.colorScheme.onSurface.withAlpha(153),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Altyazı bulunamadı',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface.withAlpha(204),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  // Aktif altyazı gösterimi
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 24),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[900] : Colors.grey[200],
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    width: double.infinity,
                    alignment: Alignment.center,
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

                        if (currentSubtitle.text.isEmpty) {
                          return SizedBox(
                            height: 50,
                            child: Center(
                              child: Text(
                                'Aktif altyazı yok',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                  color: theme.colorScheme.onSurface
                                      .withAlpha(153),
                                ),
                              ),
                            ),
                          );
                        }

                        return Text(
                          currentSubtitle.text,
                          style: TextStyle(
                            fontSize: 20,
                            color: isDarkMode ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w500,
                            shadows: [
                              Shadow(
                                color: Colors.black
                                    .withAlpha(isDarkMode ? 100 : 50),
                                blurRadius: 2,
                                offset: const Offset(0.5, 0.5),
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
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF2C2C2E).withAlpha(153)
                            : Colors.white.withAlpha(153),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(10),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor.withAlpha(26),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Altyazı #${subtitles[selectedIndex!].index}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: theme.primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Düzenleme',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.onSurface
                                      .withAlpha(204),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Metin düzenleme
                          TextField(
                            controller: _textController,
                            decoration: InputDecoration(
                              labelText: 'Altyazı Metni',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: theme.colorScheme.onSurface
                                      .withAlpha(100),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: theme.colorScheme.onSurface
                                      .withAlpha(100),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: theme.primaryColor,
                                ),
                              ),
                              filled: true,
                              fillColor: isDarkMode
                                  ? Colors.black.withAlpha(50)
                                  : Colors.white.withAlpha(230),
                            ),
                            maxLines: 3,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Zamanlama düzenleme
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _startTimeController,
                                  decoration: InputDecoration(
                                    labelText: 'Başlangıç (HH:MM:SS,MS)',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: theme.colorScheme.onSurface
                                            .withAlpha(100),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: theme.primaryColor,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: isDarkMode
                                        ? Colors.black.withAlpha(50)
                                        : Colors.white.withAlpha(230),
                                    prefixIcon: Icon(
                                      Icons.play_circle_outline,
                                      color: theme.colorScheme.onSurface
                                          .withAlpha(153),
                                    ),
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9:,]'),
                                    ),
                                  ],
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _endTimeController,
                                  decoration: InputDecoration(
                                    labelText: 'Bitiş (HH:MM:SS,MS)',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: theme.colorScheme.onSurface
                                            .withAlpha(100),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: theme.primaryColor,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: isDarkMode
                                        ? Colors.black.withAlpha(50)
                                        : Colors.white.withAlpha(230),
                                    prefixIcon: Icon(
                                      Icons.stop_circle_outlined,
                                      color: theme.colorScheme.onSurface
                                          .withAlpha(153),
                                    ),
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9:,]'),
                                    ),
                                  ],
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Güncelleme butonu
                          Container(
                            width: double.infinity,
                            height: 44,
                            decoration: BoxDecoration(
                              color: theme.primaryColor,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.primaryColor.withAlpha(60),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: _updateSubtitle,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.update,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Güncelle',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Altyazı listesi
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF1C1C1E).withAlpha(230)
                            : Colors.grey[50],
                      ),
                      child: ListView.builder(
                        itemCount: subtitles.length,
                        itemBuilder: (context, index) {
                          final subtitle = subtitles[index];
                          final isSelected = selectedIndex == index;

                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.primaryColor.withAlpha(26)
                                  : isDarkMode
                                      ? const Color(0xFF2C2C2E).withAlpha(153)
                                      : Colors.white.withAlpha(153),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? theme.primaryColor
                                    : isDarkMode
                                        ? Colors.grey[800]!.withAlpha(51)
                                        : Colors.grey[300]!.withAlpha(128),
                                width: 0.5,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () => _selectSubtitle(index),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Index & Time Column
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? theme.primaryColor
                                                  : theme.colorScheme.onSurface
                                                      .withAlpha(26),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '#${subtitle.index}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: isSelected
                                                    ? Colors.white
                                                    : theme
                                                        .colorScheme.onSurface
                                                        .withAlpha(204),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.timer_outlined,
                                                size: 12,
                                                color: theme
                                                    .colorScheme.onSurface
                                                    .withAlpha(153),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _formatDuration(
                                                    subtitle.startTime),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: theme
                                                      .colorScheme.onSurface
                                                      .withAlpha(153),
                                                  fontFamily: 'monospace',
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.timer_off_outlined,
                                                size: 12,
                                                color: theme
                                                    .colorScheme.onSurface
                                                    .withAlpha(153),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _formatDuration(
                                                    subtitle.endTime),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: theme
                                                      .colorScheme.onSurface
                                                      .withAlpha(153),
                                                  fontFamily: 'monospace',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),

                                      const SizedBox(width: 16),

                                      // Text Column
                                      Expanded(
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(top: 2),
                                          child: Text(
                                            subtitle.text,
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: isSelected
                                                  ? theme.primaryColor
                                                  : theme.colorScheme.onSurface,
                                              fontWeight: isSelected
                                                  ? FontWeight.w500
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Edit Button
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8),
                                        child: IconButton(
                                          icon: Icon(
                                            Icons.edit,
                                            size: 20,
                                            color: isSelected
                                                ? theme.primaryColor
                                                : theme.colorScheme.onSurface
                                                    .withAlpha(153),
                                          ),
                                          style: IconButton.styleFrom(
                                            backgroundColor: isSelected
                                                ? theme.primaryColor
                                                    .withAlpha(26)
                                                : Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          onPressed: () =>
                                              _selectSubtitle(index),
                                          tooltip: 'Düzenle',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
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
