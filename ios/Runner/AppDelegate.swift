import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        guard let pluginRegistrar = self.registrar(forPlugin: "plugin-name") else { return false }

        let factory = FLNativeViewFactory(messenger: pluginRegistrar.messenger())
        pluginRegistrar.register(
            factory,
            withId: "ios_ar")
        
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        
        let arChannel = FlutterMethodChannel(
            name: "com.valk.eye_hue/ar",
            binaryMessenger: controller.binaryMessenger
        )
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
