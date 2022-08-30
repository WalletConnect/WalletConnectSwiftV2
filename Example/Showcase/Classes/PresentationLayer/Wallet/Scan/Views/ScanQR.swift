import SwiftUI

struct ScanQR: UIViewRepresentable {

    class Coordinator: ScanQRViewDelegate {
        private let onValue: (String) -> Void
        private let onError: (Error) -> Void

        init(onValue: @escaping (String) -> Void, onError: @escaping (Error) -> Void) {
            self.onValue = onValue
            self.onError = onError
        }

        func scanDidDetect(value: String) {
            onValue(value)
        }

        func scanDidFail(with error: Error) {
            onError(error)
        }
    }

    let onValue: (String) -> Void
    let onError: (Error) -> Void

    func makeUIView(context: Context) -> ScanQRView {
        let view = ScanQRView()
        view.delegate = context.coordinator
        return view
    }

    func updateUIView(_ uiView: ScanQRView, context: Context) {

    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(onValue: onValue, onError: onError)
    }
}
