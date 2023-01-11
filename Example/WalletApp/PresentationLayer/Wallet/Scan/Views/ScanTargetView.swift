import UIKit

final class ScanTargetView: UIView {

    private let radius: CGFloat
    private let color: UIColor
    private let strokeWidth: CGFloat
    private let length: CGFloat

    private lazy var shapeLayer: CAShapeLayer = {
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = color.cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineWidth = strokeWidth
        return shapeLayer
    }()

    init(radius: CGFloat, color: UIColor, strokeWidth: CGFloat, length: CGFloat) {
        self.radius = radius
        self.color = color
        self.strokeWidth = strokeWidth
        self.length = length

        super.init(frame: .zero)

        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        shapeLayer.path = targetPath()
    }

    private func setupView() {
        backgroundColor = .clear
        layer.addSublayer(shapeLayer)
    }

    private func targetPath() -> CGPath {
        let path = UIBezierPath()
        path.append(createTopLeft())
        path.append(createTopRight())
        path.append(createBottomLeft())
        path.append(createBottomRight())
        return path.cgPath
    }

    private func createTopLeft() -> UIBezierPath {
        let topLeft = UIBezierPath()
        topLeft.move(to: CGPoint(x: strokeWidth/2, y: radius+length))
        topLeft.addLine(to: CGPoint(x: strokeWidth/2, y: radius))
        topLeft.addQuadCurve(to: CGPoint(x: radius, y: strokeWidth/2), controlPoint: CGPoint(x: strokeWidth/2, y: strokeWidth/2))
        topLeft.addLine(to: CGPoint(x: radius+length, y: strokeWidth/2))
        return topLeft
    }

    private func createTopRight() -> UIBezierPath {
        let topRight = UIBezierPath()
        topRight.move(to: CGPoint(x: frame.width-radius-length, y: strokeWidth/2))
        topRight.addLine(to: CGPoint(x: frame.width-radius, y: strokeWidth/2))
        topRight.addQuadCurve(to: CGPoint(x: frame.width-strokeWidth/2, y: radius), controlPoint: CGPoint(x: frame.width-strokeWidth/2, y: strokeWidth/2))
        topRight.addLine(to: CGPoint(x: frame.width-strokeWidth/2, y: radius+length))
        return topRight
    }

    private func createBottomRight() -> UIBezierPath {
        let bottomRight = UIBezierPath()
        bottomRight.move(to: CGPoint(x: frame.width-strokeWidth/2, y: frame.height-radius-length))
        bottomRight.addLine(to: CGPoint(x: frame.width-strokeWidth/2, y: frame.height-radius))
        bottomRight.addQuadCurve(to: CGPoint(x: frame.width-radius, y: frame.height-strokeWidth/2), controlPoint: CGPoint(x: frame.width-strokeWidth/2, y: frame.height-strokeWidth/2))
        bottomRight.addLine(to: CGPoint(x: frame.width-radius-length, y: frame.height-strokeWidth/2))
        return bottomRight
    }

    private func createBottomLeft() -> UIBezierPath {
        let bottomLeft = UIBezierPath()
        bottomLeft.move(to: CGPoint(x: radius+length, y: frame.height-strokeWidth/2))
        bottomLeft.addLine(to: CGPoint(x: radius, y: frame.height-strokeWidth/2))
        bottomLeft.addQuadCurve(to: CGPoint(x: strokeWidth/2, y: frame.height-radius), controlPoint: CGPoint(x: strokeWidth/2, y: frame.height-strokeWidth/2))
        bottomLeft.addLine(to: CGPoint(x: strokeWidth/2, y: frame.height-radius-length))
        return bottomLeft
    }
}
