// lib/main.dart
import 'package:extractsubs/providers/subtitle_state.dart';
import 'package:extractsubs/views/home_page.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';

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
    return MaterialApp(
      title: 'Altyazı Çıkarıcı',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
      ),
      home: const HomePage(),
    );
  }
}
