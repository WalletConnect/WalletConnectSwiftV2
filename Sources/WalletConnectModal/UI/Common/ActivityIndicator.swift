import SwiftUI

#if canImport(UIKit)
struct ActivityIndicator: UIViewRepresentable {
    @Binding var isAnimating: Bool

    func makeUIView(context: UIViewRepresentableContext<ActivityIndicator>) -> UIActivityIndicatorView {
        return UIActivityIndicatorView(style: .large)
    }

    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityIndicator>) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    }
}

#elseif canImport(AppKit)

struct ActivityIndicator: NSViewRepresentable {
    
    @Binding var isAnimating: Bool

    func makeNSView(context: Context) -> NSProgressIndicator {
        return NSProgressIndicator()
    }

    func updateNSView(_ nsView: NSProgressIndicator, context: Context) {
        isAnimating ? nsView.startAnimation(nil) : nsView.stopAnimation(nil)
    }
}

#endif
