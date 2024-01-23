import UIKit

class ActivityIndicatorManager {
    static let shared = ActivityIndicatorManager()
    private var activityIndicator: UIActivityIndicatorView?
    private let serialQueue = DispatchQueue(label: "com.yourapp.activityIndicatorManager")

    private init() {}

    func start() {
        serialQueue.async {
            self.stopInternal()

            DispatchQueue.main.async {
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let window = windowScene.windows.first(where: { $0.isKeyWindow }) else { return }

                let activityIndicator = UIActivityIndicatorView(style: .large)
                activityIndicator.center = window.center
                activityIndicator.color = .white
                activityIndicator.startAnimating()
                window.addSubview(activityIndicator)

                self.activityIndicator = activityIndicator
            }
        }
    }

    func stop() {
        serialQueue.async {
            self.stopInternal()
        }
    }

    private func stopInternal() {
        DispatchQueue.main.sync {
            self.activityIndicator?.stopAnimating()
            self.activityIndicator?.removeFromSuperview()
            self.activityIndicator = nil
        }
    }
}
