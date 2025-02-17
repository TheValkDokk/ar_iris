class FLNativeView: NSObject, FlutterPlatformView {
    private var containerView: UIView
    
    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?
    ) {
        self.containerView = UIView(frame: frame)
        super.init()
        
        let arViewController = ARViewController(binaryMessenger: messenger)

        arViewController.view.frame = containerView.bounds
        arViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        containerView.addSubview(arViewController.view)
            
        if let rootViewController = UIApplication.shared.keyWindow?.rootViewController {
            rootViewController.addChild(arViewController)
            arViewController.didMove(toParent: rootViewController)
        }
    }
    
    func view() -> UIView {
        return containerView
    }
}
