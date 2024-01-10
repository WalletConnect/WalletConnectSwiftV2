import UIKit

class ActivityIndicatorManager {
    static let shared = ActivityIndicatorManager()
    private var activityIndicator: UIActivityIndicatorView?

    private init() {}

    func start() async {
        await stop()

        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first(where: { $0.isKeyWindow }) else { return }

            let activityIndicator = UIActivityIndicatorView(style: .large)
            activityIndicator.center = window.center
            activityIndicator.startAnimating()
            window.addSubview(activityIndicator)

            self.activityIndicator = activityIndicator
        }
    }

    func stop() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                self.activityIndicator?.stopAnimating()
                self.activityIndicator?.removeFromSuperview()
                self.activityIndicator = nil
                continuation.resume()
            }
        }
    }
}
