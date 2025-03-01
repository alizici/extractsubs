// lib/views/about_page.dart
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  PackageInfo _packageInfo = PackageInfo(
    appName: 'Altyazı Çıkarıcı',
    packageName: 'com.example.extractsubs',
    version: '1.0.0',
    buildNumber: '1',
  );

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('URL açılamadı: $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hakkında'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.subtitles,
                    size: 64,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _packageInfo.appName,
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sürüm ${_packageInfo.version} (${_packageInfo.buildNumber})',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Bu uygulama video dosyalarından altyazı çıkartmak, düzenlemek ve eklemek için kullanılır.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Bağımlılıklar ve Lisanslar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildDependencyCard(
            'FFmpeg',
            'Video işleme kütüphanesi',
            'LGPL v2.1',
            'https://ffmpeg.org/',
          ),
          _buildDependencyCard(
            'ffmpeg_kit_flutter',
            'Flutter için FFmpeg entegrasyonu',
            'LGPL v3.0',
            'https://github.com/arthenica/ffmpeg-kit',
          ),
          _buildDependencyCard(
            'media_kit',
            'Video oynatma kütüphanesi',
            'MIT',
            'https://github.com/media-kit/media-kit',
          ),
          _buildDependencyCard(
            'provider',
            'Flutter durum yönetimi kütüphanesi',
            'MIT',
            'https://pub.dev/packages/provider',
          ),
          _buildDependencyCard(
            'file_picker',
            'Dosya seçimi kütüphanesi',
            'MIT',
            'https://pub.dev/packages/file_picker',
          ),
          _buildDependencyCard(
            'path',
            'Dosya yolu işleme kütüphanesi',
            'BSD',
            'https://pub.dev/packages/path',
          ),
          _buildDependencyCard(
            'shared_preferences',
            'Lokal veri saklama kütüphanesi',
            'BSD',
            'https://pub.dev/packages/shared_preferences',
          ),
          _buildDependencyCard(
            'package_info_plus',
            'Uygulama paketi bilgileri kütüphanesi',
            'BSD',
            'https://pub.dev/packages/package_info_plus',
          ),
          _buildDependencyCard(
            'url_launcher',
            'URL açma kütüphanesi',
            'BSD',
            'https://pub.dev/packages/url_launcher',
          ),
          const SizedBox(height: 32),
          const Text(
            '© 2025 Altyazı Çıkarıcı',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _launchUrl('https://example.com/privacy'),
            child: const Text('Gizlilik Politikası'),
          ),
        ],
      ),
    );
  }

  Widget _buildDependencyCard(
    String name,
    String description,
    String license,
    String url,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        title: Text(name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description),
            Text('Lisans: $license', style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: const Icon(Icons.link),
        onTap: () => _launchUrl(url),
      ),
    );
  }
}
