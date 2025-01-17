import 'package:arkit_plugin/arkit_plugin.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

class FaceDetectionPage extends StatefulWidget {
  const FaceDetectionPage({super.key});

  @override
  FaceDetectionPageState createState() => FaceDetectionPageState();
}

class FaceDetectionPageState extends State<FaceDetectionPage> {
  late ARKitController arkitController;
  ARKitNode? node;

  ARKitNode? leftEye;
  ARKitNode? rightEye;

  double irisScale = 1;
  double irisXRotation = 0;
  double distance = 1;

  @override
  void dispose() {
    arkitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Demo')),
      body: Column(
        children: [
          Expanded(
            child: ARKitSceneView(
              configuration: ARKitConfiguration.faceTracking,
              onARKitViewCreated: onARKitViewCreated,
            ),
          ),
          Text('Eye Distance: $distance'),
          Slider(
            min: -1,
            max: 2,
            value: distance,
            onChanged: (v) {
              setState(() {
                distance = v;
              });
            },
          ),
          // Text('Iris Scale: $irisScale'),
          // Slider(
          //   min: 0.5,
          //   max: 2,
          //   value: irisScale,
          //   onChanged: (v) {
          //     setState(() {
          //       irisScale = v;
          //     });
          //   },
          // ),
          SizedBox(height: 30),
        ],
      ),
    );
  }

  void onARKitViewCreated(ARKitController arkitController) {
    this.arkitController = arkitController;
    this.arkitController.onAddNodeForAnchor = _handleAddAnchor;
    this.arkitController.onUpdateNodeForAnchor = _handleUpdateAnchor;
  }

  void _handleAddAnchor(ARKitAnchor anchor) {
    if (anchor is! ARKitFaceAnchor) {
      return;
    }
    final material = ARKitMaterial(fillMode: ARKitFillMode.lines);
    anchor.geometry.materials.value = [material];

    leftEye = _createEye(anchor.leftEyeTransform);
    arkitController.add(leftEye!, parentNodeName: anchor.nodeName);
    rightEye = _createEye(anchor.rightEyeTransform);
    arkitController.add(rightEye!, parentNodeName: anchor.nodeName);
  }

  ARKitNode _createEye(Matrix4 transform) {
    final position = vector.Vector3(
      transform.getColumn(3).x,
      transform.getColumn(3).y,
      transform.getColumn(3).z,
    );
    final material = ARKitMaterial(
      transparency: 0.8,
      diffuse: ARKitMaterialProperty.color(
        const Color.fromARGB(255, 93, 173, 238),
      ),
    );

    final geo = ARKitPlane(
      materials: [material],
      width: 0.01,
      height: 0.01,
    );

    return ARKitNode(geometry: geo, position: position);
  }

  ARKitNode? getIrisNode(String eye) {
    if (eye == 'left') {
      return leftEye;
    } else {
      return rightEye;
    }
  }

  void _handleUpdateAnchor(ARKitAnchor anchor) {
    if (anchor is ARKitFaceAnchor && mounted) {
      final leftEyeTransform = anchor.leftEyeTransform;
      final rightEyeTransform = anchor.rightEyeTransform;

      final leftEyePosition = vector.Vector3(
        leftEyeTransform.getColumn(3).x,
        leftEyeTransform.getColumn(3).y,
        leftEyeTransform.getColumn(3).z,
      );
      final rightEyePosition = vector.Vector3(
        rightEyeTransform.getColumn(3).x,
        rightEyeTransform.getColumn(3).y,
        rightEyeTransform.getColumn(3).z,
      );

      final leftEyeForward = -vector.Vector3(
        leftEyeTransform.getColumn(2).x,
        leftEyeTransform.getColumn(2).y,
        leftEyeTransform.getColumn(2).z,
      ).normalized();
      final rightEyeForward = -vector.Vector3(
        rightEyeTransform.getColumn(2).x,
        rightEyeTransform.getColumn(2).y,
        rightEyeTransform.getColumn(2).z,
      ).normalized();

      final gazeTarget = vector.Vector3(0, 0, -1);

      final leftEyeRotation = computeRotation(
        leftEyeForward,
        gazeTarget - leftEyePosition,
      );
      final rightEyeRotation = computeRotation(
        rightEyeForward,
        gazeTarget - rightEyePosition,
      );

      updateIrisTransform(
        'left',
        leftEyePosition,
        leftEyeRotation,
        anchor.blendShapes['eyeBlink_L'] ?? 0,
      );
      updateIrisTransform(
        'right',
        rightEyePosition,
        rightEyeRotation,
        anchor.blendShapes['eyeBlink_R'] ?? 0,
      );
    }
  }

  vector.Quaternion computeRotation(vector.Vector3 from, vector.Vector3 to) {
    final normalizedFrom = from.normalized();
    final normalizedTo = to.normalized();

    final cross = normalizedFrom.cross(normalizedTo);

    final dot = normalizedFrom.dot(normalizedTo);

    final angle = dot.clamp(-1.0, 1.0);
    final axis = cross.normalized();

    return vector.Quaternion.axisAngle(axis, angle);
  }

  void updateIrisTransform(
    String eye,
    vector.Vector3 eyePosition,
    vector.Quaternion eyeRotation,
    double eyeBlink,
  ) {
    final irisNode = getIrisNode(eye);
    if (irisNode != null) {
      final rotationMatrix = quaternionToMatrix3(eyeRotation);
      vector.Vector3 forward;
      if (eye == 'left') {
        forward = vector.Vector3(-distance, 0, -1)
          ..applyMatrix3(rotationMatrix);
      } else {
        forward = vector.Vector3(distance, 0, -1)..applyMatrix3(rotationMatrix);
      }
      final irisOffset = -forward * 0.005;
      final newIrisPosition = eyePosition + irisOffset;
      irisNode.position = newIrisPosition;
      irisNode.rotation = rotationMatrix;
      final scale = 1 - eyeBlink;
      if (scale < 0.2) {
        irisNode.scale = vector.Vector3(0, 0, 0);
      } else {
        final ss = vector.Vector3(
          scale * irisScale,
          scale * irisScale,
          scale,
        );
        irisNode.scale = ss;
      }
    }
  }

  vector.Matrix3 quaternionToMatrix3(vector.Quaternion q) {
    final xx = q.x * q.x;
    final yy = q.y * q.y;
    final zz = q.z * q.z;
    final xy = q.x * q.y;
    final xz = q.x * q.z;
    final yz = q.y * q.z;
    final wx = q.w * q.x;
    final wy = q.w * q.y;
    final wz = q.w * q.z;

    final rotationMatrix = vector.Matrix3(
      1.0 - 2.0 * (yy + zz), 2.0 * (xy - wz), 2.0 * (xz + wy), // 1
      2.0 * (xy + wz), 1.0 - 2.0 * (xx + zz), 2.0 * (yz - wx), // 2
      2.0 * (xz - wy), 2.0 * (yz + wx), 1.0 - 2.0 * (xx + yy), // 3
    );

    return rotationMatrix;
  }
}
