import UserNotifications
import WalletConnectPush
import os

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        if let bestAttemptContent = bestAttemptContent {
            let topic = bestAttemptContent.userInfo["topic"] as! String
            let ciphertext = bestAttemptContent.userInfo["blob"] as! String
            NSLog("echo decryption, topic=%@", topic)
            do {
                let service = PushDecryptionService()
                let pushMessage = try service.decryptMessage(topic: topic, ciphertext: ciphertext)
                bestAttemptContent.title = pushMessage.title
                bestAttemptContent.body = pushMessage.body
                contentHandler(bestAttemptContent)
                return
            }
            catch {
                NSLog("echo decryption, error=%@", error.localizedDescription)
                bestAttemptContent.title = ""
                bestAttemptContent.body = "content not set"
            }
            contentHandler(bestAttemptContent)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}
