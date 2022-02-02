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
    public var chainIdentifier: String {
        "\(namespace):\(reference)"
    }
    
    ///
    public var absoluteString: String {
        "\(namespace):\(reference):\(address)"
    }
    
    public var isCAIP10Conformant: Bool {
        return String.conformsToCAIP10(absoluteString)
    }
    
    public init(chainNamespace: String, chainReference: String, address: String) {
        self.namespace = chainNamespace
        self.reference = chainReference
        self.address = address
    }
    
    public init?(string: String) {
        guard String.conformsToCAIP10(string) else { return nil }
        let splits = string.split(separator: ":")
        self.namespace = String(splits[0])
        self.reference = String(splits[1])
        self.address = String(splits[2])
    }
}
