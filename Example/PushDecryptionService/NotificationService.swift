//     

import UserNotifications
import WalletConnectPush

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        if let bestAttemptContent = bestAttemptContent {
            // Modify the notification content here...
            let topic = bestAttemptContent.userInfo["topic"] as! String
            let ciphertext = bestAttemptContent.userInfo["encrypted_message"] as! String
            do {
                let keychainStorage = GroupKeychainStorage(serviceIdentifier: "group.com.walletconnect.example")

                let kms = KeyManagementService(keychain: keychainStorage)

                let serializer = Serializer(kms: kms)
                let service = PushDecryptionService(serializer: serializer)
                let pushMessage = try service.decryptMessage(topic: topic, ciphertext: ciphertext)
                bestAttemptContent.body = pushMessage.body
                contentHandler(bestAttemptContent)

            }
            catch {
                print(error)
            }
           // bestAttemptContent.title = pushMessage.title
            bestAttemptContent.body = "dupa"
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
