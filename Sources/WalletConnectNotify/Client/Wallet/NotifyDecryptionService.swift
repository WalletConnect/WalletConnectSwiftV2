import Foundation

public class NotifyDecryptionService {
    enum Errors: Error {
        case malformedNotifyMessage
        case subsctiptionNotFound
    }
    private let serializer: Serializing
    private let database: NotifyDatabase
    private static let notifyTags: [UInt] = [4002]

    init(serializer: Serializing, database: NotifyDatabase) {
        self.serializer = serializer
        self.database = database
    }

    public init(groupIdentifier: String) {
        let keychainStorage = GroupKeychainStorage(serviceIdentifier: groupIdentifier)
        let kms = KeyManagementService(keychain: keychainStorage)
        let logger = ConsoleLogger(prefix: "🔐", loggingLevel: .off)
        let sqlite = NotifySqliteFactory.create(appGroup: groupIdentifier)
        self.serializer = Serializer(kms: kms, logger: logger)
        self.database = NotifyDatabase(sqlite: sqlite, logger: logger)
    }

    public static func canHandle(tag: UInt) -> Bool {
        return notifyTags.contains(tag)
    }

    public func decryptMessage(topic: String, ciphertext: String) throws -> (NotifyMessage, NotifySubscription, Account) {
        let (rpcRequest, _, _): (RPCRequest, String?, Data) = try serializer.deserialize(topic: topic, encodedEnvelope: ciphertext)
        guard let params = rpcRequest.params else { throw Errors.malformedNotifyMessage }
        let wrapper = try params.get(NotifyMessagePayload.Wrapper.self)
        let (messagePayload, _) = try NotifyMessagePayload.decodeAndVerify(from: wrapper)
        guard let subscription = database.getSubscription(topic: topic) else { throw Errors.subsctiptionNotFound }
        return (messagePayload.message, subscription, messagePayload.account)
    }
}
