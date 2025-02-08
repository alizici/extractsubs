// lib/services/ffmpeg_service.dart
import 'package:extractsubs/models/subtitle_track.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';

class FFmpegService {
  static Future<List<SubtitleTrack>> getSubtitleTracks(String filePath) async {
    try {
      print('Checking file: $filePath');

      final String command = '-v info -i "$filePath"';
      print('Executing FFmpeg command: $command');

      final FFmpegSession session = await FFmpegKit.execute(command);
      final logs = await session.getAllLogsAsString() ?? '';
      print('FFmpeg logs: $logs');

      return _parseSubtitleTracksFromLogs(logs);
    } catch (e, stackTrace) {
      print('FFmpeg error: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  static Future<bool> extractSubtitle({
    required String inputPath,
    required String outputPath,
    required String format,
    int? trackIndex,
  }) async {
    try {
      // Stream index doğrudan kullan
      final String command =
          '-i "$inputPath" -map 0:${trackIndex} ${_getFormatFlags(format)} "$outputPath"';

      print('FFmpeg extraction command: $command');

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();
      final logs = await session.getAllLogsAsString() ?? '';

      print('Extraction logs: $logs');
      return ReturnCode.isSuccess(returnCode);
    } catch (e) {
      print('FFmpeg extraction error: $e');
      return false;
    }
  }

  static String _getFormatFlags(String format) {
    switch (format.toLowerCase()) {
      case 'srt':
        return '-c:s srt';
      case 'ass':
      case 'ssa':
        return '-c:s ass';
      case 'vtt':
        return '-c:s webvtt';
      default:
        return '-c:s copy';
    }
  }

  static List<SubtitleTrack> _parseSubtitleTracksFromLogs(String logs) {
    List<SubtitleTrack> tracks = [];
    try {
      // Stream bilgilerini bulmak için regex
      final streamRegex = RegExp(
        r'Stream #0:(\d+)(?:\[0x[^\]]+\])?(?:\((\w+)\))?\s*:\s*Subtitle:\s*(\w+)',
        multiLine: true,
      );

      final matches = streamRegex.allMatches(logs);
      print('Found ${matches.length} subtitle streams');

      for (var match in matches) {
        final streamData = match.group(0) ?? '';
        print('Processing stream: $streamData');

        final track = SubtitleTrack(
          index: int.tryParse(match.group(1) ?? '') ?? 0,
          language: match.group(2)?.toLowerCase() ?? 'und',
          codec: match.group(3)?.toLowerCase() ?? 'unknown',
          title: '',
        );

        print('Created track: $track');
        tracks.add(track);
      }
    } catch (e, stackTrace) {
      print('Parsing error: $e');
      print('Stack trace: $stackTrace');
    }

    print('Total tracks found: ${tracks.length}');
    return tracks;
  }
}
