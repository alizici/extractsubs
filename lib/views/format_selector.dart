// lib/views/format_selector.dart
import 'package:flutter/material.dart';
import '../utils/subtitle_utils.dart';

class FormatSelector extends StatelessWidget {
  final String selectedFormat;
  final Function(String?) onFormatChanged;
  final String? currentCodec;

  const FormatSelector({
    Key? key,
    required this.selectedFormat,
    required this.onFormatChanged,
    this.currentCodec,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final availableFormats = currentCodec != null
        ? SubtitleUtils.getSupportedFormatsForCodec(currentCodec!)
        : ['srt', 'ass', 'ssa', 'vtt', 'sup'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButton<String>(
          value: availableFormats.contains(selectedFormat)
              ? selectedFormat
              : availableFormats.first,
          items: availableFormats.map((format) {
            return DropdownMenuItem(
              value: format,
              child: Text(format.toUpperCase()),
            );
          }).toList(),
          onChanged: (format) {
            if (format != null) {
              onFormatChanged(format);
            }
          },
        ),
      ],
    );
  }
}
