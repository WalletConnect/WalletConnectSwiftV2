/**
 A value that identifies an account in any given blockchain.
 
 This structure parses account IDs according to [CAIP-10].
 Account IDs are prefixed with a [CAIP-2] blockchain ID, delimited by a `':'` character, followed by the account address.
 
 Specifying a blockchain account by using a chain-agnostic identifier is useful to allow interoperability between multiple
 chains when using both wallets and decentralized applications.
 
 [CAIP-2]:https://github.com/ChainAgnostic/CAIPs/blob/master/CAIPs/caip-2.md
 [CAIP-10]:https://github.com/ChainAgnostic/CAIPs/blob/master/CAIPs/caip-10.md
 */
public struct Account: Equatable, Hashable {

    /// A blockchain namespace. Usually describes an ecosystem or standard.
    public let namespace: String

    /// A reference string that identifies a blockchain within a given namespace.
    public let reference: String

    /// The account's address specific to the blockchain.
    public let address: String

    /// The CAIP-2 blockchain identifier of the account.
    public var blockchainIdentifier: String {
        "\(namespace):\(reference)"
    }

    /// The CAIP-10 account identifier absolute string.
    public var absoluteString: String {
        "\(namespace):\(reference):\(address)"
    }

    /// Returns a CAIP-2 reference to the blockchain where the account is located.
    public var blockchain: Blockchain {
        guard let blockchain = Blockchain(namespace: namespace, reference: reference) else {
            preconditionFailure("The CAIP-2 chain id of a CAIP-10 account must always be consistent.")
        }
        return blockchain
    }

    /**
     Creates an account instance from the provided string.
     
     This initializer returns nil if the string doesn't represent a valid account id in conformance with
     [CAIP-10](https://github.com/ChainAgnostic/CAIPs/blob/master/CAIPs/caip-10.md).
     */
    public init?(_ string: String) {
        guard String.conformsToCAIP10(string) else { return nil }
        let splits = string.split(separator: ":")
        self.namespace = String(splits[0])
        self.reference = String(splits[1])
        self.address = String(splits[2])
    }

    /**
     Creates an account instance from a chain ID and an address.
     
     This initializer returns nil if the `chainIdentifier` parameter doesn't represent a valid chain id in conformance with
     [CAIP-2](https://github.com/ChainAgnostic/CAIPs/blob/master/CAIPs/caip-2.md) or if the `address` format is invalid.
     */
    public init?(chainIdentifier: String, address: String) {
        self.init("\(chainIdentifier):\(address)")
    }

    /**
     Creates an account instance from a blockchain reference and an address.
     
     This initializer returns nil if the `address` format is invalid. The `blockchain` type is already expected to be conformant.
     */
    public init?(blockchain: Blockchain, address: String) {
        self.init("\(blockchain.absoluteString):\(address)")
    }
}

extension Account: LosslessStringConvertible {
    public var description: String {
        return absoluteString
    }
}

extension Account: Codable {

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let absoluteString = try container.decode(String.self)
        guard let account = Account(absoluteString) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Malformed CAIP-10 account identifier.")
        }
        self = account
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(absoluteString)
    }
}
