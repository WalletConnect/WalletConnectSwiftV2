import SwiftUI

public extension UIView {
    
    struct Preview: UIViewRepresentable {
        let view: UIView
        public func makeUIView(context: Context) -> some UIView { view }
        public func updateUIView(_ uiView: UIViewType, context: Context) {}
    }
    
    func makePreview() -> some View {
        Preview(view: self)
    }
}
