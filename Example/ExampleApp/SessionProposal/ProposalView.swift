import SwiftUI

struct ProposalView: View {
    
    var didPressApprove: (() -> Void)?
    var didPressReject: (() -> Void)?
    
    let proposal: Proposal
    
    var body: some View {
        VStack {
            headerView
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            permissionsView
            Spacer()
            footerView
                .padding(16)
        }
    }
    
    func asyncImage(urlString: String) -> some View {
        AsyncImage(url: URL(string: urlString)) { phase in
            if case .success(let image) = phase {
                image.resizable()
            } else {
                Rectangle().foregroundColor(.secondarySystemBackground)
            }
        }
    }
    
    // App metadata for the session
    var headerView: some View {
        VStack(alignment: .center, spacing: 12) {
            asyncImage(urlString: proposal.iconURL)
                .frame(width: 64, height: 64)
                .clipShape(Circle())
                .padding(.top, 32)
            Text(proposal.proposerName)
                .font(.system(size: 17, weight: .heavy))
            Text(proposal.proposerURL)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.tertiaryLabel)
            Text(proposal.proposerDescription)
                .font(.subheadline)
                .foregroundColor(.secondaryLabel)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    // Scrollable view with permissions text
    var permissionsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Requested permissions:")
                .font(.system(size: 15, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(proposal.permissions, id: \.self) { namespace in
                        sectionView(for: namespace)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 32)
                }
                .padding(.vertical, 16)
            }
            .background(Color.secondarySystemBackground)
        }
    }
    
    // Displays a chain's methods and events
    func sectionView(for namespace: Proposal.Namespace) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("For \(namespace.chains.joined(separator: ", "))")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.secondaryLabel)
                .padding(.vertical, 4)
            if !namespace.methods.isEmpty {
                Text("Methods:")
                    .font(.system(size: 13, weight: .bold))
                    .padding(.horizontal, 16)
                ForEach(namespace.methods, id: \.self) {
                    Text("• \($0)")
                        .font(.system(size: 13))
                        .foregroundColor(.tertiaryLabel)
                }
                .padding(.horizontal, 32)
            }
            if !namespace.events.isEmpty {
                Text("Events:")
                    .font(.system(size: 13, weight: .bold))
                    .padding(.horizontal, 16)
                ForEach(namespace.events, id: \.self) {
                    Text("• \($0)")
                        .font(.system(size: 13))
                        .foregroundColor(.tertiaryLabel)
                }
                .padding(.horizontal, 32)
            }
        }
    }
    
    // Approve and reject buttons
    var footerView: some View {
        HStack {
            Button {
                didPressApprove?()
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
                didPressReject?()
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
    }
}

struct ProposalView_Previews: PreviewProvider {
    
    static var previews: some View {
        ProposalView(proposal: Proposal.mock())
        ProposalView(proposal: Proposal.mock()).preferredColorScheme(.dark)
    }
}
