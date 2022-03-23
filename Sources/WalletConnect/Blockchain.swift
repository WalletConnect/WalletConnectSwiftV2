public struct Blockchain {
    
    public let namespace: String
    
    public let reference: String
    
    public var absoluteString: String {
        "\(namespace):\(reference)"
    }
    
    public init?(_ string: String) {
        guard String.conformsToCAIP2(string) else { return nil }
        let splits = string.split(separator: ":")
        self.namespace = String(splits[0])
        self.reference = String(splits[1])
    }
    
    public init?(namespace: String, reference: String) {
        self.init("\(namespace):\(reference)")
    }
}
