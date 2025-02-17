// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/material.dart';

class EyeAdjustment {
  final double _rX;
  final double _rY;
  final double _rZ;
  final double _lX;
  final double _lY;
  final double _lZ;

  EyeAdjustment(this._rX, this._rY, this._rZ, this._lX, this._lY, this._lZ);

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      '_rX': _rX,
      '_rY': _rY,
      '_rZ': _rZ,
      '_lX': _lX,
      '_lY': _lY,
      '_lZ': _lZ,
    };
  }

  factory EyeAdjustment.fromMap(Map<String, dynamic> map) {
    return EyeAdjustment(
      map['_rX'] as double,
      map['_rY'] as double,
      map['_rZ'] as double,
      map['_lX'] as double,
      map['_lY'] as double,
      map['_lZ'] as double,
    );
  }

  String toJson() => json.encode(toMap());

  factory EyeAdjustment.fromJson(String source) =>
      EyeAdjustment.fromMap(json.decode(source) as Map<String, dynamic>);
}

class EyeAdjustmentWidget extends StatefulWidget {
  const EyeAdjustmentWidget({
    super.key,
    required this.eyeAdjustment,
    required this.onUpdate,
  });

  final EyeAdjustment eyeAdjustment;
  final Function(EyeAdjustment) onUpdate;

  @override
  State<EyeAdjustmentWidget> createState() => _EyeAdjustmentWidgetState();
}

class _EyeAdjustmentWidgetState extends State<EyeAdjustmentWidget> {
  double _rX = 0.0;
  double _rY = 0.0;
  double _rZ = 0.0;
  double _lX = 0.0;
  double _lY = 0.0;
  double _lZ = 0.0;

  void _onUpdate(String attribute, double value) {
    setState(() {
      switch (attribute) {
        case 'rX':
          _rX = value;
        case 'rY':
          _rY = value;
        case 'rZ':
          _rZ = value;
        case 'lX':
          _lX = value;
        case 'lY':
          _lY = value;
        case 'lZ':
          _lZ = value;
      }
    });
    widget.onUpdate(EyeAdjustment(_rX, _rY, _rZ, _lX, _lY, _lZ));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Material(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildEyeAdjustment(_rX, (value) {
              _onUpdate('rX', value);
            }),
            _buildEyeAdjustment(_rY, (value) {
              _onUpdate('rY', value);
            }),
            _buildEyeAdjustment(_rZ, (value) {
              _onUpdate('rZ', value);
            }),
            _buildEyeAdjustment(_lX, (value) {
              _onUpdate('lX', value);
            }),
            _buildEyeAdjustment(_lY, (value) {
              _onUpdate('lY', value);
            }),
            _buildEyeAdjustment(_lZ, (value) {
              _onUpdate('lZ', value);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEyeAdjustment(double value, Function(double) onChanged) {
    return RotatedBox(
      quarterTurns: 3,
      child: Slider(
        max: 0.005,
        min: -0.005,
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
