// lib/views/settings_page.dart
import 'package:extractsubs/views/about_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:extractsubs/providers/subtitle_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isDarkMode = false;
  String _defaultFormat = 'srt';
  final List<String> _availableFormats = ['srt', 'ass', 'ssa', 'vtt', 'sup'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      _defaultFormat = prefs.getString('defaultFormat') ?? 'srt';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    await prefs.setString('defaultFormat', _defaultFormat);

    // Update the app state
    if (mounted) {
      final state = Provider.of<SubtitleState>(context, listen: false);
      state.setFormat(_defaultFormat);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              'Uygulama Ayarları',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withAlpha(230),
              ),
            ),
          ),
          Container(
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
                  color: Colors.black.withAlpha(10),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Dark Mode Toggle
                ListTile(
                  title: Text(
                    'Karanlık Mod',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    'Uygulamanın görünümünü değiştirir',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withAlpha(179),
                    ),
                  ),
                  trailing: Switch(
                    value: _isDarkMode,
                    onChanged: (value) {
                      setState(() {
                        _isDarkMode = value;
                      });
                      _saveSettings();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Ayarlar kaydedildi. Değişikliklerin uygulanması için uygulamayı yeniden başlatın.'),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    },
                    activeColor: theme.primaryColor,
                  ),
                ),

                Divider(
                  height: 1,
                  thickness: 0.5,
                  indent: 16,
                  endIndent: 16,
                  color: theme.dividerColor.withAlpha(128),
                ),

                // Default Format Section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Varsayılan Format',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Altyazı çıkartılırken kullanılacak format',
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurface.withAlpha(179),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? const Color(0xFF2C2C2E).withAlpha(153)
                              : Colors.white.withAlpha(153),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDarkMode
                                ? Colors.grey[800]!.withAlpha(51)
                                : Colors.grey[300]!.withAlpha(128),
                            width: 0.5,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _defaultFormat,
                            items: _availableFormats.map((format) {
                              return DropdownMenuItem(
                                value: format,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.subtitles,
                                      size: 16,
                                      color: format == _defaultFormat
                                          ? theme.primaryColor
                                          : theme.colorScheme.onSurface
                                              .withAlpha(179),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      format.toUpperCase(),
                                      style: TextStyle(
                                        fontWeight: format == _defaultFormat
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        color: format == _defaultFormat
                                            ? theme.primaryColor
                                            : theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _defaultFormat = value;
                                });
                                _saveSettings();
                              }
                            },
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: theme.colorScheme.onSurface.withAlpha(179),
                            ),
                            isExpanded: true,
                            dropdownColor: isDarkMode
                                ? const Color(0xFF2C2C2E)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // About section
          Container(
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
                  color: Colors.black.withAlpha(10),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AboutPage(),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16.0, horizontal: 16.0),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withAlpha(26),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.info_outline,
                          color: theme.primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hakkında',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Uygulama bilgileri ve bağımlılıklar',
                              style: TextStyle(
                                fontSize: 13,
                                color:
                                    theme.colorScheme.onSurface.withAlpha(179),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: theme.colorScheme.onSurface.withAlpha(179),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
