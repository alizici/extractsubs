// lib/views/format_selector.dart
import 'package:flutter/material.dart';
import '../utils/subtitle_utils.dart';

class FormatSelector extends StatelessWidget {
  final String selectedFormat;
  final Function(String?) onFormatChanged;
  final String? currentCodec;

  const FormatSelector({
    super.key,
    required this.selectedFormat,
    required this.onFormatChanged,
    this.currentCodec,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final availableFormats = currentCodec != null
        ? SubtitleUtils.getSupportedFormatsForCodec(currentCodec!)
        : ['srt', 'ass', 'ssa', 'vtt', 'sup'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Format:',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface.withAlpha(204),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? const Color(0xFF2C2C2E).withAlpha(153)
                : Colors.white.withAlpha(153),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: theme.brightness == Brightness.dark
                  ? Colors.grey[800]!.withAlpha(51)
                  : Colors.grey[300]!.withAlpha(128),
              width: 0.5,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: availableFormats.contains(selectedFormat)
                  ? selectedFormat
                  : availableFormats.first,
              items: availableFormats.map((format) {
                return DropdownMenuItem(
                  value: format,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.subtitles,
                        size: 16,
                        color: format == selectedFormat
                            ? theme.primaryColor
                            : theme.colorScheme.onSurface.withAlpha(179),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        format.toUpperCase(),
                        style: TextStyle(
                          fontWeight: format == selectedFormat
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: format == selectedFormat
                              ? theme.primaryColor
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (format) {
                if (format != null) {
                  onFormatChanged(format);
                }
              },
              icon: Icon(
                Icons.arrow_drop_down,
                color: theme.colorScheme.onSurface.withAlpha(179),
              ),
              isExpanded: true,
              dropdownColor: theme.brightness == Brightness.dark
                  ? const Color(0xFF2C2C2E)
                  : Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }
}
