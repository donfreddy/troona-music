import 'package:flutter/material.dart';

class SliderTile extends StatelessWidget {
  final String label;
  final double value, min, max;
  final int divisions;
  final String Function(double) format;
  final ValueChanged<double> onChanged;

  const SliderTile({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.format,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(label),
    subtitle: Slider(
      value: value.clamp(min, max),
      min: min,
      max: max,
      divisions: divisions,
      label: format(value),
      onChanged: onChanged,
    ),
    trailing: SizedBox(
      width: 64,
      child: Text(format(value), textAlign: TextAlign.end),
    ),
  );
}
