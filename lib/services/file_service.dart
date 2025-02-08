// lib/services/file_service.dart
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:extractsubs/utils/video_utils.dart';
import 'dart:io';

class FileService {
  static Future<List<String>> pickVideoFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: VideoUtils.supportedVideoFormats.toList(),
        allowMultiple: true,
      );

      if (result != null) {
        final paths = result.paths.whereType<String>().toList();
        final validPaths = <String>[];
        final errors = <String>[];

        for (var path in paths) {
          final fileName = path.split('/').last;

          // File size check
          if (!await VideoUtils.isFileSizeValid(path)) {
            errors.add('$fileName: Dosya boyutu çok büyük (maksimum 4GB)');
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

        // Show errors if any
        if (errors.isNotEmpty) {
          throw FormatException(errors.join('\n'));
        }

        return validPaths;
      }
      return [];
    } catch (e) {
      print('File selection error: $e');
      rethrow;
    }
  }

  static String getOutputPath(String inputPath, String format) {
    final directory = path.dirname(inputPath);
    final filename = path.basenameWithoutExtension(inputPath);
    String outputPath = path.join(directory, '$filename.$format');
    int counter = 1;

    while (File(outputPath).existsSync()) {
      outputPath = path.join(directory, '${filename}_$counter.$format');
      counter++;
    }

    return outputPath;
  }

  /// Video dosyası hakkında detaylı bilgi al
  static Future<Map<String, dynamic>> getVideoDetails(String filePath) async {
    try {
      final info = await VideoUtils.getVideoInfo(filePath);

      if (info.isEmpty) {
        throw Exception('Video bilgileri alınamadı');
      }

      return info;
    } catch (e) {
      print('Video detayları alınırken hata: $e');
      rethrow;
    }
  }
}
