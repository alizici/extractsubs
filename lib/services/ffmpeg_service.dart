// lib/services/ffmpeg_service.dart
import 'dart:io';

import 'package:extractsubs/models/subtitle_track.dart';
import 'package:extractsubs/utils/language_utils.dart';
import 'package:extractsubs/utils/subtitle_utils.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:path/path.dart' as path;

class FFmpegService {
  static Future<List<SubtitleTrack>> getSubtitleTracks(String filePath) async {
    try {
      print('Checking file: $filePath');

      final String command = '-v info -i "$filePath"';
      print('Executing FFmpeg command: $command');

      final session = await FFmpegKit.execute(command);
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
    required int trackIndex,
  }) async {
    try {
      // Önce altyazı stream'inin mevcut formatını al
      final tracks = await getSubtitleTracks(inputPath);
      final selectedTrack = tracks.firstWhere(
        (track) => track.index == trackIndex,
        orElse: () => throw Exception('Altyazı parçası bulunamadı'),
      );

      // Bitmap altyazı kontrolü - Önemli: Buradan sonra return edilmeli
      if (SubtitleUtils.isBitmapSubtitle(selectedTrack.codec)) {
        if (format.toLowerCase() != 'sup') {
          // Eğer PGS/SUP altyazısı için SUP dışında bir format seçildiyse hata ver
          throw Exception(
              'Bitmap altyazılar (PGS/SUB) sadece SUP formatında çıkartılabilir');
        }
        final command =
            '-i "$inputPath" -map 0:$trackIndex -c:s copy "$outputPath"';
        print('FFmpeg bitmap subtitle extraction command: $command');
        final session = await FFmpegKit.execute(command);
        final logs = await session.getAllLogsAsString() ?? '';
        print('Bitmap extraction logs: $logs');
        return ReturnCode.isSuccess(await session.getReturnCode());
      }

      // Buraya kadar gelindiyse bitmap değildir, diğer dönüşümlere devam et
      String command;
      final inputCodec = selectedTrack.codec.toLowerCase();
      format = format.toLowerCase();

      // ASS/SSA formatları arasında dönüşüm
      if ((inputCodec == 'ass' || inputCodec == 'ssa') &&
          (format == 'ass' || format == 'ssa')) {
        command = '-i "$inputPath" -map 0:$trackIndex -c:s copy "$outputPath"';
      }
      // SRT formatı arasında dönüşüm
      else if (inputCodec == 'subrip' && format == 'srt') {
        command = '-i "$inputPath" -map 0:$trackIndex -c:s copy "$outputPath"';
      }
      // ASS/SSA -> SRT dönüşümü
      else if ((inputCodec == 'ass' || inputCodec == 'ssa') &&
          format == 'srt') {
        command = '-i "$inputPath" -map 0:$trackIndex -c:s srt "$outputPath"';
      }
      // SRT -> ASS dönüşümü
      else if (inputCodec == 'subrip' && (format == 'ass' || format == 'ssa')) {
        command = '-i "$inputPath" -map 0:$trackIndex -c:s ass "$outputPath"';
      }
      // ASS/SSA/SRT -> WebVTT dönüşümü
      else if ((inputCodec == 'ass' ||
              inputCodec == 'ssa' ||
              inputCodec == 'subrip') &&
          format == 'vtt') {
        // WebVTT'ye dönüşüm için önce SRT'ye dönüştür, sonra WebVTT'ye
        final tempPath = '${outputPath}_temp.srt';
        final firstCommand =
            '-i "$inputPath" -map 0:$trackIndex -c:s srt "$tempPath"';
        final secondCommand = '-i "$tempPath" -c:s webvtt "$outputPath"';

        // İki aşamalı dönüşüm yap
        final firstSession = await FFmpegKit.execute(firstCommand);
        final firstSuccess =
            ReturnCode.isSuccess(await firstSession.getReturnCode());

        if (!firstSuccess) {
          print(
              'İlk dönüşüm başarısız: ${await firstSession.getAllLogsAsString()}');
          return false;
        }

        final secondSession = await FFmpegKit.execute(secondCommand);
        final success =
            ReturnCode.isSuccess(await secondSession.getReturnCode());

        // Temp dosyayı temizle
        try {
          await File(tempPath).delete();
        } catch (e) {
          print('Temp dosya silinirken hata: $e');
        }

        return success;
      }
      // WebVTT -> Diğer formatlar
      else if (inputCodec == 'webvtt') {
        if (format == 'srt') {
          command = '-i "$inputPath" -map 0:$trackIndex -c:s srt "$outputPath"';
        } else if (format == 'ass' || format == 'ssa') {
          command = '-i "$inputPath" -map 0:$trackIndex -c:s ass "$outputPath"';
        } else {
          command =
              '-i "$inputPath" -map 0:$trackIndex -c:s copy "$outputPath"';
        }
      } else {
        throw Exception(
            'Desteklenmeyen format dönüşümü: $inputCodec -> $format');
      }

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

  static List<SubtitleTrack> _parseSubtitleTracksFromLogs(String logs) {
    List<SubtitleTrack> tracks = [];
    try {
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

  static Future<bool> addSubtitle({
    required String videoPath,
    required String subtitlePath,
    required String outputPath,
    String language = 'und',
  }) async {
    try {
      // Dil kodunu normalize et
      final normalizedLanguage = LanguageUtils.normalizeLanguageCode(language);

      // FFmpeg komutunu hazırla
      final String command = '-i "$videoPath" -i "$subtitlePath" -map 0 -map 1 '
          '-c copy -metadata:s:s:0 language=$normalizedLanguage '
          '"$outputPath"';

      print('FFmpeg add subtitle command: $command');
      print('Using language code: $normalizedLanguage');

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();
      final logs = await session.getAllLogsAsString() ?? '';

      if (!ReturnCode.isSuccess(returnCode)) {
        print('Add subtitle failed. FFmpeg logs: $logs');
        return false;
      }

      print('Successfully added subtitle with language: $normalizedLanguage');
      return true;
    } catch (e, stackTrace) {
      print('FFmpeg add subtitle error: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  static Future<bool> batchExtractSubtitles({
    required String inputPath,
    required String outputDir,
    required String format,
  }) async {
    try {
      // Tüm altyazı parçalarını çıkar
      final tracks = await getSubtitleTracks(inputPath);

      // Altyazı parçası bulunamadıysa false döndür
      if (tracks.isEmpty) {
        print('Dosyada altyazı parçası bulunamadı: $inputPath');
        return false;
      }

      bool allSuccess = true;

      for (var track in tracks) {
        final outputPath =
            '$outputDir/${path.basenameWithoutExtension(inputPath)}_${track.language}_${track.index}.$format';

        final success = await extractSubtitle(
          inputPath: inputPath,
          outputPath: outputPath,
          format: format,
          trackIndex: track.index,
        );

        if (!success) {
          allSuccess = false;
        }
      }

      return allSuccess;
    } catch (e) {
      print('Batch extraction error: $e');
      return false;
    }
  }
}
