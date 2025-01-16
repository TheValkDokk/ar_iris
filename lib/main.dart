import 'package:eye_hue/home_ios.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Flutter Demo', home: FaceDetectionPage());
    // return MaterialApp(title: 'Flutter Demo', home: LiveCameraScreen());
  }
}
