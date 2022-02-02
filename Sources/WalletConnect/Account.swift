/**
 
 */
public struct Account {
    
    ///
    public let namespace: String
    
    ///
    public let reference: String
    
    ///
    public let address: String
    
    ///
    public var blockchainIdentifier: String {
        "\(namespace):\(reference)"
    }
    
    ///
    public var absoluteString: String {
        "\(namespace):\(reference):\(address)"
    }
    
    public init?(string: String) {
        guard String.conformsToCAIP10(string) else { return nil }
        let splits = string.split(separator: ":")
        self.namespace = String(splits[0])
        self.reference = String(splits[1])
        self.address = String(splits[2])
    }
}
