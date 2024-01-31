import Foundation
import SwiftMessages
import UIKit

struct AlertPresenter {
    enum MessageType {
        case warning
        case error
        case info
        case success
    }

    static func present(message: String, type: AlertPresenter.MessageType) {
        DispatchQueue.main.async {
            let view = MessageView.viewFromNib(layout: .cardView)
            switch type {
            case .warning:
                view.configureTheme(.warning, iconStyle: .subtle)
            case .error:
                view.configureTheme(.error, iconStyle: .subtle)
            case .info:
                view.configureTheme(.info, iconStyle: .subtle)
            case .success:
                view.configureTheme(.success, iconStyle: .subtle)
            }
            view.button?.isHidden = true
            view.layoutMarginAdditions = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
            view.configureContent(title: "", body: message)
            var config = SwiftMessages.Config()
            config.presentationStyle = .top
            config.duration = .seconds(seconds: 1.5)
            SwiftMessages.show(config: config, view: view)
        }
    }
}
