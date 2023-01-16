import Foundation

private typealias NetworkingReason = Reason

// Internal namespace for session payloads.
internal enum SessionType {

    typealias ProposeParams = SessionProposal

    struct ProposeResponse: Codable, Equatable {
        let relay: RelayProtocolOptions
        let responderPublicKey: String
    }

    struct SettleParams: Codable, Equatable {
        let relay: RelayProtocolOptions
        let controller: Participant
        let namespaces: [String: SessionNamespace]
        let expiry: Int64
    }

    struct UpdateParams: Codable, Equatable {
        let namespaces: [String: SessionNamespace]
    }

    typealias DeleteParams = SessionType.Reason

    struct Reason: Codable, Equatable, NetworkingReason {
        let code: Int
        let message: String

        init(code: Int, message: String) {
            self.code = code
            self.message = message
        }
    }

    struct RequestParams: Codable, Equatable {
        let request: Request
        let chainId: Blockchain

        struct Request: Codable, Equatable {
            let method: String
            let params: AnyCodable
            let expiry: UInt64?
        }
    }

    struct EventParams: Codable, Equatable {
        let event: Event
        let chainId: Blockchain

        struct Event: Codable, Equatable {
            let name: String
            let data: AnyCodable

            func publicRepresentation() -> Session.Event {
                Session.Event(name: name, data: data)
            }
        }
    }

    struct PingParams: Codable, Equatable {}

    struct UpdateExpiryParams: Codable, Equatable {
        let expiry: Int64
    }
}
