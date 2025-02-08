// lib/services/file_service.dart
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

class FileService {
  static Future<List<String>> pickVideoFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: true,
      );

      if (result != null) {
        return result.paths.whereType<String>().toList();
      }
      return [];
    } catch (e) {
      print('Dosya seçme hatası: $e');
      return [];
    }
  }

  static String getOutputPath(String inputPath, String format) {
    // Video dosyasının bulunduğu dizini al
    final directory = path.dirname(inputPath);

    // Dosya adını al
    final filename = path.basenameWithoutExtension(inputPath);

    // Benzersiz dosya adı oluştur
    String outputPath = path.join(directory, '$filename.$format');
    int counter = 1;

    // Eğer dosya zaten varsa, sonuna sayı ekleyerek yeni isim oluştur
    while (File(outputPath).existsSync()) {
      outputPath = path.join(directory, '${filename}_$counter.$format');
      counter++;
    }

    return outputPath;
  }
}
