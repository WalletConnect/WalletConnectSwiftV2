import SwiftUI

import WalletConnect
struct Proposal {
    let proposerName: String
    let proposerDescription: String
    let proposerURL: String
    // icon
//    let namespaces: [WalletConnect.Namespace]
    let namespaces: [Namespace]
    
    static func mock() -> Proposal {
        Proposal(
            proposerName: "Example name",
            proposerDescription: String.loremIpsum,
            proposerURL: "example.url",
            namespaces: [
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
    
    struct Namespace {
        let chains: [String]
        let methods: [String]
        let events: [String]
    }
}

struct NewProposalView: View {
    
    let proposal: Proposal = Proposal.mock()
    
    var body: some View {
        VStack {
            Image("wc-icon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 64, height: 64)
                .background(Color(red: 0.9, green: 0.9, blue: 0.9))
                .clipShape(Circle())
                .padding(.top, 64)
            Text(proposal.proposerName)
                .font(.system(size: 17, weight: .heavy))
            Text(proposal.proposerURL)
                .font(.system(size: 14, weight: .bold))
            Text(proposal.proposerDescription)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            HStack {
                Button {
                    // action
                } label: {
                    Text("Approve")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
                .background(Color.blue)
                .cornerRadius(8)
                
                Button {
                    // action
                } label: {
                    Text("Reject")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
                .background(Color.red)
                .cornerRadius(8)
            }
            .padding(.horizontal, 16)
        }
    }
}

struct NewProposalView_Previews: PreviewProvider {
    
    static var previews: some View {
        NewProposalView()
    }
}
