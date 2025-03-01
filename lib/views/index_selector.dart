// lib/views/index_selector.dart
import 'package:flutter/material.dart';

class IndexSelector extends StatelessWidget {
  final int? selectedIndex;
  final Set<int> availableIndices;
  final Function(int?) onIndexChanged;

  const IndexSelector({
    super.key,
    required this.selectedIndex,
    required this.availableIndices,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortedIndices = availableIndices.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Altyazı İndeksi:',
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
            child: DropdownButton<int?>(
              value: selectedIndex,
              hint: Text(
                'İndeks seçin',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withAlpha(179),
                ),
              ),
              items: [
                // Null seçeneği ekleyelim (seçimi temizlemek için)
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Row(
                    children: [
                      Icon(Icons.clear, size: 16),
                      SizedBox(width: 8),
                      Text('Seçimi Temizle'),
                    ],
                  ),
                ),
                // İndeks seçenekleri
                ...sortedIndices.map((index) {
                  return DropdownMenuItem(
                    value: index,
                    child: Row(
                      children: [
                        Icon(
                          Icons.subtitles_outlined,
                          size: 16,
                          color: index == selectedIndex
                              ? theme.primaryColor
                              : theme.colorScheme.onSurface.withAlpha(179),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'İndeks $index',
                          style: TextStyle(
                            fontWeight: index == selectedIndex
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: index == selectedIndex
                                ? theme.primaryColor
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              onChanged: onIndexChanged,
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
