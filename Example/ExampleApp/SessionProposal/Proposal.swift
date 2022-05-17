import WalletConnectAuth

struct Proposal {
    let proposerName: String
    let proposerDescription: String
    let proposerURL: String
    let iconURL: String
    let permissions: [Namespace]
        
    struct Namespace: Hashable {
        let chains: [String]
        let methods: [String]
        let events: [String]
    }
    
    internal init(proposal: Session.Proposal) {
        self.proposerName = proposal.proposer.name
        self.proposerDescription = proposal.proposer.description
        self.proposerURL = proposal.proposer.url
        self.iconURL = proposal.proposer.icons.first!
        self.permissions = [
            Namespace(
                chains: ["eip155:1"],
                methods: ["eth_sendTransaction", "personal_sign", "eth_signTypedData"],
                events: ["accountsChanged", "chainChanged"])]
    }
    
    internal init(proposerName: String, proposerDescription: String, proposerURL: String, iconURL: String, permissions: [Proposal.Namespace]) {
        self.proposerName = proposerName
        self.proposerDescription = proposerDescription
        self.proposerURL = proposerURL
        self.iconURL = iconURL
        self.permissions = permissions
    }
    
    static func mock() -> Proposal {
        Proposal(
            proposerName: "Example name",
            proposerDescription: String.loremIpsum,
            proposerURL: "example.url",
            iconURL: "https://gblobscdn.gitbook.com/spaces%2F-LJJeCjcLrr53DcT1Ml7%2Favatar.png?alt=media",
            permissions: [
                Namespace(
                    chains: ["eip155:1"],
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
