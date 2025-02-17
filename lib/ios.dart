import 'package:eye_hue/eye_adjustment.dart';
import 'package:eye_hue/gen/assets.gen.dart';
import 'package:eye_hue/slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class IosAR extends StatefulWidget {
  const IosAR({super.key});

  @override
  State<IosAR> createState() => _IosARState();
}

class _IosARState extends State<IosAR> {
  static const platform = OptionalMethodChannel('com.valk.eye_hue/ar');
  final Map<String, dynamic> _creationParams = {
    "assetPath": Assets.irirs.demoIris.path,
  };

  EyeAdjustment _eyeAdjustment = EyeAdjustment(0, 0, 0, 0, 0, 0);

  final double _imageTransparency = 0.5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        spacing: 10,
        children: [
          FloatingActionButton(
            heroTag: 'edit',
            onPressed: _showEyeAdjustment,
            child: const Icon(Icons.edit),
          ),
          FloatingActionButton(
            heroTag: 'eye',
            onPressed: _showEyeImagePicker,
            child: const Icon(Icons.remove_red_eye_outlined),
          ),
        ],
      ),
      appBar: AppBar(
        title: const Text('IOS AR'),
      ),
      body: Stack(
        children: [
          UiKitView(
            viewType: 'ios_ar',
            onPlatformViewCreated: _onPlatformViewCreated,
            creationParamsCodec: StandardMessageCodec(),
            creationParams: _creationParams,
          ),
          Positioned(
            right: 0,
            child: ARSlider(
              initialValue: _imageTransparency,
              onChanged: (value) {
                _updateImageTransparency(value);
              },
              min: 0,
              max: 1,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onPlatformViewCreated(int id) async {}

  void _showEyeAdjustment() {
    showCupertinoModalBottomSheet(
      context: context,
      builder: (context) => EyeAdjustmentWidget(
          eyeAdjustment: _eyeAdjustment,
          onUpdate: (eyeAdjustment) {
            _eyeAdjustment = eyeAdjustment;
            _updateEyeAdjustment();
          }),
    );
  }

  void _showEyeImagePicker() {
    showCupertinoModalBottomSheet(
      context: context,
      builder: (context) => SizedBox(
        height: 600,
        child: Column(
          children: [
            SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  crossAxisCount:
                      MediaQuery.of(context).size.width < 600 ? 3 : 6,
                ),
                itemCount: Assets.irirs.values.length,
                itemBuilder: (context, index) => GestureDetector(
                  onTap: () {
                    _updateEyeImage(Assets.irirs.values[index].path);
                    Navigator.pop(context);
                  },
                  child: Image.asset(
                    Assets.irirs.values[index].path,
                    width: 100,
                    height: 100,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateEyeAdjustment() async {
    try {
      await platform.invokeMethod(
        'updateEyeAdjustment',
        {'data': _eyeAdjustment.toMap()},
      );
    } on PlatformException catch (e) {
      print("Failed to send eye adjustment: '${e.message}'.");
    }
  }

  Future<void> _updateEyeImage(String path) async {
    try {
      await platform.invokeMethod(
        'updateEyeImage',
        {'path': path},
      );
    } on PlatformException catch (e) {
      print("Failed to send image: '${e.message}'.");
    }
  }

  Future<void> _updateImageTransparency(double value) async {
    try {
      await platform.invokeMethod(
        'updateImageTransparency',
        {'value': value},
      );
    } on PlatformException catch (e) {
      print("Failed to send image: '${e.message}'.");
    }
  }
}
