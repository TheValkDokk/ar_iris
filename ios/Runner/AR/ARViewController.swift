import UIKit
import Foundation
import ARKit
import ios_platform_images

final class ARViewController: UIViewController {
    private let sceneView = ARSCNView(frame: .zero)
    
    var flutterMethodChannel: FlutterMethodChannel?
    
    private var messenger: FlutterBinaryMessenger?
    
    private var leftEyeNode: ImageNode?
    private var rightEyeNode: ImageNode?
    
    private var node: SCNNode?
    
    private var transparencyValue = 0.5
    
    private var rX: Float = 0.0
    private var rY: Float = 0.0
    private var rZ: Float = 0.0
    
    private var lX: Float = 0.0
    private var lY: Float = 0.0
    private var lZ: Float = 0.0
    
    private let faceTrackingConfiguration = ARFaceTrackingConfiguration()
    
    override func loadView() {
        view = sceneView
    }
    
    init(
        binaryMessenger messenger: FlutterBinaryMessenger?
    ) {
        self.messenger = messenger
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard ARFaceTrackingConfiguration.isSupported else { fatalError("A TrueDepth camera is required") }
        sceneView.delegate = self
        
        if let messenger = messenger {
            flutterMethodChannel = FlutterMethodChannel(
                name: "com.valk.eye_hue/ar",
                binaryMessenger: messenger
            )
            flutterMethodChannel?.setMethodCallHandler {
                [weak self] (call: FlutterMethodCall, result: FlutterResult) -> Void in
                self?.handleMethodCall(call, result: result)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sceneView.session.run(faceTrackingConfiguration)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        sceneView.session.pause()
    }
    
    private func handleMethodCall(_ call: FlutterMethodCall, result: FlutterResult) {
        switch call.method {
            case "updateEyeImage":
                if let args = call.arguments as? [String: Any],
                   let path = args["path"] as? String {
                    updateEyeImage(path: path)
                    result(true)
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing arguments", details: nil))
                }
            case "updateImageTransparency":
                if let args = call.arguments as? [String: Any],
                    let value = args["value"] as? Double {
                        updateEyeTransparency(value: value)
                        result(true)
                    }
            case "updateEyeAdjustment":
                if let args = call.arguments as? [String: Any],
                   let data = args["data"] as? [String: Any] {
                    let rX = data["_rX"] as? Double ?? 0
                    let rY = data["_rY"] as? Double ?? 0
                    let rZ = data["_rZ"] as? Double ?? 0
                    let lX = data["_lX"] as? Double ?? 0
                    let lY = data["_lY"] as? Double ?? 0
                    let lZ = data["_lZ"] as? Double ?? 0
                     updateEyeAdjustment(rX: Float(rX), rY: Float(rY), rZ: Float(rZ), lX: Float(lX), lY: Float(lY), lZ: Float(lZ))
                    print("rX: \(rX), rY: \(rY), rZ: \(rZ), lX: \(lX), lY: \(lY), lZ: \(lZ)")
                    result(true)
                }
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func updateEyeAdjustment(rX: Float, rY: Float, rZ: Float, lX: Float, lY: Float, lZ: Float) {
        rightEyeNode?.pivot = SCNMatrix4MakeTranslation(rX, rY, rZ)
        leftEyeNode?.pivot = SCNMatrix4MakeTranslation(lX, lY, lZ)
    }
    
    private func updateEyeTransparency(value: Double){
        self.transparencyValue = value
        rightEyeNode?.geometry?.firstMaterial?.transparency = value
        leftEyeNode?.geometry?.firstMaterial?.transparency = value
    }
    
    private func updateEyeImage(path: String) {
        guard let image = UIImage.flutterImageWithName(path) else {
            print("No Image found for \(path)")
            return
        }
        
        if let node = node {
            let oldRightEyeNode = rightEyeNode
            let oldLeftEyeNode = leftEyeNode
            
            rightEyeNode = ImageNode(width: 0.015, height: 0.015, image: image, transparency: transparencyValue)
            leftEyeNode = ImageNode(width: 0.015, height: 0.015, image: image, transparency: transparencyValue)
            
            node.replaceChildNode(oldRightEyeNode!, with: rightEyeNode!)
            node.replaceChildNode(oldLeftEyeNode!, with: leftEyeNode!)
        }
    }
}

extension ARViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard anchor is ARFaceAnchor,
            let device = sceneView.device else { return nil }
        
        let faceGeometry = ARSCNFaceGeometry(device: device)
        node = SCNNode(geometry: faceGeometry)
        
        node!.geometry?.firstMaterial?.colorBufferWriteMask = []
        
        let image = UIImage(named: "DefaultIris")
        
        if let image = image {
            rightEyeNode = ImageNode(width: 0.015, height: 0.015, image: image, transparency: transparencyValue)
            leftEyeNode = ImageNode(width: 0.015, height: 0.015, image: image, transparency: transparencyValue)
        }
        
        rightEyeNode?.pivot = SCNMatrix4MakeTranslation(rX, rY, rZ)
        leftEyeNode?.pivot = SCNMatrix4MakeTranslation(lX, lY, lZ)
        
//        rightEyeNode?.pivot = SCNMatrix4MakeTranslation(0, -0.0001, -0.01)
//        leftEyeNode?.pivot = SCNMatrix4MakeTranslation(0.0001, 0.001, -0.01)

        rightEyeNode.flatMap { node!.addChildNode($0) }
        leftEyeNode.flatMap { node!.addChildNode($0) }

        return node
    }
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor,
            let faceGeometry = node.geometry as? ARSCNFaceGeometry else { return }

        faceGeometry.update(from: faceAnchor.geometry)

        leftEyeNode?.simdTransform = faceAnchor.leftEyeTransform
        rightEyeNode?.simdTransform = faceAnchor.rightEyeTransform
    }
}
