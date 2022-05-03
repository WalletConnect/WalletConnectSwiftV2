//import WalletConnect

struct Proposal {
    let proposerName: String
    let proposerDescription: String
    let proposerURL: String
    // icon
    let permissions: [Namespace]
    
    struct Namespace: Hashable {
        let chains: [String]
        let methods: [String]
        let events: [String]
    }
    
    static func mock() -> Proposal {
        Proposal(
            proposerName: "Example name",
            proposerDescription: String.loremIpsum,
            proposerURL: "example.url",
            permissions: [
                Namespace(
                    chains: ["eip155:1", "eip155:157"],
                    methods: ["eth_sendTransaction", "personal_sign", "eth_signTypedData"],
                    events: ["accountsChanged", "chainChanged"]),
                Namespace(
                    chains: ["cosmos:cosmoshub-2"],
                    methods: ["cosmos_signDirect", "cosmos_signAmino"],
                    events: [])
            ]
        )
    }
}
