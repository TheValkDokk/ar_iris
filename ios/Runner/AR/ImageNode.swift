import SceneKit

final class ImageNode: SCNNode {
    init(
        width: CGFloat,
        height: CGFloat,
        image: UIImage,
        transparency: CGFloat = 0.5
    ) {
        super.init()
        let plane = SCNPlane(width: width, height: height)
        plane.firstMaterial?.diffuse.contents = image
        plane.firstMaterial?.isDoubleSided = true
        plane.firstMaterial?.transparency = transparency
        geometry = plane
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
