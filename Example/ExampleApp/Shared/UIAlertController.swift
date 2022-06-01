import UIKit

extension UIAlertController {
    
    static func createInputAlert(confirmHandler: @escaping (String) -> Void) -> UIAlertController {
        let alert = UIAlertController(title: "Paste URI", message: "Enter a WalletConnect URI to connect.", preferredStyle: .alert)
        let connect: () -> Void = {
            if let input = alert.textFields?.first?.text, !input.isEmpty {
                confirmHandler(input)
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        let confirmAction = UIAlertAction(title: "Connect", style: .default) { _ in
            connect()
        }
        let pasteAction = UIAlertAction(title: "Paste and Connect", style: .default) { _ in
            alert.textFields?.first?.text = UIPasteboard.general.string
            connect()
        }
        alert.addTextField { textField in
            textField.placeholder = "wc://a14aefb980188fc35ec9..."
        }
        alert.addAction(confirmAction)
        alert.addAction(pasteAction)
        alert.addAction(cancelAction)
        alert.preferredAction = confirmAction
        return alert
    }
}
