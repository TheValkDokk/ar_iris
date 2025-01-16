import 'package:flutter/services.dart';

class OpenCVProcessor {
  static const MethodChannel _channel = MethodChannel('opencv/eye_color');

  static Future<String?> processFrame(String imageBase64) async {
    try {
      final String? processedImage =
          await _channel.invokeMethod('processFrame', {
        'image': imageBase64,
      });
      return processedImage;
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }
}
