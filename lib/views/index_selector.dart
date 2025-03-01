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
    final sortedIndices = availableIndices.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Altyazı İndeksi:',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        DropdownButton<int>(
          value: selectedIndex,
          hint: const Text('İndeks seçin'),
          items: sortedIndices.map((index) {
            return DropdownMenuItem(
              value: index,
              child: Text('İndeks $index'),
            );
          }).toList(),
          onChanged: onIndexChanged,
        ),
      ],
    );
  }
}
