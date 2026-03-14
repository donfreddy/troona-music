import 'package:flutter/material.dart';

class SegmentedRow<T> extends StatelessWidget {
  final String label;
  final List<T> values;
  final List<String> labels;
  final T selected;
  final ValueChanged<T> onChanged;

  const SegmentedRow({
    super.key,
    required this.label,
    required this.values,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(label),
    subtitle: Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SegmentedButton<T>(
        segments: [
          for (var i = 0; i < values.length; i++)
            ButtonSegment(value: values[i], label: Text(labels[i])),
        ],
        selected: {selected},
        onSelectionChanged: (s) => onChanged(s.first),
      ),
    ),
    isThreeLine: true,
  );
}
