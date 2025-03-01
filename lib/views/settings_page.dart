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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Uygulama Ayarları',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Karanlık Mod'),
            subtitle: const Text('Uygulamanın görünümünü değiştirir'),
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
          ),
          const Divider(),
          ListTile(
            title: const Text('Varsayılan Format'),
            subtitle: Text(
                'Altyazı çıkartılırken kullanılacak format: $_defaultFormat'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButton<String>(
              isExpanded: true,
              value: _defaultFormat,
              items: _availableFormats
                  .map((format) => DropdownMenuItem(
                        value: format,
                        child: Text(format.toUpperCase()),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _defaultFormat = value;
                  });
                  _saveSettings();
                }
              },
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Hakkında'),
            subtitle: const Text('Uygulama bilgileri ve bağımlılıklar'),
            trailing: const Icon(Icons.info_outline),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AboutPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
