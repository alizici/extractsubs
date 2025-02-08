// lib/utils/video_utils.dart
import 'dart:async';
import 'dart:io';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'dart:convert';

import 'package:ffmpeg_kit_flutter/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';

class VideoUtils {
  // FFmpeg tarafından desteklenen yaygın video formatları
  static final Set<String> supportedVideoFormats = {
    'mp4', // MPEG-4 Part 14
    'mkv', // Matroska
    'avi', // Audio Video Interleave
    'mov', // QuickTime Movie
    'wmv', // Windows Media Video
    'flv', // Flash Video
    'webm', // WebM
    'm4v', // MPEG-4 Video
    'ts', // MPEG Transport Stream
    'mts', // MPEG Transport Stream (AVCHD)
    'mpg', // MPEG-1 Systems/Program Stream
    'mpeg', // MPEG-1 Systems/Program Stream
    'm2ts', // Blu-ray BDAV Container
    'vob', // DVD Video Object
    '3gp', // 3GPP Multimedia File
  };

  /// Dosya uzantısını kontrol eder
  static bool isVideoFormatSupported(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;
    return supportedVideoFormats.contains(extension);
  }

  /// Dosyanın video dosyası olup olmadığını FFmpeg ile kontrol eder
  /// Dosyanın video dosyası olup olmadığını FFmpeg ile kontrol eder
  /// Dosyanın video dosyası olup olmadığını FFmpeg ile kontrol eder
  static Future<bool> isValidVideoFile(String filePath) async {
    try {
      // First check if the file exists
      final file = File(filePath);
      if (!await file.exists()) {
        return false;
      }

      // Create a timeout future
      final timeoutFuture = Future.delayed(const Duration(seconds: 30), () {
        throw TimeoutException('FFmpeg validation timed out');
      });

      // Create the FFmpeg validation future
      final validationFuture = FFmpegKit.execute(
              '-v error -i "${Uri.file(filePath).toFilePath()}" -t 1 -f null -')
          .then((session) async {
        final ReturnCode? returnCode = await session.getReturnCode();
        final String? logs = await session.getAllLogsAsString();

        // Log the complete FFmpeg response for debugging

        // If we got a successful return code, it's a valid video file
        if (ReturnCode.isSuccess(returnCode)) {
          return true;
        }

        // Check for common video-related error messages that still indicate a valid file
        if (logs != null) {
          final lowerLogs = logs.toLowerCase();
          if (lowerLogs.contains('video') ||
              lowerLogs.contains('codec') ||
              lowerLogs.contains('stream') ||
              lowerLogs.contains('hevc') ||
              lowerLogs.contains('h264') ||
              lowerLogs.contains('h.264') ||
              lowerLogs.contains('avc')) {
            return true;
          }
        }

        return false;
      });

      // Race between timeout and validation
      return await Future.any([validationFuture, timeoutFuture]);
    } on TimeoutException {
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Video dosyasının temel bilgilerini döndürür
  static Future<Map<String, dynamic>> getVideoInfo(String filePath) async {
    try {
      final FFmpegSession session = await FFmpegKit.execute(
          '-i "$filePath" -v quiet -print_format json -show_streams -show_format');
      final String? output = await session.getAllLogsAsString();

      if (output == null || output.isEmpty) {
        return {};
      }

      try {
        final Map<String, dynamic> fullInfo = json.decode(output);
        final List<dynamic> streams = fullInfo['streams'] ?? [];
        final Map<String, dynamic> format = fullInfo['format'] ?? {};

        // Video stream'ini bul
        final videoStream = streams.firstWhere(
          (stream) => stream['codec_type'] == 'video',
          orElse: () => {},
        );

        if (videoStream.isEmpty) {
          return {};
        }

        return {
          'width': videoStream['width'],
          'height': videoStream['height'],
          'codec_name': videoStream['codec_name'],
          'duration': format['duration'],
          'size': format['size'],
          'bit_rate': format['bit_rate'],
        };
      } catch (e) {
        return {};
      }
    } catch (e) {
      return {};
    }
  }
}
