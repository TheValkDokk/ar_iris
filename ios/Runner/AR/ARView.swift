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
        
        let arViewController = ARViewController()
        containerView.window?.rootViewController = arViewController
        containerView.window?.makeKeyAndVisible()
//        arViewController.view.frame = containerView.bounds
//        containerView.addSubview(arViewController.view)
    }
    
    func view() -> UIView {
        return containerView
    }
}
