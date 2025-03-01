// lib/main.dart
import 'package:extractsubs/providers/subtitle_state.dart';
import 'package:extractsubs/views/home_page.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  MediaKit.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (context) => SubtitleState(),
      child: const SubtitleExtractorApp(),
    ),
  );
}

class SubtitleExtractorApp extends StatelessWidget {
  const SubtitleExtractorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ThemeMode>(
      future: _loadThemeMode(),
      builder: (context, snapshot) {
        // Veriler yüklenene kadar varsayılan tema modu kullanılır
        final themeMode = snapshot.data ?? ThemeMode.system;

        return MaterialApp(
          title: 'Altyazı Çıkarıcı',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            brightness: Brightness.light,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.blue,
            useMaterial3: true,
          ),
          themeMode: themeMode,
          home: const HomePage(),
        );
      },
    );
  }

  Future<ThemeMode> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('isDarkMode') ?? false;
    return isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }
}
