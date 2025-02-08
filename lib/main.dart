// lib/main.dart
import 'package:extractsubs/providers/subtitle_state.dart';
import 'package:extractsubs/views/home_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => SubtitleState(),
      child: const SubtitleExtractorApp(),
    ),
  );
}

class SubtitleExtractorApp extends StatelessWidget {
  const SubtitleExtractorApp({Key? key}) : super(key: key);

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
