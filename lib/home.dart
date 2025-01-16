import 'dart:convert';
import 'dart:developer';
import 'package:image/image.dart' as img;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_editor/image_editor.dart';
import 'package:rxdart/subjects.dart';

import 'process.dart';

class LiveCameraScreen extends StatefulWidget {
  const LiveCameraScreen({super.key});

  @override
  _LiveCameraScreenState createState() => _LiveCameraScreenState();
}

class _LiveCameraScreenState extends State<LiveCameraScreen> {
  late CameraController _cameraController;
  bool _isProcessing = false;
  bool _isCameraInitialized = false;

  final BehaviorSubject<String> _processedImageSubject =
      BehaviorSubject<String>();
  Stream<String> get processedImageStream => _processedImageSubject.stream;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  /// Initialize the camera
  Future<void> _initializeCamera() async {
    try {
      // Get available cameras
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        final frontCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
        );

        _cameraController = CameraController(
          frontCamera,
          ResolutionPreset.low,
          enableAudio: false,
        );

        await _cameraController.initialize();
        setState(() {
          _isCameraInitialized = true;
        });
        _startImageStream();
      }
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  String sanitizeBase64(String base64Image) {
    final sanitizedBase64 = base64Image.replaceAll(RegExp(r'\s'), '');
    final paddedBase64 =
        sanitizedBase64.padRight((sanitizedBase64.length + 3) ~/ 4 * 4, '=');

    return paddedBase64;
  }

  Future<Uint8List?> _convertYUV420ToJPEG(CameraImage image) async {
    try {
      final int width = image.width;
      final int height = image.height;

      // Convert YUV420 to RGB
      final rgbBytes = _convertYUV420ToRGB(image);

      // Create an image object
      final img.Image imgData = img.Image.fromBytes(
        width: width,
        height: height,
        bytes: rgbBytes.buffer,
      );
      final ImageEditorOption option = ImageEditorOption();
      option.addOption(FlipOption(horizontal: true));
      final result = await ImageEditor.editImage(
          image: img.encodeJpg(imgData), imageEditorOption: option);
      // Encode the image to JPEG
      return result;
    } catch (e) {
      debugPrint('Error converting YUV to JPEG: $e');
      return null;
    }
  }

  Uint8List _convertYUV420ToRGB(CameraImage image) {
    final int width = image.width;
    final int height = image.height;

    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final yBytes = yPlane.bytes;
    final uBytes = uPlane.bytes;
    final vBytes = vPlane.bytes;

    final buffer = Uint8List(width * height * 3); // RGB requires 3 channels

    int bufferIndex = 0;
    for (int i = 0; i < height; i++) {
      for (int j = 0; j < width; j++) {
        final y = yBytes[i * width + j];
        final u = uBytes[(i ~/ 2) * (width ~/ 2) + (j ~/ 2)];
        final v = vBytes[(i ~/ 2) * (width ~/ 2) + (j ~/ 2)];

        // Convert YUV to RGB
        final r = (y + (1.370705 * (v - 128))).clamp(0, 255).toInt();
        final g = (y - (0.337633 * (u - 128)) - (0.698001 * (v - 128)))
            .clamp(0, 255)
            .toInt();
        final b = (y + (1.732446 * (u - 128))).clamp(0, 255).toInt();

        buffer[bufferIndex++] = r;
        buffer[bufferIndex++] = g;
        buffer[bufferIndex++] = b;
      }
    }

    return buffer;
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  Widget _renderProcessedImage(String processedImage) {
    try {
      return Center(
        child: Image.memory(
          height: 800,
          width: 800,
          fit: BoxFit.cover,
          base64Decode(processedImage),
          gaplessPlayback: true,
        ),
      );
    } catch (e) {
      log("Image String: $processedImage");
      return Container();
    }
  }

  void _startImageStream() {
    _cameraController.startImageStream((CameraImage image) async {
      if (_isProcessing) return;
      _isProcessing = true;

      try {
        final img = await _convertYUV420ToJPEG(image);
        if (!toggle) {
          if (img != null) {
            final base64Image = base64Encode(img);
            final processedImage =
                await OpenCVProcessor.processFrame(base64Image);
            final result = sanitizeBase64(processedImage!);
            _processedImageSubject.add(result);
          }
        } else {
          _processedImageSubject.add(base64Encode(img!));
        }
      } finally {
        _isProcessing = false;
      }
    });
  }

  bool toggle = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            toggle = !toggle;
          });
        },
        child: Icon(toggle ? Icons.play_arrow_sharp : Icons.stop),
      ),
      appBar: AppBar(
        title: Text('Demo'),
      ),
      body: StreamBuilder(
        stream: processedImageStream,
        builder: (context, snapshot) {
          if (snapshot.hasData &&
              snapshot.data != null &&
              snapshot.data is String) {
            return _renderProcessedImage(snapshot.data as String);
          }
          return Container();
        },
      ),
    );
  }
}
