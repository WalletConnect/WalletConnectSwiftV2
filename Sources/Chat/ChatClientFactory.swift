import Foundation
import WalletConnectRelay
import WalletConnectUtils
import WalletConnectKMS

public struct ChatClientFactory {

    public static func create(
        registry: Registry,
        relayClient: RelayClient,
        kms: KeyManagementService,
        logger: ConsoleLogging,
        keyValueStorage: KeyValueStorage) -> ChatClient {
        let topicToRegistryRecordStore = CodableStore<RegistryRecord>(defaults: keyValueStorage, identifier: StorageDomainIdentifiers.topicToInvitationPubKey.rawValue)
        let serialiser = Serializer(kms: kms)
        let jsonRpcHistory = JsonRpcHistory<ChatRequestParams>(logger: logger, keyValueStore: CodableStore<JsonRpcRecord>(defaults: keyValueStorage, identifier: StorageDomainIdentifiers.jsonRpcHistory.rawValue))
        let networkingInteractor = NetworkingInteractor(relayClient: relayClient, serializer: serialiser, logger: logger, jsonRpcHistory: jsonRpcHistory)
        let invitePayloadStore = CodableStore<RequestSubscriptionPayload>(defaults: keyValueStorage, identifier: StorageDomainIdentifiers.invite.rawValue)
        let registryService = RegistryService(registry: registry, networkingInteractor: networkingInteractor, kms: kms, logger: logger, topicToRegistryRecordStore: topicToRegistryRecordStore)
        let threadStore = Database<Thread>(keyValueStorage: keyValueStorage, identifier: StorageDomainIdentifiers.threads.rawValue)
        let resubscriptionService = ResubscriptionService(networkingInteractor: networkingInteractor, threadStore: threadStore, logger: logger)
        let invitationHandlingService = InvitationHandlingService(registry: registry, networkingInteractor: networkingInteractor, kms: kms, logger: logger, topicToRegistryRecordStore: topicToRegistryRecordStore, invitePayloadStore: invitePayloadStore, threadsStore: threadStore)
        let inviteService = InviteService(networkingInteractor: networkingInteractor, kms: kms, threadStore: threadStore, logger: logger)
        let leaveService = LeaveService()
        let messagesStore = Database<Message>(keyValueStorage: keyValueStorage, identifier: StorageDomainIdentifiers.messages.rawValue)
        let messagingService = MessagingService(networkingInteractor: networkingInteractor, messagesStore: messagesStore, threadStore: threadStore, logger: logger)

        let client = ChatClient(
            registry: registry,
            registryService: registryService,
            messagingService: messagingService,
            invitationHandlingService: invitationHandlingService,
            inviteService: inviteService,
            leaveService: leaveService,
            resubscriptionService: resubscriptionService,
            kms: kms,
            threadStore: threadStore,
            messagesStore: messagesStore,
            invitePayloadStore: invitePayloadStore,
            socketConnectionStatusPublisher: relayClient.socketConnectionStatusPublisher
        )

        return client
    }
}
