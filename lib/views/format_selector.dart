// lib/views/format_selector.dart
import 'package:flutter/material.dart';

class FormatSelector extends StatelessWidget {
  final String selectedFormat;
  final Function(String?) onFormatChanged;

  const FormatSelector({
    Key? key,
    required this.selectedFormat,
    required this.onFormatChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: selectedFormat,
      items: ['srt', 'ass', 'ssa', 'vtt'].map((format) {
        return DropdownMenuItem(
          value: format,
          child: Text(format.toUpperCase()),
        );
      }).toList(),
      onChanged: onFormatChanged,
    );
  }
}
