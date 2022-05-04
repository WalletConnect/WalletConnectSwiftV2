import SwiftUI

struct ProposalView: View {
    
    var didPressApprove: (() -> Void)?
    var didPressReject: (() -> Void)?
    
    let proposal: Proposal
    
    var body: some View {
        VStack {
            VStack(alignment: .center, spacing: 12) {
                AsyncImage(url: URL(string: proposal.iconURL)) { phase in
                    if case .success(let image) = phase {
                        image.resizable()
                    } else {
                        Rectangle().foregroundColor(.secondarySystemBackground)
                    }
                }
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
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Requested permissions:")
                    .font(.system(size: 15, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(proposal.permissions, id: \.self) { namespace in
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
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 32)
                    }
                    .padding(.vertical, 16)
                }
                .background(Color.secondarySystemBackground)
            }
            
            Spacer()
            
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
            .padding(16)
        }
    }
}

struct ProposalView_Previews: PreviewProvider {
    
    static var previews: some View {
        ProposalView(proposal: Proposal.mock())
//        ProposalView().preferredColorScheme(.dark)
    }
}
