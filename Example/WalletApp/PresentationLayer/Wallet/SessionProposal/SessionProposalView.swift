import SwiftUI
import Web3Wallet

struct SessionProposalView: View {
    @EnvironmentObject var presenter: SessionProposalPresenter
    
    @State var text = ""
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
            
            VStack {
                Spacer()
                
                VStack(spacing: 0) {
                    Image("header")
                        .resizable()
                        .scaledToFit()
                    
                    HStack {
                        Text(presenter.sessionProposal.proposer.name)
                            .foregroundColor(.grey8)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                    }
                    
                    .padding(.top, 10)
                    
                    Text("would like to connect")
                        .foregroundColor(.grey8)
                        .font(.system(size: 22, weight: .medium, design: .rounded))
                    
                    if case .valid = presenter.validationStatus {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.blue)
                            
                            Text(presenter.sessionProposal.proposer.url)
                                .foregroundColor(.grey8)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .lineSpacing(4)
                        }
                        .padding(.top, 8)
                    } else {
                        Text(presenter.sessionProposal.proposer.url)
                            .foregroundColor(.grey8)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.top, 8)
                    }
                    
                    switch presenter.validationStatus {
                    case .unknown:
                        verifyBadgeView(imageName: "exclamationmark.circle.fill", title: "Cannot verify", color: .orange)
                        
                    case .invalid:
                        verifyBadgeView(imageName: "exclamationmark.triangle.fill", title: "Invalid domain", color: .red)
                        
                    case .scam:
                        verifyBadgeView(imageName: "exclamationmark.shield.fill", title: "Security risk", color: .red)
                        
                    default:
                        EmptyView()
                    }
                    
                    Divider()
                        .padding(.top, 12)
                        .padding(.horizontal, -18)
                    
                    ScrollView {
                        Text("Required namespaces".uppercased())
                            .foregroundColor(.grey50)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.vertical, 12)
                        
                        ForEach(presenter.sessionProposal.requiredNamespaces.keys.sorted(), id: \.self) { chain in
                            if let namespaces = presenter.sessionProposal.requiredNamespaces[chain] {
                                sessionProposalView(namespaces: namespaces)
                            }
                        }
                        
                        if let optionalNamespaces = presenter.sessionProposal.optionalNamespaces {
                            if !optionalNamespaces.isEmpty {
                                Text("Optional namespaces".uppercased())
                                    .foregroundColor(.grey50)
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(4)
                                    .padding(.vertical, 12)
                            }

                            ForEach(optionalNamespaces.keys.sorted(), id: \.self) { chain in
                                if let namespaces = optionalNamespaces[chain] {
                                    sessionProposalView(namespaces: namespaces)
                                }
                            }
                        }
                    }
                    .frame(height: 150)
                    .cornerRadius(20)
                    .padding(.vertical, 12)
                    
                    switch presenter.validationStatus {
                    case .invalid:
                        verifyDescriptionView(imageName: "exclamationmark.triangle.fill", title: "Invalid domain", description: "This domain cannot be verified. Check the request carefully before approving.", color: .red)
                        
                    case .unknown:
                        verifyDescriptionView(imageName: "exclamationmark.circle.fill", title: "Unknown domain", description: "This domain cannot be verified. Check the request carefully before approving.", color: .orange)
                        
                    case .scam:
                        verifyDescriptionView(imageName: "exclamationmark.shield.fill", title: "Security risk", description: "This website is flagged as unsafe by multiple security providers. Leave immediately to protect your assets.", color: .red)
                        
                    default:
                        EmptyView()
                    }
                    
                    if case .scam = presenter.validationStatus {
                        VStack(spacing: 20) {
                            declineButton()
                            allowButton()
                        }
                        .padding(.top, 25)
                    } else {
                        HStack {
                            declineButton()
                            allowButton()
                        }
                        .padding(.top, 25)
                    }
                }
                .padding(20)
                .background(.ultraThinMaterial)
                .cornerRadius(34)
                .padding(.horizontal, 10)
                
                Spacer()
            }
        }
        .alert(presenter.errorMessage, isPresented: $presenter.showError) {
            Button("OK", role: .cancel) {}
        }
        .edgesIgnoringSafeArea(.all)
    }

    private func sessionProposalView(namespaces: ProposalNamespace) -> some View {
        VStack {
            VStack(alignment: .leading) {
                TagsView(items: Array(namespaces.chains ?? Set())) {
                    Text($0.absoluteString.uppercased())
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.whiteBackground)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.grey70)
                        .cornerRadius(28, corners: .allCorners)
                }
                .padding(.horizontal, 15)
                .padding(.top, 9)
                
                VStack(spacing: 0) {
                    HStack {
                        Text("Methods")
                            .foregroundColor(.grey50)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                        
                        Spacer()
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 10)
                    
                    TagsView(items: Array(namespaces.methods)) {
                        Text($0)
                            .foregroundColor(.cyanBackround)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.cyanBackround.opacity(0.2))
                            .cornerRadius(10, corners: .allCorners)
                    }
                    .padding(10)
                }
                .background(Color.whiteBackground)
                .cornerRadius(20, corners: .allCorners)
                .padding(.horizontal, 5)
                
                if !namespaces.events.isEmpty {
                    VStack(spacing: 0) {
                        HStack {
                            Text("Events")
                                .foregroundColor(.grey50)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                            
                            Spacer()
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 10)
                        
                        TagsView(items: Array(namespaces.events)) {
                            Text($0)
                                .foregroundColor(.cyanBackround)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.cyanBackround.opacity(0.2))
                                .cornerRadius(10, corners: .allCorners)
                        }
                        .padding(10)
                    }
                    .background(Color.whiteBackground)
                    .cornerRadius(20, corners: .allCorners)
                    .padding(.horizontal, 5)
                    .padding(.bottom, 5)
                } else {
                    Spacer(minLength: 5)
                }
            }
            .background(.thinMaterial)
            .cornerRadius(25, corners: .allCorners)
        }
        .padding(.bottom, 15)
    }
    
    private func verifyBadgeView(imageName: String, title: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: imageName)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(color)
            
            Text(title)
                .foregroundColor(color)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
            
        }
        .padding(5)
        .background(color.opacity(0.15))
        .cornerRadius(10)
        .padding(.top, 8)
    }
    
    private func verifyDescriptionView(imageName: String, title: String, description: String, color: Color) -> some View {
        HStack(spacing: 15) {
            Image(systemName: imageName)
                .font(.system(size: 20, design: .rounded))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .foregroundColor(color)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                
                Text(description)
                    .foregroundColor(.grey8)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.15))
        .cornerRadius(20)
    }
    
    private func declineButton() -> some View {
        Button {
            Task(priority: .userInitiated) { try await
                presenter.onReject()
            }
        } label: {
            Text("Decline")
                .frame(maxWidth: .infinity)
                .foregroundColor(.white)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .padding(.vertical, 11)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .foregroundNegative,
                            .lightForegroundNegative
                        ]),
                        startPoint: .top, endPoint: .bottom)
                )
                .cornerRadius(20)
        }
        .shadow(color: .white.opacity(0.25), radius: 8, y: 2)
    }
    
    private func allowButton() -> some View {
        Button {
            Task(priority: .userInitiated) { try await
                presenter.onApprove()
            }
        } label: {
            Text(presenter.validationStatus == .scam ? "Proceed anyway" : "Allow")
                .frame(maxWidth: .infinity)
                .foregroundColor(presenter.validationStatus == .scam ? .grey50 : .white)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .padding(.vertical, 11)
                .background(
                    Group {
                        if presenter.validationStatus == .scam {
                            Color.clear
                        } else {
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    .foregroundPositive,
                                    .lightForegroundPositive
                                ]),
                                startPoint: .top, endPoint: .bottom
                            )
                        }
                    }
                )
                .cornerRadius(20)
        }
        .shadow(color: .white.opacity(0.25), radius: 8, y: 2)
    }
}

#if DEBUG
struct SessionProposalView_Previews: PreviewProvider {
    static var previews: some View {
        SessionProposalView()
    }
}
#endif
