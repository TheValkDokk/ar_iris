import 'package:flutter/material.dart';

class ARSlider extends StatefulWidget {
  const ARSlider({
    super.key,
    required this.initialValue,
    required this.onChanged,
    required this.min,
    required this.max,
  });

  final double initialValue;
  final Function(double) onChanged;
  final double min;
  final double max;

  @override
  State<ARSlider> createState() => _ARSliderState();
}

class _ARSliderState extends State<ARSlider> {
  double value = 0;

  @override
  void initState() {
    super.initState();
    value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return RotatedBox(
      quarterTurns: 3,
      child: Slider(
        value: value,
        min: widget.min,
        max: widget.max,
        onChanged: (value) {
          setState(() {
            this.value = value;
          });
          widget.onChanged(value);
        },
      ),
    );
  }
}
