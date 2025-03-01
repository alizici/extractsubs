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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hakkında'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // App info card
          Container(
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color(0xFF2C2C2E).withAlpha(153)
                  : Colors.white.withAlpha(153),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDarkMode
                    ? Colors.grey[800]!.withAlpha(51)
                    : Colors.grey[300]!.withAlpha(128),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.subtitles,
                      size: 48,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _packageInfo.appName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sürüm ${_packageInfo.version} (${_packageInfo.buildNumber})',
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.colorScheme.onSurface.withAlpha(179),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withAlpha(12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Bu uygulama video dosyalarından altyazı çıkartmak, düzenlemek ve eklemek için kullanılır.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: theme.colorScheme.onSurface.withAlpha(204),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Dependencies section
          Text(
            'Bağımlılıklar ve Lisanslar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withAlpha(230),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 12),

          // Dependency cards
          _buildDependencyCard(
            context,
            'FFmpeg',
            'Video işleme kütüphanesi',
            'LGPL v2.1',
            'https://ffmpeg.org/',
          ),
          _buildDependencyCard(
            context,
            'ffmpeg_kit_flutter',
            'Flutter için FFmpeg entegrasyonu',
            'LGPL v3.0',
            'https://github.com/arthenica/ffmpeg-kit',
          ),
          _buildDependencyCard(
            context,
            'media_kit',
            'Video oynatma kütüphanesi',
            'MIT',
            'https://github.com/media-kit/media-kit',
          ),
          _buildDependencyCard(
            context,
            'provider',
            'Flutter durum yönetimi kütüphanesi',
            'MIT',
            'https://pub.dev/packages/provider',
          ),
          _buildDependencyCard(
            context,
            'file_picker',
            'Dosya seçimi kütüphanesi',
            'MIT',
            'https://pub.dev/packages/file_picker',
          ),
          _buildDependencyCard(
            context,
            'path',
            'Dosya yolu işleme kütüphanesi',
            'BSD',
            'https://pub.dev/packages/path',
          ),
          _buildDependencyCard(
            context,
            'shared_preferences',
            'Lokal veri saklama kütüphanesi',
            'BSD',
            'https://pub.dev/packages/shared_preferences',
          ),
          _buildDependencyCard(
            context,
            'package_info_plus',
            'Uygulama paketi bilgileri kütüphanesi',
            'BSD',
            'https://pub.dev/packages/package_info_plus',
          ),
          _buildDependencyCard(
            context,
            'url_launcher',
            'URL açma kütüphanesi',
            'BSD',
            'https://pub.dev/packages/url_launcher',
          ),

          const SizedBox(height: 32),

          // Footer
          Center(
            child: Text(
              '© 2025 Altyazı Çıkarıcı',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withAlpha(153),
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Privacy policy button
          Center(
            child: Container(
              decoration: BoxDecoration(
                color: theme.primaryColor.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextButton.icon(
                onPressed: () => _launchUrl('https://example.com/privacy'),
                icon: Icon(
                  Icons.privacy_tip_outlined,
                  size: 18,
                  color: theme.primaryColor,
                ),
                label: Text(
                  'Gizlilik Politikası',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.primaryColor,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDependencyCard(
    BuildContext context,
    String name,
    String description,
    String license,
    String url,
  ) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _launchUrl(url),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.code,
                    color: theme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface.withAlpha(204),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withAlpha(26),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Lisans: $license',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: theme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.open_in_new,
                  size: 18,
                  color: theme.colorScheme.onSurface.withAlpha(128),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
